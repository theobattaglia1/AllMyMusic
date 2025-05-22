//
//  ArtistDetailView.swift
//  ArtistMusicNew
//

import SwiftUI
import UniformTypeIdentifiers

struct ArtistDetailView: View {
    let artist: Artist
    @EnvironmentObject private var store: EnhancedArtistStore
    @EnvironmentObject private var player: EnhancedAudioPlayer

    @State private var selectedTab       = 0
    @State private var showingAddSong    = false
    @State private var showingAddPlaylist = false
    @State private var showingEdit       = false

    @State private var headerImage: UXImage?
    @State private var headerURL: URL?

    // --------------------------------------------------------------------
    // Init – pre-load artwork
    // --------------------------------------------------------------------
    init(artist: Artist) {
        self.artist = artist
        _headerURL  = State(initialValue: artist.artworkURL)
        if let url  = artist.artworkURL,
           let data = try? Data(contentsOf: url),
           let img  = UXImage(data: data) {
            _headerImage = State(initialValue: img)
        }
    }

    // --------------------------------------------------------------------
    // View body
    // --------------------------------------------------------------------
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                artworkHeader

                Picker("", selection: $selectedTab) {
                    Text("Songs").tag(0)
                    Text("Playlists").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if selectedTab == 0 { songsList } else { playlistsList }
            }
            .padding(.vertical)
        }
        .navigationTitle(artist.name)
        #if canImport(UIKit)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button { showingAddSong = true }      label: { Image(systemName: "music.note") }
                Button { showingAddPlaylist = true }  label: { Image(systemName: "play.square.stack") }
                Button { showingEdit = true }         label: { Image(systemName: "pencil") }
            }
        }
        .sheet(isPresented: $showingAddSong) {
            AddSongSheet(artist: artist)
                .environmentObject(store)
                .environmentObject(player)
        }
        .sheet(isPresented: $showingAddPlaylist) {
            AddPlaylistSheet(artist: artist)
                .environmentObject(store)
        }
        .sheet(isPresented: $showingEdit) {
            EditArtistView(artist: artist)
                .environmentObject(store)
        }
    }

    // --------------------------------------------------------------------
    // Header (artwork picker + labels)
    // --------------------------------------------------------------------
    private var artworkHeader: some View {
        VStack(spacing: 16) {
            ArtworkPicker(image: $headerImage) { img in
                do {
                    let saved = try saveArtworkImageSync(img)
                    headerURL = saved
                    var updated = artist
                    updated.artworkURL = saved
                    store.updateArtist(updated)
                } catch { print("[ArtistHeader] save error:", error) }
            }
            .frame(width: 200, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 8)

            Text(artist.name).font(.title2).bold()
            Text("\(artist.songs.count) songs • \(artist.playlists.count) playlists")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // --------------------------------------------------------------------
    // SONGS – list + Finder drop
    // --------------------------------------------------------------------
    private var songsList: some View {
        LazyVStack(spacing: 12) {
            ForEach(artist.songs) { song in
                SongRow(song: song, selectedSongID: .constant(nil))
                    .contextMenu {
                        Button { player.playSong(song) } label: {
                            Label("Play", systemImage: "play.fill")
                        }
                        Button(role: .destructive) {
                            var updated = artist
                            updated.songs.removeAll { $0.id == song.id }
                            store.updateArtist(updated)
                        } label: { Label("Remove", systemImage: "trash") }
                    }
            }
        }
        .padding(.horizontal)

        // Give the whole area a hit-testable body
        .background(Color.clear)
        .contentShape(Rectangle())

        // macOS 15 / iOS 18 unified drop API
        .dropDestination(for: URL.self) { urls, _ in
            handleAudioURLs(urls)
            return true
        }
    }

    private func handleAudioURLs(_ urls: [URL]) {
        for url in urls {
            guard ["mp3","m4a","wav","aac","aif","aiff"].contains(url.pathExtension.lowercased()) else {
                print("[ArtistDrop] ignored:", url.lastPathComponent); continue
            }
            let newSong = Song(
                id: UUID(),
                title: url.deletingPathExtension().lastPathComponent,
                version: "",
                artworkURL: nil,
                audioURL: url,
                duration: 0,
                artistID: artist.id
            )
            var updated = artist
            updated.songs.append(newSong)
            store.updateArtist(updated)
        }
    }

    // --------------------------------------------------------------------
    // PLAYLIST grid (drag target handled inside PlaylistDetail itself)
    // --------------------------------------------------------------------
    private var playlistsList: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 20)]) {
            ForEach(artist.playlists) { playlist in
                NavigationLink {
                    PlaylistDetailView(playlist: playlist)
                        .environmentObject(store)
                        .environmentObject(player)
                } label: {
                    PlaylistCard(playlist: playlist)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
    }

    // --------------------------------------------------------------------
    // Save artwork helper
    // --------------------------------------------------------------------
    private func saveArtworkImageSync(_ image: UXImage) throws -> URL {
        let fm   = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir  = docs.appendingPathComponent("ArtistArtworks", isDirectory: true)
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        let url  = dir.appendingPathComponent("ArtistArtwork_\(artist.id).png")
        guard let data = image.pngDataCompat() else {
            throw NSError(domain: "ArtistDetailView", code: -1)
        }
        try data.write(to: url, options: .atomic)
        return url
    }
}
