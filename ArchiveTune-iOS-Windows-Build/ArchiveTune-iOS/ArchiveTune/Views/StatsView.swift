// ArchiveTune iOS native rewrite
// Based on ArchiveTune by Rukamori and contributors. GPL-3.0; see LICENSE.

import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var player: AudioPlayer

    private var totalListened: TimeInterval { library.history.reduce(0) { $0 + $1.listenedSeconds } }
    private var groupedPlays: [(track: Track, plays: Int, seconds: TimeInterval)] {
        let groups = Dictionary(grouping: library.history, by: \.trackID)
        return groups.compactMap { id, entries in
            guard let track = library.tracks.first(where: { $0.id == id }) else { return nil }
            return (track, entries.count, entries.reduce(0) { $0 + $1.listenedSeconds })
        }
        .sorted { $0.plays > $1.plays }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScreenBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 23) {
                        ScreenTitle(title: "Your listening", subtitle: "Private stats stored on this device")

                        HStack(spacing: 12) {
                            StatCard(value: "\(library.history.count)", label: "Plays", icon: "play.fill")
                            StatCard(value: totalListened.formattedMinutes, label: "Minutes", icon: "clock")
                            StatCard(value: "\(library.tracks.count)", label: "Tracks", icon: "music.note")
                        }
                        .padding(.horizontal, 20)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Most played").font(.title3.weight(.bold))
                            if groupedPlays.isEmpty {
                                EmptyState(icon: "chart.bar", title: "No listening data yet", message: "Play something from your library and your stats will appear here.")
                            } else {
                                ForEach(Array(groupedPlays.prefix(10).enumerated()), id: \.element.track.id) { index, item in
                                    HStack(spacing: 12) {
                                        Text("\(index + 1)").font(.caption.monospacedDigit()).foregroundStyle(.white.opacity(0.5)).frame(width: 18)
                                        ArtworkView(data: item.track.artworkData, size: 46)
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(item.track.title).font(.subheadline.weight(.semibold)).lineLimit(1)
                                            Text("\(item.track.artist) · \(item.plays) plays").font(.caption).foregroundStyle(.white.opacity(0.55))
                                        }
                                        Spacer()
                                        Button { player.play(item.track, from: library.tracks) } label: { Image(systemName: "play.circle.fill").font(.title2) }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 30)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

private struct StatCard: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon).foregroundStyle(.purple.opacity(0.95))
            Text(value).font(.title2.weight(.bold).monospacedDigit())
            Text(label).font(.caption).foregroundStyle(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 17))
    }
}

private extension TimeInterval {
    var formattedMinutes: String {
        let minutes = Int(self / 60)
        if minutes < 60 { return "\(minutes)" }
        return "\(minutes / 60)h \(minutes % 60)m"
    }
}
