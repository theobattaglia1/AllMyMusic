import SwiftUI
import UniformTypeIdentifiers

struct EditSongView: View {
    let song: Song
    @EnvironmentObject private var store: EnhancedArtistStore
    @Environment(\.dismiss) private var dismiss

    // MARK: — Form State
    @State private var title: String
    @State private var version: String
    @State private var artworkURL: URL?
    @State private var artworkImage: UXImage?
    @State private var album: String
    @State private var composer: String
    @State private var grouping: String
    @State private var genre: String
    @State private var year: String
    @State private var releaseDate: Date?
    @State private var bpm: String
    @State private var isrc: String
    @State private var comments: String
    @State private var selectedArtistID: UUID?
    @State private var songCollaborators: [SongCollaborator]
    @State private var collaboratorSearch: String = ""
    @State private var showAddCollaboratorSheet = false

    // Computed binding for optional DatePicker
    private var releaseDateBinding: Binding<Date> {
        Binding(get: { releaseDate ?? Date() },
                set: { releaseDate = $0 })
    }

    // MARK: — Init
    init(song: Song) {
        self.song = song
        _title             = State(initialValue: song.title)
        _version           = State(initialValue: song.version)
        _artworkURL        = State(initialValue: song.artworkURL)
        _album             = State(initialValue: song.album ?? "")
        _composer          = State(initialValue: song.composer ?? "")
        _grouping          = State(initialValue: song.grouping ?? "")
        _genre             = State(initialValue: song.genre ?? "")
        _year              = State(initialValue: song.year ?? "")
        _releaseDate       = State(initialValue: song.releaseDate)
        // Disambiguate String init for Double → String
        _bpm               = State(initialValue: song.bpm.map { String($0) } ?? "")
        _isrc              = State(initialValue: song.isrc ?? "")
        _comments          = State(initialValue: song.comments ?? "")
        _selectedArtistID  = State(initialValue: song.artistID)
        _songCollaborators = State(initialValue: song.collaborators ?? [])
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── Header ─────────────────────────────
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button("Save") {
                    Task { @MainActor in
                        await saveAndDismiss()
                    }
                }
            }
            .padding()

            Form {
                Section("Artist") {
                    Picker("Artist", selection: $selectedArtistID) {
                        Text("None").tag(UUID?.none)
                        ForEach(store.artists) { artist in
                            Text(artist.name).tag(Optional(artist.id))
                        }
                    }
                }

                collaboratorsSection

                Section(header: Text("Artwork")) {
                    ArtworkPicker(image: $artworkImage) { img in
                        Task { @MainActor in
                            await saveArtworkImageAsync(img)
                        }
                    }
                    if artworkImage != nil {
                        HStack {
                            Button("Remove Artwork") {
                                artworkImage = nil
                                artworkURL = nil
                            }
                        }
                    }
                }

                Section {
                    TextField("Title", text: $title)
                    TextField("Version", text: $version)
                }

                Section("Additional Details") {
                    TextField("Album", text: $album)
                    TextField("Composer", text: $composer)
                    TextField("Grouping", text: $grouping)
                    TextField("Genre", text: $genre)
                    TextField("Year", text: $year)
#if canImport(UIKit)
                        .keyboardType(.numberPad)
#endif
                    DatePicker("Release Date", selection: releaseDateBinding, displayedComponents: .date)
                        .datePickerStyle(.compact)
                    TextField("BPM", text: $bpm)
#if canImport(UIKit)
                        .keyboardType(.decimalPad)
#endif
                    TextField("ISRC", text: $isrc)
#if canImport(UIKit)
                    TextField("Comments", text: $comments, axis: .vertical)
                        .lineLimit(5)
#else
                    TextEditor(text: $comments)
                        .frame(height: 80)
#endif
                }
            }
        }
        .navigationTitle("Edit Song")
#if canImport(UIKit)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }

    // MARK: — Collaborators
    private var collaboratorsSection: some View {
        Section(header: Text("Collaborators")) {
            ForEach(songCollaborators) { songCollab in
                if let collab = store.collaborators.first(where: { $0.id == songCollab.collaboratorID }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(collab.name)
                                .font(.body)
                            TextField("Role", text: Binding(
                                get: { songCollab.role ?? collab.role ?? "" },
                                set: { newRole in
                                    if let idx = songCollaborators.firstIndex(where: { $0.id == songCollab.id }) {
                                        songCollaborators[idx].role = newRole
                                    }
                                }
                            ))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button(role: .destructive) {
                            songCollaborators.removeAll { $0.id == songCollab.id }
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                    }
                }
            }
            HStack {
                TextField("Search or add collaborator", text: $collaboratorSearch)
                Button {
                    showAddCollaboratorSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(collaboratorSearch.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            // You can flesh out search suggestions here...
        }
    }

    // MARK: — Save
    @MainActor
    private func saveAndDismiss() async {
        let savedURL = artworkImage != nil
            ? await saveArtworkImageAsync(artworkImage!)
            : nil
        let updated = Song(
            id: song.id,
            title: title,
            version: version,
            artworkURL: savedURL,
            audioURL: song.audioURL,
            duration: song.duration,
            artistID: selectedArtistID,
            album: album.isEmpty ? nil : album,
            composer: composer.isEmpty ? nil : composer,
            grouping: grouping.isEmpty ? nil : grouping,
            genre: genre.isEmpty ? nil : genre,
            year: year.isEmpty ? nil : year,
            releaseDate: releaseDate,
            bpm: Double(bpm),
            isrc: isrc.isEmpty ? nil : isrc,
            comments: comments.isEmpty ? nil : comments,
            collaborators: songCollaborators.isEmpty ? nil : songCollaborators
        )
        store.updateSong(updated)
        dismiss()
    }

    // MARK: — Save Artwork
    private func saveArtworkImageAsync(_ image: UXImage) async -> URL? {
        let fm = FileManager.default
        let support = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let folder = support.appendingPathComponent("SongArtworks", isDirectory: true)
        try? fm.createDirectory(at: folder, withIntermediateDirectories: true)
        let fileURL = folder.appendingPathComponent(UUID().uuidString + ".png")
        if let data = image.pngDataCompat() {
            do {
                try data.write(to: fileURL)
                await MainActor.run {
                    artworkImage = image
                    artworkURL = fileURL
                }
                return fileURL
            } catch {
                print("[ERROR] Failed saving artwork:", error)
            }
        }
        return nil
    }
}

#if canImport(UIKit)
import UIKit

/// If you still need a UIKit‐based image picker, wrap it here.
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UXImage?
    var onImagePicked: (UXImage) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        picker.mediaTypes = [UTType.image.identifier]
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UXImage {
                parent.image = img
                parent.onImagePicked(img)
            }
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
#endif

// MARK: — Preview
struct EditSongView_Previews: PreviewProvider {
    static var previews: some View {
        let store = EnhancedArtistStore()
        let song = Song(
            id: UUID(),
            title: "Sample Song",
            version: "",
            artworkURL: nil,
            audioURL: URL(string: "file:///dev/null")!,
            duration: 180,
            artistID: nil
        )
        return NavigationStack {
            EditSongView(song: song)
                .environmentObject(store)
        }
    }
}
