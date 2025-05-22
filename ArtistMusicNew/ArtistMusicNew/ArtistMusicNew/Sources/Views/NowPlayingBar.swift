import SwiftUI

@MainActor
class NowPlayingViewModel: ObservableObject {
    @Published var isDraggingSlider = false
    @Published var sliderValue: TimeInterval = 0
    @Published var shouldSkipBackward = false
    @Published var shouldPlayPause = false
    @Published var shouldSkipForward = false
    @Published var isNowPlayingViewPresented = false
    
    private weak var player: EnhancedAudioPlayer?
    
    init(player: EnhancedAudioPlayer) {
        self.player = player
    }
    
    func handleSkipBackward() {
        player?.skipBackward()
    }
    
    func handlePlayPause() {
        guard let player = player else { return }
        if player.isPlaying {
            player.pause()
        } else if let song = player.currentSong {
            player.playSong(song)
        }
    }
    
    func handleSkipForward() {
        player?.skipForward()
    }
    
    func handleSeek() {
        player?.seek(to: sliderValue)
    }
    
    func updatePlayer(_ newPlayer: EnhancedAudioPlayer) {
        self.player = newPlayer
    }
}

struct NowPlayingBar: View {
    @EnvironmentObject private var player: EnhancedAudioPlayer
    @EnvironmentObject private var store: EnhancedArtistStore
    @StateObject private var viewModel: NowPlayingViewModel
    
    init() {
        // Initialize with a temporary player
        let tempPlayer = EnhancedAudioPlayer()
        _viewModel = StateObject(wrappedValue: NowPlayingViewModel(player: tempPlayer))
    }
    
    private var artistName: String {
        guard let artistID = player.currentSong?.artistID else { return "Unknown Artist" }
        return store.artists.first(where: { $0.id == artistID })?.name ?? "Unknown Artist"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Slider(value: $viewModel.sliderValue, in: 0...player.duration) {
                Text("Seek")
            } onEditingChanged: { isEditing in
                viewModel.isDraggingSlider = isEditing
                if !isEditing {
                    viewModel.handleSeek()
                }
            }
            .padding(.horizontal)
            .disabled(player.currentSong == nil)
            .onChange(of: player.currentTime) { oldValue, newValue in
                if !viewModel.isDraggingSlider {
                    viewModel.sliderValue = newValue
                }
            }
            
            HStack {
                Group {
                    if let url = player.currentSong?.artworkURL, FileManager.default.fileExists(atPath: url.path), let data = try? Data(contentsOf: url), let image = UXImage(data: data) {
                        Image(uxImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.5))
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                
                VStack(alignment: .leading) {
                    Text(player.currentSong?.title ?? "Not Playing")
                        .font(.caption)
                        .lineLimit(1)
                    Text(artistName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                HStack(spacing: 20) {
                    Button {
                        viewModel.handleSkipBackward()
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.title)
                    }
                    .disabled(player.currentSong == nil)
                    
                    Button {
                        viewModel.handlePlayPause()
                    } label: {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title)
                    }
                    
                    Button {
                        viewModel.handleSkipForward()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.title)
                    }
                    .disabled(player.currentSong == nil)
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 60)
        .background(.thinMaterial)
        .onAppear {
            viewModel.updatePlayer(player)
        }
        .onTapGesture {
            viewModel.isNowPlayingViewPresented = true
        }
        .sheet(isPresented: $viewModel.isNowPlayingViewPresented) {
            #if os(iOS)
            NowPlayingView()
                .environmentObject(player)
                .environmentObject(store)
            #else
            NowPlayingView()
                .environmentObject(player)
                .environmentObject(store)
                .frame(width: 400, height: 600)
            #endif
        }
    }
} 
