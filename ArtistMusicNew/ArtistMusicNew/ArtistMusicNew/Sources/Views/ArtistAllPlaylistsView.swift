import SwiftUI

struct ArtistAllPlaylistsView: View {
    let artist: Artist
    @EnvironmentObject private var store: EnhancedArtistStore
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 20)
            ], spacing: 20) {
                ForEach(artist.playlists) { playlist in
                    NavigationLink {
                        PlaylistDetailView(playlist: playlist)
                    } label: {
                        PlaylistCard(playlist: playlist)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            store.deletePlaylist(playlist)
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Playlists")
    }
}

// MARK: - Preview Provider
struct ArtistAllPlaylistsView_Previews: PreviewProvider {
    static var previews: some View {
        let store = EnhancedArtistStore()
        let artist = Artist(
            id: UUID(),
            name: "Sample Artist",
            artworkURL: nil,
            songs: [],
            playlists: []
        )
        store.addArtist(artist)
        
        return NavigationStack {
            ArtistAllPlaylistsView(artist: artist)
                .environmentObject(store)
        }
    }
} 