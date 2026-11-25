// ArchiveTune iOS native rewrite
// Based on ArchiveTune by Rukamori and contributors. GPL-3.0; see LICENSE.

import SwiftUI

struct DiscoverView: View {
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                ScreenBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        ScreenTitle(title: "Discover", subtitle: "Explore music beyond your local library")

                        VStack(alignment: .leading, spacing: 13) {
                            HStack {
                                Image(systemName: "play.rectangle.fill").font(.title).foregroundStyle(.red)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("YouTube Music").font(.headline)
                                    Text("Open the official music service").font(.caption).foregroundStyle(.white.opacity(0.6))
                                }
                                Spacer()
                                Image(systemName: "arrow.up.right").foregroundStyle(.white.opacity(0.55))
                            }
                            Link(destination: URL(string: "https://music.youtube.com")!) {
                                Text("Open YouTube Music")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 13)
                                    .background(Color.red.opacity(0.82), in: RoundedRectangle(cornerRadius: 14))
                            }
                            Text("YouTube Music sign-in, online catalog playback, and account syncing are handled by the official service. The iOS port does not extract or download protected streams.")
                                .font(.caption).foregroundStyle(.white.opacity(0.52)).fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(17)
                        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Search the web").font(.title3.weight(.bold))
                            TextField("Songs, artists, albums", text: $searchText)
                                .textInputAutocapitalization(.never)
                                .padding(13)
                                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 13))
                            if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                                Link(destination: youtubeSearchURL) {
                                    Label("Search YouTube Music", systemImage: "magnifyingglass")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 13)
                                        .background(.purple.opacity(0.55), in: RoundedRectangle(cornerRadius: 13))
                                }
                            }
                        }

                        EmptyState(icon: "sparkles", title: "More discovery is coming", message: "Native charts, recommendations, and online library sync need a supported music-service API or a project backend.")
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var youtubeSearchURL: URL {
        var components = URLComponents(string: "https://music.youtube.com/search")!
        components.queryItems = [URLQueryItem(name: "q", value: searchText)]
        return components.url ?? URL(string: "https://music.youtube.com")!
    }
}
