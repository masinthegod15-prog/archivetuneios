// ArchiveTune iOS native rewrite
// Based on ArchiveTune by Rukamori and contributors. GPL-3.0; see LICENSE.

import SwiftUI

private enum TunePalette {
    static let accent = Color(red: 0.66, green: 0.48, blue: 1.0)
    static let deep = Color(red: 0.075, green: 0.065, blue: 0.12)
    static let surface = Color.white.opacity(0.075)
    static let muted = Color.white.opacity(0.58)
}

struct ScreenBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color(red: 0.105, green: 0.085, blue: 0.17), TunePalette.deep, Color.black],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct ScreenTitle: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 30, weight: .bold, design: .rounded))
            if let subtitle {
                Text(subtitle).font(.subheadline).foregroundStyle(TunePalette.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }
}

struct ArtworkView: View {
    let data: Data?
    var size: CGFloat = 54

    var body: some View {
        Group {
            if let data, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                ZStack {
                    LinearGradient(colors: [TunePalette.accent.opacity(0.8), Color.purple.opacity(0.35)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    Image(systemName: "waveform").font(.system(size: size * 0.34, weight: .semibold)).foregroundStyle(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.18, style: .continuous))
    }
}

struct TrackRow: View {
    let track: Track
    var number: Int? = nil
    var onTap: () -> Void
    var onAddToPlaylist: ((UUID) -> Void)? = nil
    @EnvironmentObject private var library: LibraryStore

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    if let number {
                        Text("\(number)").font(.caption.monospacedDigit()).foregroundStyle(TunePalette.muted).frame(width: 18)
                    }
                    ArtworkView(data: track.artworkData, size: 50)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(track.title).font(.subheadline.weight(.semibold)).lineLimit(1).foregroundStyle(.white)
                        Text("\(track.artist) · \(track.album)").font(.caption).lineLimit(1).foregroundStyle(TunePalette.muted)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
            Menu {
                if let onAddToPlaylist {
                    if library.playlists.isEmpty {
                        Text("Create a playlist first")
                    } else {
                        Menu("Add to playlist") {
                            ForEach(library.playlists) { playlist in
                                Button(playlist.name) { onAddToPlaylist(playlist.id) }
                            }
                        }
                    }
                }
                Button(role: .destructive) {
                    try? library.remove(track)
                } label: {
                    Label("Remove from library", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis").font(.headline).foregroundStyle(TunePalette.muted).padding(8)
            }
        }
        .padding(.vertical, 5)
    }
}

struct MiniPlayer: View {
    @EnvironmentObject private var player: AudioPlayer
    @State private var showPlayer = false

    var body: some View {
        if let track = player.currentTrack {
            HStack(spacing: 11) {
                Button { showPlayer = true } label: {
                    HStack(spacing: 11) {
                        ArtworkView(data: track.artworkData, size: 42)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(track.title).font(.subheadline.weight(.semibold)).lineLimit(1).foregroundStyle(.white)
                            Text(track.artist).font(.caption).lineLimit(1).foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                Button { player.togglePlayback() } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title3).frame(width: 38, height: 42)
                }
                .accessibilityLabel(player.isPlaying ? "Pause" : "Play")
                Button { player.playNext() } label: {
                    Image(systemName: "forward.end.fill").font(.title3).frame(width: 34, height: 42)
                }
                .accessibilityLabel("Next track")
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(.white.opacity(0.1), lineWidth: 1))
            .padding(.horizontal, 12)
            .padding(.bottom, 5)
            .sheet(isPresented: $showPlayer) { PlayerView().environmentObject(player) }
        }
    }
}

struct EmptyState: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 38, weight: .light)).foregroundStyle(TunePalette.accent)
            Text(title).font(.headline)
            Text(message).font(.subheadline).foregroundStyle(TunePalette.muted).multilineTextAlignment(.center).frame(maxWidth: 270)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 42)
    }
}

extension TimeInterval {
    var tuneTime: String {
        guard isFinite, self >= 0 else { return "0:00" }
        let total = Int(self)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
