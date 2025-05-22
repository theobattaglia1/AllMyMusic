import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: EnhancedArtistStore
    @EnvironmentObject private var player: EnhancedAudioPlayer
    @AppStorage("useICloudSync") private var useICloudSync = true
    @AppStorage("autoPlay") private var autoPlay = true
    @AppStorage("showArtwork") private var showArtwork = true
    @State private var showingResetAlert = false
    
    var body: some View {
        List {
            // iCloud Sync Section
            Section {
                Toggle("Use iCloud Sync", isOn: $useICloudSync)
                
                if useICloudSync {
                    HStack {
                        Text("Sync Status")
                        Spacer()
                        if store.isLoading {
                            ProgressView()
                        } else {
                            Text("Up to date")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("iCloud Sync")
            } footer: {
                Text("Enable iCloud sync to keep your music library synchronized across devices.")
            }
            
            // Playback Section
            Section {
                Toggle("Auto-play", isOn: $autoPlay)
                Toggle("Show Artwork", isOn: $showArtwork)
                
                HStack {
                    Text("Volume")
                    Spacer()
                    Slider(value: $player.volume, in: 0...1)
                        .frame(width: 150)
                }
            } header: {
                Text("Playback")
            }
            
            // Library Section
            Section {
                Button(role: .destructive) {
                    showingResetAlert = true
                } label: {
                    Label("Reset Library", systemImage: "trash")
                }
            } header: {
                Text("Library")
            } footer: {
                Text("This will remove all artists, songs, and playlists from your library.")
            }
            
            // About Section
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("About")
            }
        }
        .alert("Reset Library", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                // Reset library
            }
        } message: {
            Text("Are you sure you want to reset your library? This action cannot be undone.")
        }
    }
}

// MARK: - Settings Toggle
struct SettingsToggle: View {
    let title: String
    let systemImage: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            Label(title, systemImage: systemImage)
        }
    }
}

// MARK: - Settings Button
struct SettingsButton: View {
    let title: String
    let systemImage: String
    let role: ButtonRole?
    let action: () -> Void
    
    init(
        title: String,
        systemImage: String,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.role = role
        self.action = action
    }
    
    var body: some View {
        Button(role: role, action: action) {
            Label(title, systemImage: systemImage)
        }
    }
} 