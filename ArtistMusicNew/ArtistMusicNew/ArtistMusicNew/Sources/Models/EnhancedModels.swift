import Foundation
import CoreTransferable

// MARK: - Artist
struct Artist: Identifiable, Codable, Hashable, Equatable {
    let id: UUID
    var name: String
    var artworkURL: URL?
    var songs: [Song]
    var playlists: [Playlist]

    enum CodingKeys: String, CodingKey {
        case id, name, artworkURL, songs, playlists
    }

    public init(id: UUID, name: String, artworkURL: URL?, songs: [Song], playlists: [Playlist]) {
        self.id = id
        self.name = name
        self.artworkURL = artworkURL
        self.songs = songs
        self.playlists = playlists
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        songs = try container.decode([Song].self, forKey: .songs)
        playlists = try container.decode([Playlist].self, forKey: .playlists)
        if let rawPath = try? container.decode(String.self, forKey: .artworkURL), !rawPath.isEmpty {
            let path: String
            if rawPath.hasPrefix("file://") {
                path = String(rawPath.dropFirst("file://".count))
            } else {
                path = rawPath
            }
            if FileManager.default.fileExists(atPath: path) {
                artworkURL = URL(fileURLWithPath: path)
            } else {
                artworkURL = nil
            }
        } else {
            artworkURL = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(songs, forKey: .songs)
        try container.encode(playlists, forKey: .playlists)
        if let path = artworkURL?.path, !path.isEmpty, FileManager.default.fileExists(atPath: path) {
            try container.encode(path, forKey: .artworkURL)
        } else {
            try container.encodeNil(forKey: .artworkURL)
        }
    }
}

// MARK: - Song
struct Song: Identifiable, Codable, Hashable, Equatable, Transferable {
    let id: UUID
    var title: String
    var version: String
    var artworkURL: URL?
    var audioURL: URL
    var duration: TimeInterval
    var artistID: UUID?
    var album: String?
    var composer: String?
    var grouping: String?
    var genre: String?
    var year: String?
    var releaseDate: Date?
    var bpm: Double?
    var isrc: String?
    var comments: String?
    var collaborators: [SongCollaborator]?
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .json)
    }
}

// MARK: - Playlist
struct Playlist: Identifiable, Codable, Hashable, Equatable {
    let id: UUID
    var name: String
    var artworkURL: URL?
    var songs: [Song]
    var artistID: UUID?
    var description: String?
    var genre: String?

    enum CodingKeys: String, CodingKey {
        case id, name, artworkURL, songs, artistID, description, genre
    }

    public init(id: UUID, name: String, artworkURL: URL?, songs: [Song], artistID: UUID?, description: String?, genre: String?) {
        self.id = id
        self.name = name
        self.artworkURL = artworkURL
        self.songs = songs
        self.artistID = artistID
        self.description = description
        self.genre = genre
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        songs = try container.decode([Song].self, forKey: .songs)
        artistID = try container.decodeIfPresent(UUID.self, forKey: .artistID)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        genre = try container.decodeIfPresent(String.self, forKey: .genre)
        if let rawPath = try? container.decode(String.self, forKey: .artworkURL), !rawPath.isEmpty {
            let path: String
            if rawPath.hasPrefix("file://") {
                path = String(rawPath.dropFirst("file://".count))
            } else {
                path = rawPath
            }
            if FileManager.default.fileExists(atPath: path) {
                artworkURL = URL(fileURLWithPath: path)
            } else {
                artworkURL = nil
            }
        } else {
            artworkURL = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(songs, forKey: .songs)
        try container.encodeIfPresent(artistID, forKey: .artistID)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(genre, forKey: .genre)
        if let path = artworkURL?.path, !path.isEmpty, FileManager.default.fileExists(atPath: path) {
            try container.encode(path, forKey: .artworkURL)
        } else {
            try container.encodeNil(forKey: .artworkURL)
        }
    }
}

// MARK: - Collaborator
struct Collaborator: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var role: String?
}

// MARK: - SongCollaborator
struct SongCollaborator: Identifiable, Codable, Hashable {
    let id: UUID // Unique per song-collaborator entry
    var collaboratorID: UUID
    var role: String?
}

// MARK: - PlaybackState
enum PlaybackState {
    case playing
    case paused
    case stopped
}

// MARK: - PlaybackMode
enum PlaybackMode {
    case sequential
    case shuffle
    case repeatAll
    case repeatOne
} 