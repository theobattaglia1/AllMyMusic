import SwiftUI
import UniformTypeIdentifiers

struct EditSongView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var store: EnhancedArtistStore
    
    @State private var song: Song // Editable copy
    
    init(song: Song) {
        _song = State(initialValue: song) // Initialize State with the passed song
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Song Details") {
                    TextField("Title", text: $song.title)
                    TextField("Version", text: $song.version, prompt: Text("e.g., feat. Artist"))
                    TextField("Artwork URL", text: $song.artworkURL.getBinding(defaultValue: ""), prompt: Text("Optional URL"))
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
                
                // We might add file pickers for audio/artwork later
                // Section("Audio File") {
                //    Text("Current File: \(song.audioURL.lastPathComponent)")
                //    Button("Change Audio File...") {
                         // Implement file picker
                //    }
                // }
            }
            .navigationTitle("Edit Song")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.updateSong(song)
                        dismiss()
                    }
                    .disabled(song.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// Helper extension to get a Binding<String> from an optional URL
extension Optional where Wrapped == URL {
    func getBinding(defaultValue: String) -> Binding<String> {
        Binding<String>(
            get: { self?.absoluteString ?? defaultValue },
            set: { newValue in
                if newValue.isEmpty {
                    self = nil
                } else {
                    // Basic URL validation
                    if let url = URL(string: newValue), url.scheme != nil {
                        self = url
                    } else {
                        // Handle invalid URL? Maybe show an alert. For now, just don't update.
                        print("Invalid URL entered: \(newValue)")
                    }
                }
            }
        )
    }
}

// MARK: - Previews
struct EditSongView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a dummy song for the preview
        let dummySong = Song(
            id: UUID(),
            title: "Sample Song",
            version: "feat. Preview Artist",
            artworkURL: URL(string: "https://example.com/artwork.png"),
            audioURL: URL(string: "file:///path/to/sample.mp3")!,
            duration: 240,
            artistID: UUID() // Assign to a dummy artist if needed for context
        )
        
        return EditSongView(song: dummySong)
            .environmentObject(EnhancedArtistStore()) // Provide a dummy store for preview
    }
} 