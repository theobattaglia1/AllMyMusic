import Foundation
import AVFoundation
import SwiftUI

@MainActor                // everything on the main actor
final class EnhancedAudioPlayer: ObservableObject {

    // MARK: - Published
    @Published private(set) var currentSong : Song?
    @Published private(set) var isPlaying   = false
    @Published private(set) var currentTime : TimeInterval = 0
    @Published private(set) var duration    : TimeInterval = 0

    @Published var volume: Float = 1.0 {
        didSet { player.volume = volume }
    }

    // MARK: - AVFoundation
    private let player = AVPlayer()          // single instance
    private var timeObserver: Any?

    // MARK: - Queue
    private var queue: [Song] = []
    private var currentIndex  = 0

    // MARK: - Init / deinit
    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playNext),
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )
    }

    deinit {
        // deinit is *not* isolated; remove observer directly
        if let token = timeObserver { player.removeTimeObserver(token) }
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public control
    func playSong(_ song: Song) {
        removeTimeObserver()

        // swap player item
        player.replaceCurrentItem(with: AVPlayerItem(url: song.audioURL))

        // periodic time updates
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main                                   // still hop to MainActor
        ) { [weak self] time in
            guard let self else { return }
            Task { @MainActor in
                self.currentTime = time.seconds
                if let dur = self.player.currentItem?.duration.seconds,
                   dur.isFinite { self.duration = dur }
            }
        }

        player.volume = volume
        player.play()

        currentSong = song
        isPlaying   = true
    }

    func pause()  { player.pause(); isPlaying = false }
    func resume() { guard player.currentItem != nil else { return }
                    player.play(); isPlaying = true }

    func seek(to t: TimeInterval) { player.seek(to: .init(seconds: t,
                                                          preferredTimescale: 600)) }
    func skipBackward() { seek(to: max(0, currentTime - 10)) }
    func skipForward()  { seek(to: min(duration, currentTime + 10)) }

    // MARK: Queue
    func setQueue(_ songs: [Song]) {
        queue = songs; currentIndex = 0
        if let first = songs.first { playSong(first) }
    }

    @objc func playNext() {
        guard !queue.isEmpty else { return }
        currentIndex = (currentIndex + 1) % queue.count
        playSong(queue[currentIndex])
    }

    func playPrevious() {
        guard !queue.isEmpty else { return }
        currentIndex = (currentIndex - 1 + queue.count) % queue.count
        playSong(queue[currentIndex])
    }

    // MARK: Helper
    private func removeTimeObserver() {
        if let token = timeObserver {
            player.removeTimeObserver(token)
            timeObserver = nil
        }
    }
}
