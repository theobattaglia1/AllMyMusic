//
//  AddSongSheet.swift
//  ArtistMusicNew
//

import SwiftUI
import UniformTypeIdentifiers

struct AddSongSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject      private var store: EnhancedArtistStore

    /// nil ⇒ “All Songs”; non-nil ⇒ only for that artist
    let artist: Artist?

    // ──────────────────────────────────────────────────────────────────────────
    @State private var title   = ""
    @State private var version = ""

    @State private var artworkImage: UXImage?
    @State private var artworkURL:   URL?

    @State private var showImgPicker   = false
    @State private var showAudioPicker = false
    @State private var artError: String?

    // MARK: UI ----------------------------------------------------------------
    var body: some View {
        NavigationStack {
            Form {
                Section("Song Info") {
                    TextField("Title",             text: $title)
                    TextField("Version (feat. …)", text: $version)
                }

                artworkSection
                audioSection
                actionSection
            }
            .navigationTitle("Add Song")
#if os(iOS) || os(tvOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            // --- drag & drop --------------------------------------------------
            .onDrop(of: [.fileURL], isTargeted: nil, perform: handleDrop(providers:))
            // --- pickers ------------------------------------------------------
            .fileImporter(isPresented: $showImgPicker,
                          allowedContentTypes: [.image],
                          onCompletion: handlePickedImage)
            .fileImporter(isPresented: $showAudioPicker,
                          allowedContentTypes: [.audio],
                          onCompletion: handlePickedAudio)
        }
    }

    // MARK: sections ----------------------------------------------------------
    private var artworkSection: some View {
        Section("Artwork") {
            if let img = artworkImage {
                Image(uxImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 120, maxHeight: 120)
                    .cornerRadius(8)
                    .padding(.bottom, 4)

                HStack {
                    Button("Remove Artwork") { artworkImage = nil; artworkURL = nil }
                    Spacer()
                    Button("Choose Artwork…") { showImgPicker = true }
                }
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [6]))
                        .frame(height: 120)
                        .foregroundColor(.gray.opacity(0.5))
                    Text("Drag & drop image here or choose…")
                        .foregroundColor(.secondary)
                }
                Button("Choose Artwork…") { showImgPicker = true }
            }
        }
    }

    private var audioSection: some View {
        Section("Audio File") {
            Button("Choose Audio…") { showAudioPicker = true }
        }
    }

    private var actionSection: some View {
        Section {
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button("Add", action: manualAdd)
                    .disabled(title.isEmpty)
            }
        }
    }

    // MARK: drag handler ------------------------------------------------------
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            // 1️⃣ AUDIO first ─────────────────────────────────────────
            if provider.hasItemConformingToTypeIdentifier(UTType.audio.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier,
                                  options: nil) { item, _ in
                    guard
                        let data = item as? Data,
                        let url  = URL(dataRepresentation: data,
                                       relativeTo: nil)
                    else { return }
                    DispatchQueue.main.async { importAudio(url) }
                }
                return true
            }

            // 2️⃣ IMAGE second ───────────────────────────────────────
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier,
                                  options: nil) { item, _ in
                    guard
                        let data = item as? Data,
                        let url  = URL(dataRepresentation: data,
                                       relativeTo: nil),
                        let imgData = try? Data(contentsOf: url),
                        let img = UXImage(data: imgData)
                    else { return }
                    Task { @MainActor in await saveArtwork(img) }
                }
                return true
            }
        }
        return false
    }

    // MARK: pickers -----------------------------------------------------------
    private func handlePickedAudio(result: Result<URL, Error>) {
        guard case let .success(url) = result else { return }
        importAudio(url)
    }

    private func handlePickedImage(result: Result<URL, Error>) {
        guard
            case let .success(url) = result,
            let data = try? Data(contentsOf: url),
            let img  = UXImage(data: data)
        else { return }
        Task { @MainActor in await saveArtwork(img) }
    }

    // MARK: import helpers ----------------------------------------------------
    private func importAudio(_ src: URL) {
        do {
            let dst = try copyFileToDocuments(
                src,
                folderName: artist != nil ? "ArtistAudio" : "AudioFiles"
            )
            addSong(withAudio: dst)
        } catch {
            print("[ERROR] copying audio:", error)
        }
    }

    @MainActor
    private func saveArtwork(_ img: UXImage) async {
        do {
            artworkURL   = try saveArtworkPNG(img)
            artworkImage = img
        } catch {
            artError = "Failed to save artwork"
            print("[ERROR] saveArtwork:", error)
        }
    }

    private func saveArtworkPNG(_ img: UXImage) throws -> URL {
        let fm   = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir  = docs.appendingPathComponent("SongArtworks", isDirectory: true)
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        let fileURL = dir.appendingPathComponent(UUID().uuidString + ".png")
#if canImport(UIKit)
        guard let data = img.jpegData(compressionQuality: 1.0) else {
            throw NSError(domain: "AddSongSheet", code: -1)
        }
#else
        guard let data = img.pngDataCompat() else {
            throw NSError(domain: "AddSongSheet", code: -1)
        }
#endif
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }

    // MARK: Song creation -----------------------------------------------------
    @MainActor
    private func addSong(withAudio url: URL) {
        let finalTitle = title.isEmpty
            ? url.deletingPathExtension().lastPathComponent
            : title

        let song = Song(
            id: UUID(),
            title: finalTitle,
            version: version,
            artworkURL: artworkURL,
            audioURL: url,
            duration: 0,
            artistID: artist?.id
        )
        store.addSong(song, to: artist)      // persists immediately
        dismiss()                            // close sheet right away
    }

    private func manualAdd() {
        // Only used if user presses *Add* before dropping an audio file.
        // We simply leave the sheet open.
    }
}

// ──────────────────────────────────────────────────────────────────────────────
#Preview {
    let store  = EnhancedArtistStore()
    let artist = Artist(id: UUID(), name: "Preview", artworkURL: nil,
                        songs: [], playlists: [])
    store.addArtist(artist)
    return AddSongSheet(artist: artist).environmentObject(store)
}
