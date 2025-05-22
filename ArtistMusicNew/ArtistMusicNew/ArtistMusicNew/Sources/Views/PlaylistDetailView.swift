//
//  PlaylistDetailView.swift
//  ArtistMusicNew
//

import SwiftUI
import UniformTypeIdentifiers

struct PlaylistDetailView: View {
    let playlist: Playlist
    @EnvironmentObject private var player: EnhancedAudioPlayer
    @EnvironmentObject private var store: EnhancedArtistStore

    @State private var showingAddSong     = false
    @State private var showingAddPlaylist = false
    @State private var showingEditSheet   = false

    @State private var coverImage: UXImage?
    @State private var coverURL: URL?

    // Parent artist (if any)
    private var artist: Artist? { store.artists.first { $0.id == playlist.artistID } }

    init(playlist: Playlist) {
        self.playlist = playlist
        _coverURL    = State(initialValue: playlist.artworkURL)
        if let url  = playlist.artworkURL,
           let data = try? Data(contentsOf: url),
           let img  = UXImage(data: data) {
            _coverImage = State(initialValue: img)
        }
    }

    // --------------------------------------------------------------------
    // Body
    // --------------------------------------------------------------------
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                playAllButton
                songsList
            }
            .padding()
        }
        .navigationTitle(playlist.name)
#if canImport(UIKit)
.navigationBarTitleDisplayMode(.inline)
#endif
.toolbar { playlistToolbar }
        .sheet(isPresented: $showingAddSong)     { addSongSheet }
        .sheet(isPresented: $showingAddPlaylist) { addSubPlaylistSheet }
        .sheet(isPresented: $showingEditSheet)   { editSheet }

        // Whole scroll view accepts audio URLs
        .background(Color.clear)
        .contentShape(Rectangle())
        .dropDestination(for: URL.self) { urls, _ in
            handleAudioURLs(urls)
            return true
        }
    }

    // --------------------------------------------------------------------
    // Toolbar + sheets
    // --------------------------------------------------------------------
    private var playlistToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Menu {
                Button { showingAddSong = true } label: {
                    Label("Add Song", systemImage: "music.note")
                }
                Button { showingAddPlaylist = true } label: {
                    Label("Add Sub-Playlist", systemImage: "play.square.stack")
                }
            } label: { Image(systemName: "plus.circle.fill").font(.title2) }

            Button { showingEditSheet = true } label: { Image(systemName: "pencil") }
        }
    }

    @ViewBuilder private var addSongSheet: some View {
        if let art = artist {
            AddSongSheet(artist: art)
                .environmentObject(store)
                .environmentObject(player)
        }
    }
    @ViewBuilder private var addSubPlaylistSheet: some View {
        if let art = artist {
            AddPlaylistSheet(artist: art).environmentObject(store)
        }
    }
    private var editSheet: some View {
        EditPlaylistView(playlist: playlist)
            .environmentObject(store)
            .environmentObject(player)
    }

    // --------------------------------------------------------------------
    // Header (cover art + labels)
    // --------------------------------------------------------------------
    private var header: some View {
        VStack(spacing: 16) {
            ArtworkPicker(image: $coverImage) { img in
                do {
                    let saved = try saveCoverImageSync(img)
                    coverURL = saved
                    var updated = playlist
                    updated.artworkURL = saved
                    store.updatePlaylist(updated)
                } catch { print("[PlaylistHeader] save error:", error) }
            }
            .frame(width: 200, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 8)

            Text(playlist.name).font(.title2).bold()
            Text("\(playlist.songs.count) songs")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // --------------------------------------------------------------------
    // Play-all
    // --------------------------------------------------------------------
    private var playAllButton: some View {
        Button {
            player.setQueue(playlist.songs)
        } label: {
            Label("Play All", systemImage: "play.fill")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // --------------------------------------------------------------------
    // Songs list
    // --------------------------------------------------------------------
    private var songsList: some View {
        LazyVStack(spacing: 12) {
            ForEach(playlist.songs) { song in
                SongRow(song: song, selectedSongID: .constant(nil))
                    .contextMenu {
                        Button { player.playSong(song) } label: {
                            Label("Play", systemImage: "play.fill")
                        }
                        Button(role: .destructive) {
                            var updated = playlist
                            updated.songs.removeAll { $0.id == song.id }
                            store.updatePlaylist(updated)
                        } label: { Label("Remove", systemImage: "trash") }
                    }
            }
        }
        .padding(.horizontal)
    }

    // --------------------------------------------------------------------
    // Handle Finder drop
    // --------------------------------------------------------------------
    private func handleAudioURLs(_ urls: [URL]) {
        for url in urls {
            guard ["mp3","m4a","wav","aac","aif","aiff"].contains(url.pathExtension.lowercased()) else {
                print("[PlaylistDrop] ignored:", url.lastPathComponent); continue
            }
            let song = Song(
                id: UUID(),
                title: url.deletingPathExtension().lastPathComponent,
                version: "",
                artworkURL: nil,
                audioURL: url,
                duration: 0,
                artistID: playlist.artistID
            )
            var updated = playlist
            updated.songs.append(song)
            store.updatePlaylist(updated)
        }
    }

    // --------------------------------------------------------------------
    // Save cover art
    // --------------------------------------------------------------------
    private func saveCoverImageSync(_ image: UXImage) throws -> URL {
        let fm     = FileManager.default
        let docs   = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = docs.appendingPathComponent("PlaylistArtworks", isDirectory: true)
        try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        let filename = "PlaylistCover_\(UUID()).png"
        let fileURL  = folder.appendingPathComponent(filename)
        guard let data = image.pngDataCompat() else {
            throw NSError(domain: "PlaylistDetailView", code: -1)
        }
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }
}
