import AVFoundation
import Combine // Import Combine for @Published

class EnhancedAudioPlayer: ObservableObject { // Make it an ObservableObject
    private var player: AVAudioPlayer?
    @Published var currentSong: Song? // Make currentSong published
    @Published private var isPlaying = false
    @Published var duration = 0.0 // Make duration published
    @Published var currentTime = 0.0 // Make currentTime public
    private var volume = 1.0
    private var timeObserverToken: Any? // Keep a reference to the time observer
    
    private var songQueue: [Song] = [] // Add a queue for playback
    private var currentSongIndex: Int? // Track the index of the current song in the queue

    // Expose isPlaying state (can remove this now, isPlaying is published)
    // var isPlayingSong: Bool { isPlaying }
    
    func playSong(_ song: Song) {
        // Stop any currently playing song and remove observer
        stop()

        let url = song.audioURL
        
        do {
            // Ensure the URL is a file URL
            guard url.isFileURL else {
                print("Error: URL is not a file URL: \(url)")
                return
            }
            
            // Check if file exists
            guard FileManager.default.fileExists(atPath: url.path) else {
                print("Error: File does not exist at path: \(url.path)")
                return
            }
            
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.volume = volume
            player?.play()
            
            currentSong = song
            isPlaying = true
            duration = player?.duration ?? 0
            currentTime = 0.0 // Reset current time on new song
            
            // Find the index of the played song in the queue
            if let index = songQueue.firstIndex(where: { $0.id == song.id }) {
                currentSongIndex = index
            } else {
                // If the song is not in the current queue, clear the queue and add this song
                songQueue = [song]
                currentSongIndex = 0
            }
            
            // Start timer and store the observer token
            startTimer()
        } catch {
            print("Error playing song: \(error.localizedDescription)")
            print("Error details: \(error)")
        }
    }
    
    // Add a method to set the playback queue
    func setQueue(_ queue: [Song]) {
        songQueue = queue
        currentSongIndex = nil // Reset current index when setting a new queue
    }
    
    // Add skip forward functionality
    func skipForward() {
        guard let currentIndex = currentSongIndex, currentIndex < songQueue.count - 1 else {
            print("Cannot skip forward: already at the end of the queue.")
            return
        }
        playSong(songQueue[currentIndex + 1])
    }
    
    // Add skip backward functionality
    func skipBackward() {
        guard let currentIndex = currentSongIndex, currentIndex > 0 else {
            print("Cannot skip backward: already at the beginning of the queue.")
            // Optionally restart the current song if at the beginning
            player?.currentTime = 0.0
            currentTime = 0.0
            return
        }
        playSong(songQueue[currentIndex - 1])
    }
    
    func stop() {
        player?.stop()
        player = nil
        currentSong = nil
        isPlaying = false
        duration = 0.0
        currentTime = 0.0 // Reset current time on stop
        
        // Invalidate and remove the time observer
        if let token = timeObserverToken {
             // Assuming startTimer uses addPeriodicTimeObserver on the player:
             player?.removeTimeObserver(token) // This should now work if called BEFORE player is set to nil
             timeObserverToken = nil
        }
    }

    // Add pause functionality
    func pause() {
        player?.pause()
        isPlaying = false
    }
    
    // Add resume functionality
    func resume() {
        player?.play()
        isPlaying = true
    }
    
    // Add seek functionality
    func seek(to time: TimeInterval) {
        player?.currentTime = time
        currentTime = time // Update published current time immediately
    }

    private func startTimer() {
        // Implement the time observer
        guard let player = player else { return }

        // Remove existing observer if any
        if let token = timeObserverToken {
            player.removeTimeObserver(token)
        }

        // Add a new periodic time observer
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
        }
    }
    
    // You'll likely need other playback controls like pause, resume, seek, etc.
} 