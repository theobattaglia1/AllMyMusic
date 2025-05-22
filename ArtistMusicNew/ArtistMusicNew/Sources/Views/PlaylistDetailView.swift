private func handleDroppedFiles(items: [URL]) {
    guard var currentPlaylist = store.allPlaylists.first(where: { $0.id == playlist.id }) else { return }
    
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
                version: "", // Can't extract version from file name easily
                artworkURL: nil, // Can't extract artwork from file easily
                audioURL: fileURL,
                duration: 0, // Cannot determine duration without AVFoundation
                artistID: nil // No artist associated when dropping into a playlist directly
            )
            
            // Add song to the central collection and the playlist
            store.addSong(newSong)
            currentPlaylist.songs.append(newSong)
            
        } else {
            print("Skipping non-audio file: \(fileURL.lastPathComponent)")
        }
    }
    
    // Update the playlist in the store after adding songs
    store.updatePlaylist(currentPlaylist)
} 