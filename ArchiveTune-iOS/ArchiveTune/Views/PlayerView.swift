// ArchiveTune iOS native rewrite
// Based on ArchiveTune by Rukamori and contributors. GPL-3.0; see LICENSE.

import SwiftUI

struct PlayerView: View {
    @EnvironmentObject private var player: AudioPlayer
    @Environment(\.dismiss) private var dismiss
    @State private var showLyrics = false
    @State private var showQueue = false

    var body: some View {
        ZStack {
            ScreenBackground()
            if let track = player.currentTrack {
                VStack(spacing: 0) {
                    HStack {
                        Button { dismiss() } label: { Image(systemName: "chevron.down").font(.headline).frame(width: 40, height: 40) }
                        Spacer()
                        VStack(spacing: 2) {
                            Text("NOW PLAYING").font(.caption2.weight(.bold)).tracking(1.4).foregroundStyle(.white.opacity(0.5))
                            Text("LOCAL LIBRARY").font(.caption2).foregroundStyle(.white.opacity(0.35))
                        }
                        Spacer()
                        Menu {
                            Picker("Playback speed", selection: Binding(get: { player.playbackRate }, set: { player.setPlaybackRate($0) })) {
                                Text("0.5×").tag(Float(0.5))
                                Text("0.75×").tag(Float(0.75))
                                Text("1×").tag(Float(1.0))
                                Text("1.25×").tag(Float(1.25))
                                Text("1.5×").tag(Float(1.5))
                                Text("2×").tag(Float(2.0))
                            }
                        } label: {
                            Image(systemName: "speedometer").font(.headline).frame(width: 40, height: 40)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    Spacer(minLength: 25)
                    ArtworkView(data: track.artworkData, size: min(UIScreen.main.bounds.width - 76, 330))
                        .shadow(color: .black.opacity(0.4), radius: 26, y: 15)
                        .padding(.horizontal, 30)
                    Spacer(minLength: 28)

                    HStack(alignment: .center, spacing: 14) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(track.title).font(.title2.weight(.bold)).lineLimit(2)
                            Text(track.artist).font(.subheadline).foregroundStyle(.white.opacity(0.6)).lineLimit(1)
                        }
                        Spacer()
                        Image(systemName: "waveform").font(.title2).foregroundStyle(.purple.opacity(0.9))
                    }
                    .padding(.horizontal, 26)

                    VStack(spacing: 7) {
                        Slider(value: Binding(get: { player.currentTime }, set: { player.seek(to: $0) }), in: 0...max(player.duration, 1))
                            .tint(.purple)
                        HStack {
                            Text(player.currentTime.tuneTime)
                            Spacer()
                            Text("-\(max(0, player.duration - player.currentTime).tuneTime)")
                        }
                        .font(.caption.monospacedDigit()).foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(.horizontal, 25)
                    .padding(.top, 16)

                    HStack(spacing: 0) {
                        Button { player.toggleShuffle() } label: {
                            Image(systemName: "shuffle").font(.title3).foregroundStyle(player.isShuffled ? .purple : .white.opacity(0.55))
                                .frame(maxWidth: .infinity).frame(height: 54)
                        }
                        Button { player.playPrevious() } label: {
                            Image(systemName: "backward.end.fill").font(.title2).frame(maxWidth: .infinity).frame(height: 58)
                        }
                        Button { player.togglePlayback() } label: {
                            Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundStyle(.black)
                                .frame(width: 68, height: 68)
                                .background(.white, in: Circle())
                        }
                        .accessibilityLabel(player.isPlaying ? "Pause" : "Play")
                        Button { player.playNext() } label: {
                            Image(systemName: "forward.end.fill").font(.title2).frame(maxWidth: .infinity).frame(height: 58)
                        }
                        Button { player.cycleRepeatMode() } label: {
                            Image(systemName: player.repeatMode.symbol).font(.title3)
                                .foregroundStyle(player.repeatMode == .off ? .white.opacity(0.55) : .purple)
                                .frame(maxWidth: .infinity).frame(height: 54)
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.top, 17)

                    HStack(spacing: 12) {
                        Button { showLyrics = true } label: {
                            Label("Lyrics", systemImage: "quote.bubble").font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity).padding(.vertical, 12).background(.white.opacity(0.08), in: Capsule())
                        }
                        Button { showQueue = true } label: {
                            Label("Queue (\(player.queue.count))", systemImage: "list.bullet").font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity).padding(.vertical, 12).background(.white.opacity(0.08), in: Capsule())
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.top, 18)
                    .padding(.bottom, 18)
                }
            } else {
                EmptyState(icon: "music.note", title: "Nothing playing", message: "Choose a track from your library.")
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showLyrics) {
            if let track = player.currentTrack { LyricsSheet(track: track) }
        }
        .sheet(isPresented: $showQueue) { QueueSheet() }
    }
}

private struct LyricsSheet: View {
    @EnvironmentObject private var player: AudioPlayer
    @StateObject private var model = LyricsViewModel()
    let track: Track

    private var activeLineID: Int? {
        guard model.isSynced else { return nil }
        return model.lines.last(where: { $0.time <= player.currentTime + 0.15 })?.id
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScreenBackground()
                if model.isLoading {
                    ProgressView("Finding lyrics…").tint(.white).foregroundStyle(.white)
                } else if let error = model.errorMessage {
                    EmptyState(icon: "quote.bubble", title: "Lyrics unavailable", message: error)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 18) {
                                ForEach(model.lines) { line in
                                    Text(line.text.isEmpty ? " " : line.text)
                                        .font(.system(size: line.id == activeLineID ? 23 : 18, weight: line.id == activeLineID ? .bold : .medium, design: .rounded))
                                        .foregroundStyle(line.id == activeLineID ? .white : .white.opacity(0.45))
                                        .multilineTextAlignment(.center)
                                        .frame(maxWidth: .infinity)
                                        .id(line.id)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 32)
                        }
                        .onChange(of: activeLineID) { _, id in
                            guard let id else { return }
                            withAnimation(.easeInOut(duration: 0.25)) { proxy.scrollTo(id, anchor: .center) }
                        }
                    }
                }
            }
            .navigationTitle("Lyrics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text(model.isSynced ? "SYNCED" : "PLAIN")
                        .font(.caption2.weight(.bold)).tracking(1).foregroundStyle(.white.opacity(0.45))
                }
            }
        }
        .preferredColorScheme(.dark)
        .task(id: track.id) { await model.load(for: track) }
    }
}

private struct QueueSheet: View {
    @EnvironmentObject private var player: AudioPlayer
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                ScreenBackground()
                List {
                    ForEach(Array(player.queue.enumerated()), id: \.element.id) { index, track in
                        Button {
                            player.playAll(player.queue, startingAt: index)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                ArtworkView(data: track.artworkData, size: 46)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(track.title).font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                                    Text(track.artist).font(.caption).foregroundStyle(.white.opacity(0.55))
                                }
                                Spacer()
                                if index == player.currentIndex { Image(systemName: "waveform").foregroundStyle(.purple) }
                            }
                        }
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain).scrollContentBackground(.hidden)
            }
            .navigationTitle("Up next")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
        .preferredColorScheme(.dark)
    }
}
