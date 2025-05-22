import SwiftUI
import UniformTypeIdentifiers

struct ArtistsView: View {
    @EnvironmentObject private var store: EnhancedArtistStore
    @State private var showingAddArtist = false
    @State private var searchText = ""
    @State private var artistToEdit: Artist? = nil
    @State private var showImageDocumentPicker = false
    @State private var imagePickerCompletion: ((UXImage?) -> Void)? = nil
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 20)
                ], spacing: 20) {
                    ForEach(filteredArtists) { artist in
                        NavigationLink(destination: ArtistDetailView(artist: artist)) {
                            ArtistCard(artist: artist)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button {
                                print("[DEBUG] ArtistsView.contextMenu Edit pressed for artist: \(artist.name)")
                                artistToEdit = artist
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                print("[DEBUG] ArtistsView.contextMenu Remove pressed for artist: \(artist.name)")
                                store.deleteArtist(artist)
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding()
            }
            .searchable(text: $searchText, prompt: "Search artists")
            .sheet(isPresented: $showingAddArtist) {
                AddArtistSheet(presentImagePicker: presentImageDocumentPicker)
                    .environmentObject(store)
                    .onAppear {
                        print("[DEBUG] ArtistsView.sheet AddArtistSheet presented")
                    }
            }
            .sheet(item: $artistToEdit) { artist in
                EditArtistView(artist: artist)
                    .environmentObject(store)
                    .onAppear {
                        print("[DEBUG] ArtistsView.sheet EditArtistView presented for artist: \(artist.name)")
                    }
            }
        }
    }
    
    private var filteredArtists: [Artist] {
        if searchText.isEmpty {
            return store.artists
        }
        return store.artists.filter { artist in
            artist.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    func presentImageDocumentPicker(completion: @escaping (UXImage?) -> Void) {
        imagePickerCompletion = completion
        showImageDocumentPicker = true
    }
}

// MARK: - Artist Card
struct ArtistCard: View {
    let artist: Artist
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            artworkImageView(for: artist)
                .frame(width: 160, height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 4)
                .onAppear {
                    print("[DEBUG] ArtistCard.onAppear for artist: \(artist.name)")
                    if let url = artist.artworkURL {
                        debugPrintArtwork(url: url, artist: artist)
                    }
                }
            VStack(alignment: .leading, spacing: 4) {
                Text(artist.name)
                    .font(.subheadline)
                    .lineLimit(1)
                Text("\(artist.songs.count) songs")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)
        }
    }
    
    @ViewBuilder
    private func artworkImageView(for artist: Artist) -> some View {
        if let url = artist.artworkURL {
            if FileManager.default.fileExists(atPath: url.path) {
                if let data = try? Data(contentsOf: url), let image = UXImage(data: data) {
                    Image(uxImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color.gray.opacity(0.3)
                }
            } else {
                Color.gray.opacity(0.3)
            }
        } else {
            Color.gray.opacity(0.3)
        }
    }
    
    private func debugPrintArtwork(url: URL, artist: Artist) {
        print("[DEBUG] ArtistCard.debugPrintArtwork called for artist: \(artist.name), url: \(url.path)")
        if FileManager.default.fileExists(atPath: url.path) {
            print("[DEBUG] ArtistCard: File exists at: \(url.path)")
        } else {
            print("[ERROR] ArtistCard: File does NOT exist at: \(url.path)")
        }
    }
}

// MARK: - Artist Detail View
/*
struct ArtistDetailView: View {
    let artist: Artist
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Artist header
            VStack(spacing: 16) {
                AsyncImage(url: artist.artworkURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 200, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Text(artist.name)
                    .font(.title)
                    .bold()
                
                Text("\(artist.songs.count) songs • \(artist.playlists.count) playlists")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            
            // Tab selector
            Picker("View", selection: $selectedTab) {
                Text("Songs").tag(0)
                Text("Playlists").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Content
            TabView(selection: $selectedTab) {
                // Songs tab
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(artist.songs) { song in
                            SongRow(song: song)
                        }
                    }
                    .padding(.horizontal)
                }
                .tag(0)
                
                // Playlists tab
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 16)
                    ], spacing: 16) {
                        ForEach(artist.playlists) { playlist in
                            PlaylistCard(playlist: playlist)
                        }
                    }
                    .padding()
                }
                .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
 #if canImport(UIKit)
 .navigationBarTitleDisplayMode(.inline)
 #endif    }
}
*/

// MARK: - Add Artist Sheet
struct AddArtistSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: EnhancedArtistStore
    @State private var name = ""
    @State private var artworkImage: UXImage?
    @State private var showImporter = false
    private let artistID = UUID()
    var presentImagePicker: ((@escaping (UXImage?) -> Void) -> Void)
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") {
                    print("[DEBUG] AddArtistSheet Cancel button pressed")
                    dismiss()
                }
                Spacer()
                Button("Add") {
                    if let img = artworkImage {
                        do {
                            _ = try saveArtworkImageSync(img)
                            // Use savedURL as needed
                        } catch {
                            print("[ERROR] couldn't save artwork:", error)
                        }
                    }
                    let artist = Artist(
                        id: artistID,
                        name: name,
                        artworkURL: nil, // Set to savedURL if needed
                        songs: [],
                        playlists: []
                    )
                    store.addArtist(artist)
                    dismiss()
                }
                .disabled(name.isEmpty)
            }
            .padding()
            Form(content: {
                TextField("Name", text: $name)
                ArtworkPicker(image: $artworkImage) { img in
                    // Handle image picked
                }
                HStack {
                    Button("Cancel") { dismiss() }
                    Spacer()
                    Button("Add") {
                        if let img = artworkImage {
                            do {
                                _ = try saveArtworkImageSync(img)
                                // Use savedURL as needed
                            } catch {
                                print("[ERROR] couldn't save artwork:", error)
                            }
                        }
                        let artist = Artist(
                            id: artistID,
                            name: name,
                            artworkURL: nil, // Set to savedURL if needed
                            songs: [],
                            playlists: []
                        )
                        store.addArtist(artist)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            })
        }
        .navigationTitle("Add Artist")
#if canImport(UIKit)
.navigationBarTitleDisplayMode(.inline)
#endif
.fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            do {
                let url  = try result.get().first!
                let data = try Data(contentsOf: url)
                guard let ui = UXImage(data: data) else { return }
                artworkImage = ui
                // Don't assign artworkURL yet – copy on Add
            } catch {
                print("[ERROR] import failed:", error)
            }
        }
    }
    
    private func saveArtworkImageSync(_ image: UXImage) throws -> URL {
        let fm   = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = docs.appendingPathComponent("ArtistArtworks", isDirectory: true)
        try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        let filename = "ArtistArtwork_\(artistID.uuidString).png"
        let fileURL  = folder.appendingPathComponent(filename)
        guard let data = image.pngDataCompat() else {
            throw NSError(domain: "AddArtistSheet", code: -1, userInfo: nil)
        }
        try data.write(to: fileURL, options: .atomic)
        print("[DEBUG] Saved artwork to", fileURL)
        return fileURL
    }
}

// MARK: - Preview Provider
struct ArtistsView_Previews: PreviewProvider {
    static var previews: some View {
        let store = EnhancedArtistStore()
        store.addArtist(Artist(
            id: UUID(),
            name: "Sample Artist",
            artworkURL: nil,
            songs: [],
            playlists: []
        ))
        
        return ArtistsView()
            .environmentObject(store)
    }
} 
