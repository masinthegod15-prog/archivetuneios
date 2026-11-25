// ArchiveTune iOS native rewrite
// Based on ArchiveTune by Rukamori and contributors. GPL-3.0; see LICENSE.

import SwiftUI

struct HomeView: View {
    var onOpenLibrary: () -> Void = {}
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var player: AudioPlayer
    @State private var showImport = false
    @State private var importMessage: String?
    @State private var showSearch = false

    private var recentlyAdded: [Track] { Array(library.tracks.prefix(5)) }
    private var recentlyPlayed: [Track] {
        library.history.compactMap { entry in library.tracks.first(where: { $0.id == entry.trackID }) }
            .reduce(into: [Track]()) { result, track in
                if !result.contains(where: { $0.id == track.id }) { result.append(track) }
            }
            .prefix(5).map { $0 }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScreenBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(greeting).font(.subheadline.weight(.medium)).foregroundStyle(.white.opacity(0.62))
                                Text("Your music,\nyour way.")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .lineSpacing(-3)
                            }
                            Spacer()
                            Button { showSearch = true } label: {
                                Image(systemName: "magnifyingglass").font(.headline)
                                    .frame(width: 44, height: 44)
                                    .background(.white.opacity(0.1), in: Circle())
                            }
                            .accessibilityLabel("Search your library")
                        }
                        .padding(.top, 16)

                        HStack(spacing: 12) {
                            HomeActionCard(title: "Import music", subtitle: "Add audio files", icon: "plus", color: .purple) { showImport = true }
                            HomeActionCard(title: "Your library", subtitle: "\(library.tracks.count) tracks", icon: "music.note.list", color: .indigo, action: onOpenLibrary)
                        }

                        if library.tracks.isEmpty {
                            EmptyState(icon: "music.note", title: "Your library is empty", message: "Import MP3, M4A, AAC, FLAC, WAV, or AIFF files to start listening.")
                        }

                        if !recentlyPlayed.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                sectionHeader("Recently played", detail: "Pick up where you left off")
                                ForEach(Array(recentlyPlayed.enumerated()), id: \.element.id) { _, track in
                                    TrackRow(track: track, onTap: { player.play(track, from: library.tracks) }, onAddToPlaylist: { id in try? library.add(track, to: id) })
                                }
                            }
                        }

                        if !recentlyAdded.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                sectionHeader("Recently added", detail: "Fresh in your collection")
                                ForEach(Array(recentlyAdded.enumerated()), id: \.element.id) { _, track in
                                    TrackRow(track: track, onTap: { player.play(track, from: library.tracks) }, onAddToPlaylist: { id in try? library.add(track, to: id) })
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showSearch) { SearchView() }
            .fileImporter(isPresented: $showImport, allowedContentTypes: [.audio], allowsMultipleSelection: true) { result in
                switch result {
                case .success(let urls):
                    Task {
                        do {
                            let count = try await library.importFiles(urls)
                            importMessage = count == 1 ? "Imported 1 track." : "Imported \(count) tracks."
                        } catch { importMessage = error.localizedDescription }
                    }
                case .failure(let error): importMessage = error.localizedDescription
                }
            }
            .alert("Music import", isPresented: Binding(get: { importMessage != nil }, set: { if !$0 { importMessage = nil } })) {
                Button("OK", role: .cancel) { importMessage = nil }
            } message: { Text(importMessage ?? "") }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        if hour < 12 { return "GOOD MORNING" }
        if hour < 18 { return "GOOD AFTERNOON" }
        return "GOOD EVENING"
    }

    private func sectionHeader(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.title3.weight(.bold))
            Text(detail).font(.caption).foregroundStyle(.white.opacity(0.55))
        }
    }
}

private struct HomeActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 13) {
                Image(systemName: icon).font(.title2.weight(.semibold)).foregroundStyle(.white)
                    .frame(width: 42, height: 42).background(color.opacity(0.55), in: RoundedRectangle(cornerRadius: 13))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.subheadline.weight(.bold)).foregroundStyle(.white)
                    Text(subtitle).font(.caption).foregroundStyle(.white.opacity(0.58))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
            .padding(14)
            .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.08), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
