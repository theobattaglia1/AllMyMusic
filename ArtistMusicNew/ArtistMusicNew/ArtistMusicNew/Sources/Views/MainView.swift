import SwiftUI
#if os(macOS)
import AppKit
#endif

enum MainViewCategory: String, CaseIterable, Identifiable {
    case artists = "Artists"
    case songs = "Songs"
    case playlists = "Playlists"
    case settings = "Settings"
    
    var id: String { self.rawValue }
    
    var systemImage: String {
        switch self {
        case .artists:
            return "person.2.fill"
        case .songs:
            return "music.note"
        case .playlists:
            return "play.square.stack"
        case .settings:
            return "gear"
        }
    }
}

struct MainView: View {
    @EnvironmentObject private var store: EnhancedArtistStore
    @EnvironmentObject private var player: EnhancedAudioPlayer
    @State private var selectedCategory: MainViewCategory? = .artists
    @State private var selectedArtist: Artist? = nil
    @State private var selectedPlaylist: Playlist? = nil
    @State private var artistsExpanded = true
    @State private var playlistsExpanded = true
    
    var body: some View {
        ZStack(alignment: .bottom) {
            NavigationSplitView {
                List(selection: $selectedCategory) {
                    // Artists main label
                    Button {
                        selectedCategory = .artists
                        selectedArtist = nil
                    } label: {
                        Label("Artists", systemImage: MainViewCategory.artists.systemImage)
                    }
                    .buttonStyle(.plain)
                    
                    // Artists dropdown
                    DisclosureGroup(isExpanded: $artistsExpanded) {
                        ForEach(store.artists) { artist in
                            Button {
                                selectedArtist = artist
                                selectedCategory = .artists
                            } label: {
                                Label(artist.name, systemImage: "person.fill")
                            }
                            .buttonStyle(.plain)
                        }
                    } label: { EmptyView() }
                    
                    // Playlists main label
                    Button {
                        selectedCategory = .playlists
                        selectedPlaylist = nil
                    } label: {
                        Label("Playlists", systemImage: MainViewCategory.playlists.systemImage)
                    }
                    .buttonStyle(.plain)
                    
                    // Playlists dropdown
                    DisclosureGroup(isExpanded: $playlistsExpanded) {
                        ForEach(store.artists.flatMap { $0.playlists }) { playlist in
                            Button {
                                selectedPlaylist = playlist
                                selectedCategory = .playlists
                            } label: {
                                Label(playlist.name, systemImage: "play.square")
                            }
                            .buttonStyle(.plain)
                        }
                    } label: { EmptyView() }
                    
                    // Songs
                    Button { selectedCategory = .songs } label: {
                        Label("Songs", systemImage: MainViewCategory.songs.systemImage)
                    }
                    .buttonStyle(.plain)
                    
                    // Settings
                    Button { selectedCategory = .settings } label: {
                        Label("Settings", systemImage: MainViewCategory.settings.systemImage)
                    }
                    .buttonStyle(.plain)
                }
                .navigationTitle("Library")
            } content: {
                // Main content pane
                if selectedCategory == .artists, let artist = selectedArtist {
                    ArtistDetailView(artist: artist)
                        .environmentObject(store)
                        .environmentObject(player)
                    
                } else if selectedCategory == .playlists, let playlist = selectedPlaylist {
                    PlaylistDetailView(playlist: playlist)
                        .environmentObject(store)
                        .environmentObject(player)
                    
                } else if let category = selectedCategory {
                    switch category {
                    case .artists:
                        ArtistsView()
                            .environmentObject(store)
                            .environmentObject(player)
                    case .songs:
                        LibraryView(category: .songs)
                            .environmentObject(store)
                            .environmentObject(player)
                    case .playlists:
                        LibraryView(category: .playlists)
                            .environmentObject(store)
                            .environmentObject(player)
                    case .settings:
                        SettingsView()
                    }
                } else {
                    Text("Select a category")
                }
            } detail: {
                // Right‐hand pane (optional)
                Text("Select an item")
            }
            
            NowPlayingBar()
                .ignoresSafeArea(.keyboard, edges: .bottom)
        }
#if os(macOS)
        .background(
            KeyboardEventHandlingView(onSpace: {
                guard !isTextFieldFocused() else { return }
                if player.isPlaying {
                    player.pause()
                } else if let song = player.currentSong {
                    player.playSong(song)
                }
            })
        )
#endif
    }
    
#if os(macOS)
    private func isTextFieldFocused() -> Bool {
        if let responder = NSApp.keyWindow?.firstResponder,
           responder.isKind(of: NSTextView.self) {
            return true
        }
        return false
    }
#endif
}

#if os(macOS)
struct KeyboardEventHandlingView: NSViewRepresentable {
    let onSpace: () -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        context.coordinator.monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 49
               && !event.modifierFlags.contains(.command)
               && !event.modifierFlags.contains(.option)
               && !event.modifierFlags.contains(.control) {
                onSpace()
                return nil
            }
            return event
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        if let monitor = coordinator.monitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    func makeCoordinator() -> Coordinator { Coordinator() }
    
    class Coordinator { var monitor: Any? }
}
#endif

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        let store = EnhancedArtistStore()
        let player = EnhancedAudioPlayer()
        return MainView()
            .environmentObject(store)
            .environmentObject(player)
    }
}
