// ArchiveTune iOS native rewrite
// Based on ArchiveTune by Rukamori and contributors. GPL-3.0; see LICENSE.

import SwiftUI

@main
struct ArchiveTuneApp: App {
    @StateObject private var library = LibraryStore()
    @StateObject private var player = AudioPlayer()
    @AppStorage("archiveTuneAppearance") private var appearance = "dark"

    private var preferredScheme: ColorScheme? {
        switch appearance {
        case "light": .light
        case "system": nil
        default: .dark
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(library)
                .environmentObject(player)
                .preferredColorScheme(preferredScheme)
        }
    }
}
