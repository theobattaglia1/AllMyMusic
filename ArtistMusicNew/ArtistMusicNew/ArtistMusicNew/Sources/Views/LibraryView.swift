//
//  LibraryView.swift
//  ArtistMusicNew
//
//  Created by Theo Battaglia on 5/18/25.
//

import SwiftUI
import UniformTypeIdentifiers

enum LibraryCategory {
    case songs, playlists
}

struct LibraryView: View {
    @EnvironmentObject private var store: EnhancedArtistStore
    @EnvironmentObject private var player: EnhancedAudioPlayer

    let category: LibraryCategory

    @State private var searchText = ""
    @State private var showingAddSongSheet = false
    @State private var showingAddPlaylist  = false
    @State private var editingSong: Song?
    @State private var editingPlaylist: Playlist?
    @State private var selectedSongID: UUID?

    var body: some View {
        VStack(spacing: 0) {
            if category == .songs {
                songsListView
            } else {
                playlistsGridView
            }
        }
        .navigationTitle(category == .songs ? "Songs" : "Playlists")
        .searchable(text: $searchText)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if category == .songs {
                    Button { showingAddSongSheet = true } label: {
                        Image(systemName: "plus.circle.fill").font(.title2)
                    }
                } else {
                    Button { showingAddPlaylist = true } label: {
                        Image(systemName: "plus.circle.fill").font(.title2)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddSongSheet) {
            AddSongSheet(artist: nil)
                .environmentObject(store)
                .environmentObject(player)
        }
        .sheet(isPresented: $showingAddPlaylist) {
            if let firstArtist = store.artists.first {
                AddPlaylistSheet(artist: firstArtist)
                    .environmentObject(store)
            } else {
                Text("Add an artist first.").padding()
            }
        }
        .sheet(item: $editingSong) { song in
            EditSongView(song: song)
                .environmentObject(store)
                .environmentObject(player)
        }
        .sheet(item: $editingPlaylist) { pl in
            EditPlaylistView(playlist: pl)
                .environmentObject(store)
        }
    }

    // MARK: – Songs List
    private var songsListView: some View {
        List(filteredSongs) { song in
            SongRow(song: song, selectedSongID: $selectedSongID)
                .contextMenu {
                    Button { editingSong = song } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        store.deleteSong(song)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
        }
        .onDrop(of: [UTType.audio], isTargeted: nil) { providers in
            // when an audio file is dropped, grab its URL and import it
            for provider in providers {
                if provider.hasItemConformingToTypeIdentifier(UTType.audio.identifier) {
                    _ = provider.loadObject(ofClass: URL.self) { url, _ in
                        if let url = url {
                            DispatchQueue.main.async {
                                importDroppedAudio([url])
                            }
                        }
                    }
                    return true
                }
            }
            return false
        }
    }

    private var filteredSongs: [Song] {
        let global = store.allSongs
        let artistSongs = store.artists.flatMap(\.songs)
        let combined = Dictionary(grouping: global + artistSongs, by: \.id)
            .compactMap { $0.value.first }
        return combined
            .filter {
                searchText.isEmpty ||
                $0.title.localizedCaseInsensitiveContains(searchText)
            }
            .sorted { lhs, rhs in
                lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
    }

    private func importDroppedAudio(_ urls: [URL]) {
        for url in urls {
            do {
                let local = try copyFileToDocuments(url)
                let song  = Song(
                    id: UUID(),
                    title: local.deletingPathExtension().lastPathComponent,
                    version: "",
                    artworkURL: nil,
                    audioURL: local,
                    duration: 0,
                    artistID: nil
                )
                store.addSong(song)
            } catch {
                print("[ERROR] drop import:", error)
            }
        }
    }

    // MARK: – Playlists Grid
    private var playlistsGridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 20) {
                ForEach(filteredPlaylists) { pl in
                    NavigationLink {
                        PlaylistDetailView(playlist: pl)
                            .environmentObject(store)
                            .environmentObject(player)
                    } label: {
                        PlaylistCard(playlist: pl)
                    }
                    .contextMenu {
                        Button { editingPlaylist = pl } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            store.deletePlaylist(pl)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding()
        }
    }

    private var filteredPlaylists: [Playlist] {
        store.artists.flatMap(\.playlists)
            .filter {
                searchText.isEmpty ||
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
    }
}

struct LibraryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            LibraryView(category: .songs)
                .environmentObject(EnhancedArtistStore())
                .environmentObject(EnhancedAudioPlayer())
        }
    }
}
