// ArchiveTune iOS native rewrite
// Based on ArchiveTune by Rukamori and contributors. GPL-3.0; see LICENSE.

import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var player: AudioPlayer
    @State private var selectedSection = "Songs"
    @State private var showImporter = false
    @State private var showCreatePlaylist = false
    @State private var selectedPlaylist: Playlist?
    @State private var alertMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                ScreenBackground()
                VStack(spacing: 13) {
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Library").font(.system(size: 30, weight: .bold, design: .rounded))
                            Text("\(library.tracks.count) tracks · \(library.playlists.count) playlists")
                                .font(.caption).foregroundStyle(.white.opacity(0.56))
                        }
                        Spacer()
                        Menu {
                            Button { showImporter = true } label: { Label("Import audio files", systemImage: "plus") }
                            Button { showCreatePlaylist = true } label: { Label("New playlist", systemImage: "text.badge.plus") }
                        } label: {
                            Image(systemName: "plus").font(.headline.weight(.bold)).frame(width: 42, height: 42)
                                .background(.white.opacity(0.1), in: Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    Picker("Library section", selection: $selectedSection) {
                        Text("Songs").tag("Songs")
                        Text("Playlists").tag("Playlists")
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)

                    if selectedSection == "Songs" {
                        if library.tracks.isEmpty {
                            EmptyState(icon: "music.note.list", title: "No songs yet", message: "Import audio files from your device or cloud drive.")
                            Spacer()
                        } else {
                            List {
                                ForEach(Array(library.tracks.enumerated()), id: \.element.id) { index, track in
                                    TrackRow(track: track, number: index + 1, onTap: { player.play(track, from: library.tracks) }, onAddToPlaylist: { id in try? library.add(track, to: id) })
                                        .listRowBackground(Color.clear)
                                        .listRowSeparatorTint(.white.opacity(0.08))
                                }
                            }
                            .listStyle(.plain)
                            .scrollContentBackground(.hidden)
                        }
                    } else {
                        if library.playlists.isEmpty {
                            EmptyState(icon: "text.badge.plus", title: "Make your first playlist", message: "Group your favorite tracks into collections.")
                            Spacer()
                        } else {
                            List {
                                ForEach(library.playlists) { playlist in
                                    Button { selectedPlaylist = playlist } label: {
                                        HStack(spacing: 13) {
                                            RoundedRectangle(cornerRadius: 13).fill(.purple.opacity(0.28)).frame(width: 54, height: 54)
                                                .overlay(Image(systemName: "music.note.list").font(.title3).foregroundStyle(.white))
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(playlist.name).font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                                                Text("\(playlist.trackIDs.count) tracks").font(.caption).foregroundStyle(.white.opacity(0.55))
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(.white.opacity(0.4))
                                        }
                                    }
                                    .listRowBackground(Color.clear)
                                    .listRowSeparatorTint(.white.opacity(0.08))
                                    .swipeActions {
                                        Button(role: .destructive) { try? library.deletePlaylist(playlist) } label: { Label("Delete", systemImage: "trash") }
                                    }
                                }
                            }
                            .listStyle(.plain)
                            .scrollContentBackground(.hidden)
                        }
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.audio], allowsMultipleSelection: true) { result in
                switch result {
                case .success(let urls):
                    Task {
                        do {
                            let count = try await library.importFiles(urls)
                            alertMessage = "Imported \(count) audio file(s)."
                        } catch { alertMessage = error.localizedDescription }
                    }
                case .failure(let error): alertMessage = error.localizedDescription
                }
            }
            .sheet(isPresented: $showCreatePlaylist) { CreatePlaylistSheet() }
            .sheet(item: $selectedPlaylist) { playlist in
                PlaylistDetailView(playlist: playlist)
            }
            .alert("ArchiveTune", isPresented: Binding(get: { alertMessage != nil }, set: { if !$0 { alertMessage = nil } })) {
                Button("OK", role: .cancel) { alertMessage = nil }
            } message: { Text(alertMessage ?? "") }
        }
    }
}

private struct CreatePlaylistSheet: View {
    @EnvironmentObject private var library: LibraryStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Playlist name") {
                    TextField("My playlist", text: $name)
                }
                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red).font(.caption)
                }
                Section {
                    Text("Playlists are stored on this device and included in local backups.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("New playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        do { try library.createPlaylist(named: name); dismiss() }
                        catch { errorMessage = error.localizedDescription }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private struct PlaylistDetailView: View {
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var player: AudioPlayer
    @Environment(\.dismiss) private var dismiss
    let playlist: Playlist
    @State private var showRename = false
    @State private var newName = ""

    private var tracks: [Track] { library.playlistTracks(playlist) }

    var body: some View {
        NavigationStack {
            ZStack {
                ScreenBackground()
                VStack(spacing: 0) {
                    if !tracks.isEmpty {
                        Button { player.playAll(tracks) } label: {
                            Label("Play all", systemImage: "play.fill")
                                .font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                                .frame(maxWidth: .infinity).padding(.vertical, 13)
                                .background(.purple.opacity(0.6), in: RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    }
                    if tracks.isEmpty {
                        EmptyState(icon: "music.note", title: "This playlist is empty", message: "Use the menu on a song to add it to this playlist.")
                    } else {
                        List {
                            ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                                TrackRow(track: track, number: index + 1, onTap: { player.play(track, from: tracks) })
                                    .listRowBackground(Color.clear)
                            }
                        }
                        .listStyle(.plain).scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle(playlist.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Rename playlist", systemImage: "pencil") { newName = playlist.name; showRename = true }
                        Button("Delete playlist", systemImage: "trash", role: .destructive) { try? library.deletePlaylist(playlist); dismiss() }
                    } label: { Image(systemName: "ellipsis.circle") }
                }
            }
            .alert("Rename playlist", isPresented: $showRename) {
                TextField("Playlist name", text: $newName)
                Button("Cancel", role: .cancel) { }
                Button("Save") { try? library.renamePlaylist(playlist, to: newName) }
            }
        }
    }
}
