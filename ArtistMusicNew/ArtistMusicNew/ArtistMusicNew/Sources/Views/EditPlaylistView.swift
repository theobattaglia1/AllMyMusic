import SwiftUI
import UniformTypeIdentifiers

struct EditPlaylistView: View {
    let playlist: Playlist
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: EnhancedArtistStore

    // ── State ────────────────────────────────────────────────────────────────
    @State private var name: String
    @State private var artworkURL: URL?
    @State private var artworkImage: UXImage?
    @State private var description: String
    @State private var genre: String
    @State private var showFileImporter = false

    init(playlist: Playlist) {
        self.playlist    = playlist
        _name            = State(initialValue: playlist.name)
        _description     = State(initialValue: playlist.description ?? "")
        _genre           = State(initialValue: playlist.genre ?? "")
        // artworkImage will be loaded in onAppear below
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── Top Bar ───────────────────────────────
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button("Save") {
                    Task { @MainActor in await saveAndDismiss() }
                }
                .disabled(name.isEmpty)
            }
            .padding()

            // ── Form Body ────────────────────────────
            Form {
                Section {
                    TextField("Name", text: $name)
#if canImport(UIKit)
                        .textContentType(.name)
                        .autocapitalization(.words)
#endif
                }

                Section(header: Text("Artwork")) {
                    VStack {
                        if let img = artworkImage {
                            Image(uxImage: img)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: 120, maxHeight: 120)
                                .cornerRadius(8)
                                .padding(.bottom, 4)

                            HStack {
                                Button("Remove Artwork") {
                                    artworkImage = nil
                                    artworkURL   = nil
                                }
                                Spacer()
                                Button("Choose from Files") {
                                    showFileImporter = true
                                }
                            }
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                                    .foregroundColor(Color.gray.opacity(0.5))
                                    .frame(height: 120)

                                Text("Drag & drop image here or choose from Files")
                                    .foregroundColor(.secondary)
                            }
                            .onDrop(of: ["public.image"], isTargeted: nil) { providers in
                                guard let provider = providers.first else { return false }
                                _ = provider.loadObject(ofClass: UXImage.self) { object, _ in
                                    if let dropped = object as? UXImage {
                                        Task { @MainActor in await saveArtworkImageAsync(dropped) }
                                    }
                                }
                                return true
                            }
                            HStack {
                                Spacer()
                                Button("Choose from Files") {
                                    showFileImporter = true
                                }
                                Spacer()
                            }
                        }
                    }
                }

                Section(header: Text("Additional Details")) {
                    // Description + placeholder
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $description)
                            .frame(height: 100)
                            .cornerRadius(5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.gray.opacity(0.2))
                            )

                        if description.isEmpty {
                            Text("Description")
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 8)
                        }
                    }

                    TextField("Genre", text: $genre)
                }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [UTType.image],
                allowsMultipleSelection: false
            ) { result in
                do {
                    let urls = try result.get()
                    if let url = urls.first,
                       let data = try? Data(contentsOf: url),
                       let img  = UXImage(data: data)
                    {
                        Task { @MainActor in await saveArtworkImageAsync(img) }
                    }
                } catch {
                    print("[ERROR] picking image:", error)
                }
            }
        }
        .navigationTitle("Edit Playlist")
#if canImport(UIKit)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .onAppear {
            // Load existing artwork if present
            if let url = playlist.artworkURL,
               FileManager.default.fileExists(atPath: url.path),
               let data = try? Data(contentsOf: url),
               let img  = UXImage(data: data)
            {
                artworkImage = img
                artworkURL   = url
            }
        }
    }

    // ── Save & Persist ────────────────────────────────────────────────────────
    @MainActor
    private func saveAndDismiss() async {
        let savedURL = (artworkImage != nil)
            ? await saveArtworkImageAsync(artworkImage!)
            : nil

        let updated = Playlist(
            id: playlist.id,
            name: name,
            artworkURL: savedURL,
            songs: playlist.songs,
            artistID: playlist.artistID,
            description: description.isEmpty ? nil : description,
            genre: genre.isEmpty       ? nil : genre
        )
        store.updatePlaylist(updated)
        dismiss()
    }

    private func saveArtworkImageAsync(_ image: UXImage) async -> URL? {
        let fm       = FileManager.default
        let support  = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let folder   = support.appendingPathComponent("PlaylistArtworks", isDirectory: true)
        try? fm.createDirectory(at: folder, withIntermediateDirectories: true)
        let fileURL  = folder.appendingPathComponent(UUID().uuidString + ".png")

        if let data = image.pngDataCompat() {
            do {
                try data.write(to: fileURL)
                await MainActor.run {
                    artworkImage = image
                    artworkURL   = fileURL
                }
                return fileURL
            } catch {
                print("[ERROR] saving playlist artwork:", error)
            }
        }
        return nil
    }
}

// ── Preview ─────────────────────────────────────────────────────────────────
struct EditPlaylistView_Previews: PreviewProvider {
    static var previews: some View {
        let store = EnhancedArtistStore()
        let playlist = Playlist(
            id: UUID(),
            name: "Demo Playlist",
            artworkURL: nil,
            songs: [],
            artistID: nil,
            description: "A sample playlist",
            genre: "Jazz"
        )
        return EditPlaylistView(playlist: playlist)
            .environmentObject(store)
    }
}
