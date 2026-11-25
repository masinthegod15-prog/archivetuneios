// ArchiveTune iOS native rewrite
// Based on ArchiveTune by Rukamori and contributors. GPL-3.0; see LICENSE.

import AVFoundation
import Combine
import MediaPlayer
import UIKit

@MainActor
final class AudioPlayer: ObservableObject {
    @Published private(set) var queue: [Track] = []
    @Published private(set) var currentIndex: Int?
    @Published private(set) var isPlaying = false
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published var isShuffled = false
    @Published var repeatMode: RepeatMode = .off
    @Published var playbackRate: Float = 1.0

    private let player = AVPlayer()
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?

    var currentTrack: Track? {
        guard let currentIndex, queue.indices.contains(currentIndex) else { return nil }
        return queue[currentIndex]
    }

    init() {
        configureAudioSession()
        installTimeObserver()
        installEndObserver()
        configureRemoteCommands()
    }

    func play(_ track: Track, from tracks: [Track]) {
        queue = tracks
        currentIndex = queue.firstIndex(where: { $0.id == track.id })
        if currentIndex == nil {
            queue.insert(track, at: 0)
            currentIndex = 0
        }
        startCurrentTrack()
    }

    func playAll(_ tracks: [Track], startingAt index: Int = 0) {
        guard !tracks.isEmpty else { return }
        queue = tracks
        currentIndex = min(max(index, 0), tracks.count - 1)
        startCurrentTrack()
    }

    func togglePlayback() {
        if isPlaying { pause() } else { resume() }
    }

    func pause() {
        player.pause()
        isPlaying = false
        updateNowPlayingInfo()
    }

    func resume() {
        guard currentTrack != nil else { return }
        try? AVAudioSession.sharedInstance().setActive(true)
        player.playImmediately(atRate: playbackRate)
        isPlaying = true
        updateNowPlayingInfo()
    }

    func playNext() {
        guard !queue.isEmpty else { return }
        if isShuffled, queue.count > 1 {
            var candidates = Array(queue.indices)
            if let currentIndex { candidates.removeAll { $0 == currentIndex } }
            currentIndex = candidates.randomElement()
        } else if let currentIndex, currentIndex + 1 < queue.count {
            self.currentIndex = currentIndex + 1
        } else if repeatMode == .all {
            currentIndex = 0
        } else {
            pause()
            player.seek(to: .zero)
            currentTime = 0
            return
        }
        startCurrentTrack()
    }

    func playPrevious() {
        guard !queue.isEmpty else { return }
        if currentTime > 3 {
            seek(to: 0)
            return
        }
        if let currentIndex, currentIndex > 0 {
            self.currentIndex = currentIndex - 1
        } else if repeatMode == .all {
            currentIndex = queue.count - 1
        } else {
            seek(to: 0)
            return
        }
        startCurrentTrack()
    }

    func seek(to seconds: TimeInterval) {
        let target = max(0, min(seconds, duration > 0 ? duration : seconds))
        player.seek(to: CMTime(seconds: target, preferredTimescale: 600))
        currentTime = target
        updateNowPlayingInfo()
    }

    func setPlaybackRate(_ rate: Float) {
        playbackRate = min(max(rate, 0.5), 2.0)
        if isPlaying { player.rate = playbackRate }
        updateNowPlayingInfo()
    }

    func toggleShuffle() { isShuffled.toggle() }
    func cycleRepeatMode() { repeatMode = repeatMode.next }

    private func startCurrentTrack() {
        guard let track = currentTrack else { return }
        player.pause()
        let item = AVPlayerItem(url: track.fileURL)
        item.audioTimePitchAlgorithm = .timeDomain
        player.replaceCurrentItem(with: item)
        currentTime = 0
        duration = track.duration
        try? AVAudioSession.sharedInstance().setActive(true)
        player.playImmediately(atRate: playbackRate)
        isPlaying = true
        updateNowPlayingInfo()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("ArchiveTune audio session: \(error.localizedDescription)")
        }
    }

    private func installTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            let seconds = time.seconds
            if seconds.isFinite { self.currentTime = seconds }
            if let itemDuration = self.player.currentItem?.duration.seconds, itemDuration.isFinite, itemDuration > 0 {
                self.duration = itemDuration
            }
            self.updateNowPlayingInfo()
        }
    }

    private func installEndObserver() {
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if self.repeatMode == .one {
                    self.seek(to: 0)
                    self.resume()
                } else {
                    self.playNext()
                }
            }
        }
    }

    private func configureRemoteCommands() {
        let commands = MPRemoteCommandCenter.shared()
        commands.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.resume() }
            return .success
        }
        commands.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.pause() }
            return .success
        }
        commands.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.togglePlayback() }
            return .success
        }
        commands.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.playNext() }
            return .success
        }
        commands.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.playPrevious() }
            return .success
        }
        commands.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            Task { @MainActor in self?.seek(to: event.positionTime) }
            return .success
        }
    }

    private func updateNowPlayingInfo() {
        guard let track = currentTrack else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtist: track.artist,
            MPMediaItemPropertyAlbumTitle: track.album,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? playbackRate : 0,
            MPNowPlayingInfoPropertyPlaybackQueueIndex: currentIndex ?? 0,
            MPNowPlayingInfoPropertyPlaybackQueueCount: queue.count
        ]
        if duration > 0 { info[MPMediaItemPropertyPlaybackDuration] = duration }
        if let data = track.artworkData, let image = UIImage(data: data) {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}
