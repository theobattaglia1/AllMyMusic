import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @EnvironmentObject private var store: EnhancedArtistStore
    @EnvironmentObject private var player: EnhancedAudioPlayer
    @State private var searchText = ""
    @State private var showingAddPlaylist = false
    @State private var selectedSongToEdit: Song?
    @State private var showingFileImporter = false
    @State private var selectedSongID: UUID?
    
    enum LibraryCategory {
        case songs
        case playlists
    }
    
    let libraryCategory: LibraryCategory
    
    var body: some View {
        VStack(spacing: 0) {
            if libraryCategory == .songs {
                songsListView
            } else {
                playlistsGridView
            }
        }
        .navigationTitle(libraryCategory == .songs ? "Songs" : "Playlists")
        .searchable(text: $searchText, prompt: "Search \(libraryCategory == .songs ? "songs" : "playlists")")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if libraryCategory == .songs || libraryCategory == .playlists {
                    Button {
                        print("Add button tapped, libraryCategory: \(libraryCategory)")
                        if libraryCategory == .songs {
                            #if os(macOS)
                            NotificationCenter.default.post(
                                name: NSNotification.Name("ImportSongs"),
                                object: nil
                            )
                            #else
                            showingFileImporter = true
                            #endif
                        } else {
                            showingAddPlaylist = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddPlaylist) {
            NavigationStack {
                AddPlaylistSheet(artist: nil)
                    .environmentObject(store)
                    .environmentObject(player)
            }
        }
        .sheet(item: $selectedSongToEdit) { song in
            EditSongView(song: song)
                .environmentObject(store)
                .environmentObject(player)
        }
        #if !os(macOS)
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.audio, .mp3, .wav, .aiff, .mpeg4Audio],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                handleDroppedFiles(items: urls, for: .songs)
            case .failure(let error):
                print("File import failed: \(error.localizedDescription)")
            }
        }
        #endif
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            Task {
                var urls: [URL] = []
                for provider in providers {
                    if let url = try? await provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) as? URL {
                        urls.append(url)
                    }
                }
                if !urls.isEmpty {
                    handleDroppedFiles(items: urls, for: libraryCategory)
                }
            }
            return true
        }
    }
    
    private var songsListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredSongs) { song in
                    SongRow(song: song, selectedSongID: $selectedSongID)
                        .contextMenu {
                            Button {
                                selectedSongToEdit = song
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                store.deleteSong(song)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(.horizontal)
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            Task {
                var urls: [URL] = []
                for provider in providers {
                    if let url = try? await provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) as? URL {
                        urls.append(url)
                    }
                }
                if !urls.isEmpty {
                    handleDroppedFiles(items: urls, for: .songs)
                }
            }
            return true
        }
    }
    
    private var playlistsGridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 20) {
                ForEach(filteredPlaylists) { playlist in
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
                            Label {
                                Text("Delete")
                            } icon: {
                                Image(systemName: "trash")
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            Task {
                var urls: [URL] = []
                for provider in providers {
                    if let url = try? await provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) as? URL {
                        urls.append(url)
                    }
                }
                if !urls.isEmpty {
                    handleDroppedFiles(items: urls, for: libraryCategory)
                }
            }
            return true
        }
    }
    
    private var filteredSongs: [Song] {
        if searchText.isEmpty {
            return store.allSongs
        }
        return store.allSongs.filter { song in
            let titleMatch = song.title.localizedCaseInsensitiveContains(searchText)
            let versionMatch = song.version.localizedCaseInsensitiveContains(searchText)
            let artistMatch = song.artistID.map { artistID in
                store.artists.first(where: { $0.id == artistID })?.name.localizedCaseInsensitiveContains(searchText) ?? false
            } ?? false
            
            return titleMatch || versionMatch || artistMatch
        }
    }
    
    private var filteredPlaylists: [Playlist] {
        if searchText.isEmpty {
            return store.allPlaylists
        }
        return store.allPlaylists.filter { playlist in
            playlist.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private func handleDroppedFiles(items: [URL], for category: LibraryCategory) {
        guard category == .songs else { return }
        
        for fileURL in items {
            // Start accessing the security-scoped resource
            guard fileURL.startAccessingSecurityScopedResource() else {
                print("Failed to access security-scoped resource: \(fileURL)")
                continue
            }
            
            defer {
                fileURL.stopAccessingSecurityScopedResource()
            }
            
            // Check if the file is an audio file
            if fileURL.pathExtension.lowercased().contains("mp3") ||
               fileURL.pathExtension.lowercased().contains("wav") ||
               fileURL.pathExtension.lowercased().contains("aiff") ||
               fileURL.pathExtension.lowercased().contains("m4a") {
                
                let songTitle = fileURL.deletingPathExtension().lastPathComponent
                let newSong = Song(
                    id: UUID(),
                    title: songTitle,
                    version: "",
                    artworkURL: nil,
                    audioURL: fileURL,
                    duration: 0,
                    artistID: nil
                )
                store.addSong(newSong)
            }
        }
    }
}

enum LibraryCategory {
    // ... existing code ...
} 