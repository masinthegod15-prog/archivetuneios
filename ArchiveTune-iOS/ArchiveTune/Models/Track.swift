// ArchiveTune iOS native rewrite
// Based on ArchiveTune by Rukamori and contributors. GPL-3.0; see LICENSE.

import Foundation

struct Track: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var title: String
    var artist: String
    var album: String
    var filename: String
    var duration: TimeInterval
    var artworkData: Data?
    var dateAdded: Date = .now

    var fileURL: URL {
        LibraryPaths.audioDirectory.appendingPathComponent(filename, isDirectory: false)
    }

    static func == (lhs: Track, rhs: Track) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct Playlist: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var trackIDs: [UUID] = []
    var dateCreated: Date = .now
}

struct HistoryEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var trackID: UUID
    var playedAt: Date = .now
    var listenedSeconds: TimeInterval = 0
}

struct BackupPayload: Codable {
    var formatVersion: Int = 1
    var createdAt: Date = .now
    var tracks: [Track]
    var playlists: [Playlist]
    var history: [HistoryEntry]
    var audioFiles: [String: Data]
}

enum RepeatMode: String, CaseIterable, Identifiable {
    case off
    case all
    case one

    var id: String { rawValue }
    var next: RepeatMode {
        switch self {
        case .off: .all
        case .all: .one
        case .one: .off
        }
    }

    var symbol: String {
        switch self {
        case .off: "repeat"
        case .all: "repeat"
        case .one: "repeat.1"
        }
    }
}


enum LibraryPaths {
    static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static var audioDirectory: URL {
        documentsDirectory.appendingPathComponent("Audio", isDirectory: true)
    }
}
