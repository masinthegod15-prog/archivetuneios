// ArchiveTune iOS native rewrite
// Based on ArchiveTune by Rukamori and contributors. GPL-3.0; see LICENSE.

import AVFoundation
import Foundation
import Combine
import UniformTypeIdentifiers

@MainActor
final class LibraryStore: ObservableObject {
    @Published private(set) var tracks: [Track] = []
    @Published private(set) var playlists: [Playlist] = []
    @Published private(set) var history: [HistoryEntry] = []
    @Published var lastError: String?

    static var documentsDirectory: URL { LibraryPaths.documentsDirectory }
    static var audioDirectory: URL { LibraryPaths.audioDirectory }

    private var storeURL: URL {
        Self.documentsDirectory.appendingPathComponent("archivetune-library.json")
    }
    private var unsavedListeningSeconds: TimeInterval = 0

    init() {
        do {
            try FileManager.default.createDirectory(at: Self.audioDirectory, withIntermediateDirectories: true)
            try load()
        } catch {
            lastError = "Your library could not be loaded: \(error.localizedDescription)"
        }
    }

    func importFiles(_ sourceURLs: [URL]) async throws -> Int {
        var importedCount = 0
        for sourceURL in sourceURLs {
            let hasAccess = sourceURL.startAccessingSecurityScopedResource()
            defer {
                if hasAccess { sourceURL.stopAccessingSecurityScopedResource() }
            }

            let fileExtension = sourceURL.pathExtension.lowercased()
            guard Self.isSupportedAudioExtension(fileExtension) else { continue }

            let safeExtension = fileExtension.isEmpty ? "audio" : fileExtension
            let destination = Self.audioDirectory.appendingPathComponent("\(UUID().uuidString).\(safeExtension)")
            try FileManager.default.copyItem(at: sourceURL, to: destination)

            let track = await Self.makeTrack(from: destination)
            tracks.insert(track, at: 0)
            importedCount += 1
        }
        try save()
        return importedCount
    }

    func createPlaylist(named rawName: String) throws {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        guard !playlists.contains(where: { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }) else {
            throw LibraryError.playlistAlreadyExists
        }
        playlists.insert(Playlist(name: name), at: 0)
        try save()
    }

    func add(_ track: Track, to playlistID: UUID) throws {
        guard let index = playlists.firstIndex(where: { $0.id == playlistID }) else { return }
        if !playlists[index].trackIDs.contains(track.id) {
            playlists[index].trackIDs.append(track.id)
            try save()
        }
    }

    func remove(_ track: Track) throws {
        tracks.removeAll { $0.id == track.id }
        playlists = playlists.map { playlist in
            var updated = playlist
            updated.trackIDs.removeAll { $0 == track.id }
            return updated
        }
        history.removeAll { $0.trackID == track.id }
        try? FileManager.default.removeItem(at: track.fileURL)
        try save()
    }

    func deletePlaylist(_ playlist: Playlist) throws {
        playlists.removeAll { $0.id == playlist.id }
        try save()
    }

    func renamePlaylist(_ playlist: Playlist, to rawName: String) throws {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, let index = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        playlists[index].name = name
        try save()
    }

    func playlistTracks(_ playlist: Playlist) -> [Track] {
        playlist.trackIDs.compactMap { id in tracks.first(where: { $0.id == id }) }
    }

    func recordPlay(_ track: Track) {
        history.insert(HistoryEntry(trackID: track.id), at: 0)
        try? save()
    }

    func addListeningTime(trackID: UUID, seconds: TimeInterval) {
        guard seconds > 0, seconds <= 3 else { return }
        guard let index = history.firstIndex(where: { $0.trackID == trackID }) else { return }
        history[index].listenedSeconds += seconds
        unsavedListeningSeconds += seconds
        if unsavedListeningSeconds >= 12 {
            unsavedListeningSeconds = 0
            try? save()
        }
    }

    func flush() { try? save() }

    func makeBackup() throws -> Data {
        var audioFiles: [String: Data] = [:]
        for track in tracks {
            if FileManager.default.fileExists(atPath: track.fileURL.path) {
                audioFiles[track.filename] = try Data(contentsOf: track.fileURL)
            }
        }
        let payload = BackupPayload(tracks: tracks, playlists: playlists, history: history, audioFiles: audioFiles)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(payload)
    }

    func restoreBackup(_ data: Data) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(BackupPayload.self, from: data)
        guard payload.formatVersion == 1 else { throw LibraryError.unsupportedBackupVersion }

        try FileManager.default.createDirectory(at: Self.audioDirectory, withIntermediateDirectories: true)
        for (filename, content) in payload.audioFiles {
            let safeName = URL(fileURLWithPath: filename).lastPathComponent
            guard safeName == filename else { continue }
            try content.write(to: Self.audioDirectory.appendingPathComponent(safeName), options: .atomic)
        }

        tracks = payload.tracks
        playlists = payload.playlists
        history = payload.history
        try save()
    }

    private func load() throws {
        guard FileManager.default.fileExists(atPath: storeURL.path) else { return }
        let data = try Data(contentsOf: storeURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(StoredLibrary.self, from: data)
        tracks = payload.tracks.filter { FileManager.default.fileExists(atPath: $0.fileURL.path) }
        playlists = payload.playlists
        history = payload.history
    }

    private func save() throws {
        let payload = StoredLibrary(tracks: tracks, playlists: playlists, history: history)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(payload).write(to: storeURL, options: .atomic)
    }

    private static func makeTrack(from url: URL) async -> Track {
        let asset = AVURLAsset(url: url)
        let metadata = (try? await asset.load(.commonMetadata)) ?? []
        let duration = try? await asset.load(.duration)
        let title = metadata.first(where: { $0.commonKey?.rawValue == "title" })?.stringValue
        let artist = metadata.first(where: { $0.commonKey?.rawValue == "artist" })?.stringValue
        let album = metadata.first(where: { $0.commonKey?.rawValue == "albumName" })?.stringValue
        let artwork = metadata.first(where: { $0.commonKey?.rawValue == "artwork" })?.dataValue
        let fallbackName = url.deletingPathExtension().lastPathComponent
        let seconds = duration?.seconds ?? 0

        return Track(
            title: title?.nilIfBlank ?? fallbackName,
            artist: artist?.nilIfBlank ?? "Unknown Artist",
            album: album?.nilIfBlank ?? "Unknown Album",
            filename: url.lastPathComponent,
            duration: seconds.isFinite ? seconds : 0,
            artworkData: artwork
        )
    }

    private static func isSupportedAudioExtension(_ ext: String) -> Bool {
        ["aac", "aif", "aiff", "flac", "m4a", "m4b", "mp3", "mp4", "wav", "caf"].contains(ext)
    }
}

private struct StoredLibrary: Codable {
    var tracks: [Track]
    var playlists: [Playlist]
    var history: [HistoryEntry]
}

private enum LibraryError: LocalizedError {
    case playlistAlreadyExists
    case unsupportedBackupVersion

    var errorDescription: String? {
        switch self {
        case .playlistAlreadyExists: "A playlist with that name already exists."
        case .unsupportedBackupVersion: "This backup was made by an unsupported ArchiveTune version."
        }
    }
}

private extension String {
    var nilIfBlank: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
