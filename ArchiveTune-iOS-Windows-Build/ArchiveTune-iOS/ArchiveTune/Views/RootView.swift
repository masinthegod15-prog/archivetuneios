// ArchiveTune iOS native rewrite
// Based on ArchiveTune by Rukamori and contributors. GPL-3.0; see LICENSE.

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var player: AudioPlayer
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(onOpenLibrary: { selectedTab = 2 }).tabItem { Label("Home", systemImage: "house.fill") }.tag(0)
            DiscoverView().tabItem { Label("Discover", systemImage: "safari") }.tag(1)
            LibraryView().tabItem { Label("Library", systemImage: "square.stack.fill") }.tag(2)
            StatsView().tabItem { Label("Stats", systemImage: "chart.bar.fill") }.tag(3)
            SettingsView().tabItem { Label("Settings", systemImage: "slider.horizontal.3") }.tag(4)
        }
        .tint(Color(red: 0.68, green: 0.50, blue: 1.0))
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if player.currentTrack != nil { MiniPlayer() }
        }
        .onChange(of: player.currentTime) { oldValue, newValue in
            guard player.isPlaying, let track = player.currentTrack else { return }
            library.addListeningTime(trackID: track.id, seconds: newValue - oldValue)
        }
        .onChange(of: player.currentTrack?.id) { _, newID in
            guard let newID, let track = library.tracks.first(where: { $0.id == newID }) else { return }
            library.recordPlay(track)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background || phase == .inactive { library.flush() }
        }
    }
}
