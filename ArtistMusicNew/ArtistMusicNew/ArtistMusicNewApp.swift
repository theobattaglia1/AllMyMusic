import SwiftUI

@main
struct ArtistMusicNewApp: App {
    @StateObject private var store = EnhancedArtistStore()
    @StateObject private var player = EnhancedAudioPlayer()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(store)
                .environmentObject(player)
                .frame(minWidth: 800, minHeight: 600)
        }
#if os(macOS)
        MenuBarExtra("Now Playing", systemImage: "music.note") {
            NowPlayingView()
                .environmentObject(store)
                .environmentObject(player)
                .frame(width: 300, height: 450)
        }
        .menuBarExtraStyle(.window)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .undoRedo) { }
            CommandGroup(replacing: .pasteboard) { }
        }
        .defaultSize(width: 1024, height: 768)
        .defaultPosition(.center)
        #endif
    }
} 