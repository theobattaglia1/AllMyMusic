private func handleDroppedFiles(items: [URL]) {
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
                artistID: artist.id // Associate with the current artist
            )
            store.addSong(newSong, to: artist)
        } else {
            print("Skipping non-audio file: \(fileURL.lastPathComponent)")
        }
    }
} 