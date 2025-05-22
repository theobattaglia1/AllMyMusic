import SwiftUI
import UniformTypeIdentifiers

struct AddPlaylistSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: EnhancedArtistStore

    let artist: Artist
    @State private var name: String = ""
    @State private var coverImage: UXImage?
    @State private var coverURL: URL?

    var body: some View {
        NavigationView {
            Form {
                Section("Name") {
                    TextField("Playlist Name", text: $name)
                }
                Section("Cover Art") {
                    ArtworkPicker(image: $coverImage) { _ in }
                }
            }
            .navigationTitle("New Playlist")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: saveAndDismiss)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func saveAndDismiss() {
        // 1) save cover image if provided
        if let img = coverImage {
            do {
                let saved = try saveCoverImageSync(img)
                coverURL = saved
                print("[DEBUG] Saved playlist cover to", saved)
            } catch {
                print("[ERROR] couldn’t save playlist cover:", error)
            }
        }

        // 2) create playlist with required fields
        let newPlaylist = Playlist(
            id: UUID(),
            name: name,
            artworkURL: coverURL,
            songs: [],
            artistID: artist.id,
            description: nil,
            genre: nil
        )
        store.addPlaylist(newPlaylist, to: artist)

        // 3) dismiss
        dismiss()
    }

    private func saveCoverImageSync(_ image: UXImage) throws -> URL {
        let fm     = FileManager.default
        let docs   = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = docs.appendingPathComponent("PlaylistArtworks", isDirectory: true)
        try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        let filename = "PlaylistCover_\(UUID().uuidString).png"
        let fileURL  = folder.appendingPathComponent(filename)
        guard let data = image.pngDataCompat() else {
            throw NSError(domain: "AddPlaylistSheet", code: -1, userInfo: nil)
        }
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }
}
