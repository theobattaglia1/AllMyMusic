import SwiftUI

struct EditArtistView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: EnhancedArtistStore

    let artist: Artist
    @State private var name: String
    @State private var artworkImage: UXImage?
    @State private var artworkURL: URL?

    init(artist: Artist) {
        self.artist = artist
        _name       = State(initialValue: artist.name)
        _artworkURL = State(initialValue: artist.artworkURL)
        if let url = artist.artworkURL,
           let data = try? Data(contentsOf: url),
           let img  = UXImage(data: data) {
            _artworkImage = State(initialValue: img)
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Name") {
                    TextField("Artist Name", text: $name)
                }

                Section("Artwork") {
                    ArtworkPicker(image: $artworkImage) { _ in
                        // Optionally do validation or cropping here
                    }
                }
            }
            .navigationTitle("Edit Artist")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: { dismiss() })
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: saveAndDismiss)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func saveAndDismiss() {
        print("SAVE tapped")
        if let img = artworkImage {
            do {
                let saved = try saveArtworkImageSync(img)
                print("[DEBUG] Saved artwork to", saved)
                artworkURL = saved
            } catch {
                print("[ERROR] couldn’t save artwork:", error)
            }
        }

        var updated = artist
        updated.name       = name
        updated.artworkURL = artworkURL
        store.updateArtist(updated)
        dismiss()
    }

    private func saveArtworkImageSync(_ image: UXImage) throws -> URL {
        let fm     = FileManager.default
        let docs   = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = docs.appendingPathComponent("ArtistArtworks", isDirectory: true)
        try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        let filename = "ArtistArtwork_\(artist.id.uuidString).png"
        let fileURL  = folder.appendingPathComponent(filename)
        guard let data = image.pngDataCompat() else {
            throw NSError(domain: "EditArtistView", code: -1, userInfo: nil)
        }
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }
}
