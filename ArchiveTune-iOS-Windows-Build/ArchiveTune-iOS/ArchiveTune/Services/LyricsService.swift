// ArchiveTune iOS native rewrite
// Based on ArchiveTune by Rukamori and contributors. GPL-3.0; see LICENSE.

import Foundation
import Combine

struct LyricLine: Identifiable, Equatable {
    var id: Int
    var time: TimeInterval
    var text: String
}

struct LyricsResult {
    var lines: [LyricLine]
    var isSynced: Bool
}

@MainActor
final class LyricsViewModel: ObservableObject {
    @Published private(set) var lines: [LyricLine] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var isSynced = false

    private var loadedTrackID: UUID?

    func load(for track: Track) async {
        guard loadedTrackID != track.id else { return }
        loadedTrackID = track.id
        isLoading = true
        errorMessage = nil
        lines = []
        do {
            let result = try await LyricsService.shared.fetchLyrics(for: track)
            lines = result.lines
            isSynced = result.isSynced
            if result.lines.isEmpty { errorMessage = "No lyrics were found for this track." }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct LyricsService {
    static let shared = LyricsService()

    func fetchLyrics(for track: Track) async throws -> LyricsResult {
        var components = URLComponents(string: "https://lrclib.net/api/get")!
        components.queryItems = [
            URLQueryItem(name: "track_name", value: track.title),
            URLQueryItem(name: "artist_name", value: track.artist),
            URLQueryItem(name: "album_name", value: track.album == "Unknown Album" ? nil : track.album),
            URLQueryItem(name: "duration", value: track.duration > 0 ? String(Int(track.duration.rounded())) : nil)
        ].filter { $0.value != nil }
        guard let url = components.url else { throw LyricsError.invalidRequest }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("ArchiveTune-iOS/1.0", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw LyricsError.invalidResponse }
        guard http.statusCode == 200 else {
            if http.statusCode == 404 { throw LyricsError.notFound }
            throw LyricsError.server(http.statusCode)
        }

        let payload = try JSONDecoder().decode(LRCLibPayload.self, from: data)
        if let synced = payload.syncedLyrics, !synced.isEmpty {
            return LyricsResult(lines: Self.parse(synced), isSynced: true)
        }
        if let plain = payload.plainLyrics, !plain.isEmpty {
            let plainLines = plain.components(separatedBy: .newlines).enumerated().map {
                LyricLine(id: $0.offset, time: 0, text: $0.element)
            }
            return LyricsResult(lines: plainLines, isSynced: false)
        }
        return LyricsResult(lines: [], isSynced: false)
    }

    private static func parse(_ lrc: String) -> [LyricLine] {
        let pattern = #"\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\]"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        var result: [LyricLine] = []
        for rawLine in lrc.components(separatedBy: .newlines) {
            let range = NSRange(rawLine.startIndex..., in: rawLine)
            let matches = regex.matches(in: rawLine, range: range)
            let text = regex.stringByReplacingMatches(in: rawLine, range: range, withTemplate: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }
            for match in matches {
                guard let minutesRange = Range(match.range(at: 1), in: rawLine),
                      let secondsRange = Range(match.range(at: 2), in: rawLine),
                      let minutes = Double(rawLine[minutesRange]),
                      let seconds = Double(rawLine[secondsRange]) else { continue }
                var fraction = 0.0
                if let fractionRange = Range(match.range(at: 3), in: rawLine) {
                    let rawFraction = String(rawLine[fractionRange])
                    fraction = Double("0." + rawFraction) ?? 0
                }
                result.append(LyricLine(id: result.count, time: minutes * 60 + seconds + fraction, text: text))
            }
        }
        return result.sorted { $0.time < $1.time }
    }
}

private struct LRCLibPayload: Decodable {
    var syncedLyrics: String?
    var plainLyrics: String?
}

private enum LyricsError: LocalizedError {
    case invalidRequest
    case invalidResponse
    case notFound
    case server(Int)

    var errorDescription: String? {
        switch self {
        case .invalidRequest: "The lyrics request could not be created."
        case .invalidResponse: "The lyrics service returned an invalid response."
        case .notFound: "No lyrics were found for this track."
        case .server(let code): "The lyrics service returned error \(code)."
        }
    }
}
