import Foundation
import SwiftUI

@MainActor
class EnhancedArtistStore: ObservableObject {
    @Published private(set) var artists: [Artist] = []
    @Published private(set) var allSongs: [Song] = []
    @Published private(set) var allPlaylists: [Playlist] = []
    @Published var collaborators: [Collaborator] = []
    @Published private(set) var isLoading = false
    
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    private let artistsFileURL: URL
    private let songsFileURL: URL
    private let playlistsFileURL: URL
    private let collaboratorsFileURL: URL
    
    init() {
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        artistsFileURL = documentsDirectory.appendingPathComponent("artists.json")
        songsFileURL = documentsDirectory.appendingPathComponent("songs.json")
        playlistsFileURL = documentsDirectory.appendingPathComponent("playlists.json")
        collaboratorsFileURL = documentsDirectory.appendingPathComponent("collaborators.json")
        loadData()
    }
    
    // MARK: - Data Persistence
    private func save() {
        do {
            let encoder = JSONEncoder()
            
            // Save Artists
            let artistsData = try encoder.encode(artists)
            try artistsData.write(to: artistsFileURL)
            print("Saved artists to \(artistsFileURL.path)")
            
            // Save All Songs
            let songsData = try encoder.encode(allSongs)
            try songsData.write(to: songsFileURL)
            print("Saved all songs to \(songsFileURL.path)")
            
            // Save All Playlists
            let playlistsData = try encoder.encode(allPlaylists)
            try playlistsData.write(to: playlistsFileURL)
            print("Saved all playlists to \(playlistsFileURL.path)")
            
            // Save Collaborators
            let collaboratorsData = try encoder.encode(collaborators)
            try collaboratorsData.write(to: collaboratorsFileURL)
            print("Saved collaborators to \(collaboratorsFileURL.path)")
            
        } catch {
            print("Error saving data: \(error)")
        }
    }
    
    private func loadData() {
        let decoder = JSONDecoder()
        
        // Load Artists
        if fileManager.fileExists(atPath: artistsFileURL.path) {
            do {
                let data = try Data(contentsOf: artistsFileURL)
                artists = try decoder.decode([Artist].self, from: data)
                print("Loaded artists from \(artistsFileURL.path)")
            } catch {
                print("Error loading artists: \(error)")
            }
        }
        
        // Load All Songs
        if fileManager.fileExists(atPath: songsFileURL.path) {
            do {
                let data = try Data(contentsOf: songsFileURL)
                allSongs = try decoder.decode([Song].self, from: data)
                print("Loaded all songs from \(songsFileURL.path)")
            } catch {
                print("Error loading songs: \(error)")
            }
        }
        
        // Load All Playlists
        if fileManager.fileExists(atPath: playlistsFileURL.path) {
            do {
                let data = try Data(contentsOf: playlistsFileURL)
                allPlaylists = try decoder.decode([Playlist].self, from: data)
                print("Loaded all playlists from \(playlistsFileURL.path)")
            } catch {
                print("Error loading playlists: \(error)")
            }
        }
        
        // Load Collaborators
        if fileManager.fileExists(atPath: collaboratorsFileURL.path) {
            do {
                let data = try Data(contentsOf: collaboratorsFileURL)
                collaborators = try decoder.decode([Collaborator].self, from: data)
                print("Loaded collaborators from \(collaboratorsFileURL.path)")
            } catch {
                print("Error loading collaborators: \(error)")
            }
        }
        
        // Ensure songs and playlists within artists are consistent with central collections
        // This might be needed if artists, songs, and playlists can be manipulated independently.
        // A more robust data model might avoid this complexity.
        // For now, let's just rely on the central collections being the source of truth.
         
         // Removed populateCentralCollections() call
    }
    
    // Removed populateCentralCollections()
    
    // MARK: - Artist Management
    func addArtist(_ artist: Artist) {
        artists.append(artist)
        save()
    }
    
    func updateArtist(_ artist: Artist) {
        if let index = artists.firstIndex(where: { $0.id == artist.id }) {
            artists[index] = artist
        }
        // Update songs and playlists within the updated artist in central collections
        allSongs.removeAll { $0.artistID == artist.id }
        allSongs.append(contentsOf: artist.songs)
        allPlaylists.removeAll { $0.artistID == artist.id }
        allPlaylists.append(contentsOf: artist.playlists)
        save()
    }
    
    func deleteArtist(_ artist: Artist) {
        // Remove artist
        artists.removeAll { $0.id == artist.id }
        
        // Remove associated songs and playlists from central collections
        allSongs.removeAll { $0.artistID == artist.id }
        allPlaylists.removeAll { $0.artistID == artist.id }
        save()
    }
    
    // MARK: - Song Management
    func addSong(_ song: Song, to artist: Artist? = nil) {
        print("Attempting to add song: \(song.title) with audioURL: \(song.audioURL.absoluteString)")
        // Add to central collection if not already present
        if !allSongs.contains(where: { $0.id == song.id }) {
             allSongs.append(song)
             print("Added song \(song.title) to allSongs array. allSongs count: \(allSongs.count)")
        }
       
        // Add to artist's collection if artist is provided
        if let artist = artist, let index = artists.firstIndex(where: { $0.id == artist.id }) {
            // Prevent adding duplicate songs to an artist
            if !artists[index].songs.contains(where: { $0.id == song.id }) {
                 artists[index].songs.append(song)
                 // Ensure the song's artistID is set
                 artists[index].songs[artists[index].songs.count - 1].artistID = artist.id
                 print("Added song \(song.title) to artist \(artist.name)'s songs array.")
            }
        }
        save()
        print("Save function called after adding song \(song.title).")
    }
    
    func updateSong(_ song: Song) {
        // Update in central collection
        if let index = allSongs.firstIndex(where: { $0.id == song.id }) {
            allSongs[index] = song
        }
        
        // Update in artist's collection if associated with an artist
        if let artistID = song.artistID, let artistIndex = artists.firstIndex(where: { $0.id == artistID }) {
             if let songIndex = artists[artistIndex].songs.firstIndex(where: { $0.id == song.id }) {
                artists[artistIndex].songs[songIndex] = song
            }
        }
        save()
    }
    
    func deleteSong(_ song: Song, from artist: Artist? = nil) {
        // Remove from central collection
        allSongs.removeAll { $0.id == song.id }
        
        // Remove from artist's collection if associated with an artist or if artist is provided
        if let artist = artist, let index = artists.firstIndex(where: { $0.id == artist.id }) {
             artists[index].songs.removeAll { $0.id == song.id }
        } else if let artistID = song.artistID, let artistIndex = artists.firstIndex(where: { $0.id == artistID }) {
             artists[artistIndex].songs.removeAll { $0.id == song.id }
        }

        save()
    }
    
    // MARK: - Playlist Management
    func addPlaylist(_ playlist: Playlist, to artist: Artist? = nil) {
        // Add to central collection if not already present
         if !allPlaylists.contains(where: { $0.id == playlist.id }) {
             allPlaylists.append(playlist)
         }
        
        // Add to artist's collection if artist is provided
        if let artist = artist, let index = artists.firstIndex(where: { $0.id == artist.id }) {
             // Prevent adding duplicate playlists to an artist
            if !artists[index].playlists.contains(where: { $0.id == playlist.id }) {
                artists[index].playlists.append(playlist)
                 // Ensure the playlist's artistID is set
                 artists[index].playlists[artists[index].playlists.count - 1].artistID = artist.id
            }
        }
        save()
    }
    
     func updatePlaylist(_ playlist: Playlist) {
        // Update in central collection
        if let index = allPlaylists.firstIndex(where: { $0.id == playlist.id }) {
            allPlaylists[index] = playlist
        }
        
        // Update in artist's collection if associated with an artist
        if let artistID = playlist.artistID, let artistIndex = artists.firstIndex(where: { $0.id == artistID }) {
             if let playlistIndex = artists[artistIndex].playlists.firstIndex(where: { $0.id == playlist.id }) {
                artists[artistIndex].playlists[playlistIndex] = playlist
            }
        }
        save()
    }
    
    func deletePlaylist(_ playlist: Playlist, from artist: Artist? = nil) {
         // Remove from central collection
        allPlaylists.removeAll { $0.id == playlist.id }
        
        // Remove from artist's collection if associated with an artist or if artist is provided
        if let artist = artist, let index = artists.firstIndex(where: { $0.id == artist.id }) {
             artists[index].playlists.removeAll { $0.id == playlist.id }
        } else if let artistID = playlist.artistID, let artistIndex = artists.firstIndex(where: { $0.id == artistID }) {
             artists[artistIndex].playlists.removeAll { $0.id == playlist.id }
        }

        save()
    }
    
    // MARK: - iCloud Sync
    func syncWithICloud() async {
        isLoading = true
        do {
        // TODO: Implement iCloud sync
        }
        isLoading = false
    }
} 