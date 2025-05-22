import SwiftUI

struct NowPlayingView: View {
    @EnvironmentObject private var player: EnhancedAudioPlayer
    @EnvironmentObject private var store: EnhancedArtistStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var isDraggingSlider = false
    @State private var sliderValue: TimeInterval = 0
    @State private var artworkScale: CGFloat = 1.0
    
    private var artistName: String {
        guard let artistID = player.currentSong?.artistID else { return "Unknown Artist" }
        return store.artists.first(where: { $0.id == artistID })?.name ?? "Unknown Artist"
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.title2)
                    }
                    
                    Spacer()
                    
                    Text("Now Playing")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button {
                        // Show queue
                    } label: {
                        Image(systemName: "list.bullet")
                            .font(.title2)
                    }
                }
                .padding()
                
                // Artwork
                Group {
                    if let url = player.currentSong?.artworkURL, FileManager.default.fileExists(atPath: url.path), let data = try? Data(contentsOf: url), let image = UXImage(data: data) {
                        Image(uxImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(artworkScale)
                            .frame(maxWidth: geometry.size.width * 0.8)
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.5))
                            .frame(maxWidth: geometry.size.width * 0.8)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 10)
                .padding()
                
                // Song Info
                VStack(spacing: 8) {
                    Text(player.currentSong?.title ?? "Not Playing")
                        .font(.title2)
                        .bold()
                    
                    Text(artistName)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .padding()
                
                // Progress
                VStack(spacing: 8) {
                    Slider(value: $sliderValue, in: 0...player.duration) {
                        Text("Seek")
                    } onEditingChanged: { isEditing in
                        isDraggingSlider = isEditing
                        if !isEditing {
                            player.seek(to: sliderValue)
                        }
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        Text(formatTime(player.currentTime))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text(formatTime(player.duration))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                
                // Controls
                HStack(spacing: 40) {
                    Button {
                        player.skipBackward()
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.title)
                    }
                    
                    Button {
                        if player.isPlaying {
                            player.pause()
                        } else if let song = player.currentSong {
                            player.playSong(song)
                        }
                    } label: {
                        Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 64))
                    }
                    
                    Button {
                        player.skipForward()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.title)
                    }
                }
                .padding()
                
                // Additional Controls
                HStack(spacing: 40) {
                    Button {
                        // Toggle shuffle
                    } label: {
                        Image(systemName: "shuffle")
                            .font(.title2)
                    }
                    
                    Button {
                        // Toggle repeat
                    } label: {
                        Image(systemName: "repeat")
                            .font(.title2)
                    }
                    
                    Button {
                        // Show lyrics
                    } label: {
                        Image(systemName: "text.quote")
                            .font(.title2)
                    }
                }
                .padding()
                
                Spacer()
            }
#if os(iOS)
    .background(Color(UXColor.systemBackground))
#else
    .background(Color(UXColor.windowBackgroundColor))
#endif

            .onChange(of: player.currentTime) { oldValue, newValue in
                if !isDraggingSlider {
                    sliderValue = newValue
                }
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    NowPlayingView()
        .environmentObject(EnhancedAudioPlayer())
        .environmentObject(EnhancedArtistStore())
} 
