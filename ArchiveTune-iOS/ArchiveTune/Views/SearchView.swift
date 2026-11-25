// ArchiveTune iOS native rewrite
// Based on ArchiveTune by Rukamori and contributors. GPL-3.0; see LICENSE.

import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var player: AudioPlayer
    @State private var query = ""

    private var results: [Track] {
        guard !query.isEmpty else { return library.tracks }
        return library.tracks.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.artist.localizedCaseInsensitiveContains(query) ||
            $0.album.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        ZStack {
            ScreenBackground()
            VStack(spacing: 14) {
                ScreenTitle(title: "Search", subtitle: "Find a song in your collection")
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.white.opacity(0.55))
                    TextField("Search songs, artists, albums", text: $query)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                .padding(14)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 15))
                .padding(.horizontal, 20)

                if results.isEmpty {
                    EmptyState(icon: "magnifyingglass", title: "No matches", message: "Try another title, artist, or album.")
                    Spacer()
                } else {
                    List {
                        ForEach(results) { track in
                            TrackRow(track: track, onTap: { player.play(track, from: results) }, onAddToPlaylist: { id in try? library.add(track, to: id) })
                                .listRowBackground(Color.clear)
                                .listRowSeparatorTint(.white.opacity(0.08))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}
