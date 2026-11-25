// ArchiveTune iOS native rewrite
// Based on ArchiveTune by Rukamori and contributors. GPL-3.0; see LICENSE.

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var library: LibraryStore
    @AppStorage("archiveTuneAppearance") private var appearance = "dark"
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var exportDocument = BackupDocument(data: Data())
    @State private var alertTitle = "ArchiveTune"
    @State private var alertMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                ScreenBackground()
                Form {
                    Section("Appearance") {
                        Picker("Theme", selection: $appearance) {
                            Text("Dark").tag("dark")
                            Text("Light").tag("light")
                            Text("System").tag("system")
                        }
                        .tint(.purple)
                    }

                    Section("Playback") {
                        LabeledContent("Background audio", value: "Enabled")
                        LabeledContent("Lock Screen controls", value: "Enabled")
                    }

                    Section("Library & backup") {
                        Button { createBackup() } label: { Label("Export full backup", systemImage: "square.and.arrow.up") }
                        Button { showImporter = true } label: { Label("Restore from backup", systemImage: "square.and.arrow.down") }
                        Text("A backup includes your imported audio files, playlists, listening history, and library metadata. Large libraries create large files.")
                            .font(.caption).foregroundStyle(.secondary)
                    }

                    Section("Online services") {
                        LabeledContent("Lyrics", value: "LRCLIB")
                        Link(destination: URL(string: "https://music.youtube.com")!) {
                            Label("YouTube Music", systemImage: "arrow.up.right.square")
                        }
                        Text("YouTube Music account integration, online playback, Spotify import, and scrobbling are not connected in this iOS build. See PORT_STATUS.md for the current port status.")
                            .font(.caption).foregroundStyle(.secondary)
                    }

                    Section("About") {
                        LabeledContent("Version", value: "iOS Preview 1.0")
                        Link(destination: URL(string: "https://github.com/rukamori/ArchiveTune")!) {
                            Label("Original ArchiveTune project", systemImage: "github")
                        }
                        Link(destination: URL(string: "https://github.com/rukamori/ArchiveTune/blob/main/LICENSE")!) {
                            Label("GPL-3.0 License", systemImage: "doc.text")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .foregroundStyle(.white)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .fileExporter(
                isPresented: $showExporter,
                document: exportDocument,
                contentType: .json,
                defaultFilename: "ArchiveTune-Backup"
            ) { result in
                switch result {
                case .success: showAlert("Backup exported", "Your ArchiveTune backup was saved.")
                case .failure(let error): showAlert("Export failed", error.localizedDescription)
                }
            }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json], allowsMultipleSelection: false) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    let hasAccess = url.startAccessingSecurityScopedResource()
                    defer { if hasAccess { url.stopAccessingSecurityScopedResource() } }
                    do {
                        try library.restoreBackup(Data(contentsOf: url))
                        showAlert("Backup restored", "Your library and playlists were restored.")
                    } catch { showAlert("Restore failed", error.localizedDescription) }
                case .failure(let error): showAlert("Restore failed", error.localizedDescription)
                }
            }
            .alert(alertTitle, isPresented: Binding(get: { alertMessage != nil }, set: { if !$0 { alertMessage = nil } })) {
                Button("OK", role: .cancel) { alertMessage = nil }
            } message: { Text(alertMessage ?? "") }
        }
    }

    private func createBackup() {
        do {
            exportDocument = BackupDocument(data: try library.makeBackup())
            showExporter = true
        } catch { showAlert("Backup failed", error.localizedDescription) }
    }

    private func showAlert(_ title: String, _ message: String) {
        alertTitle = title
        alertMessage = message
    }
}
