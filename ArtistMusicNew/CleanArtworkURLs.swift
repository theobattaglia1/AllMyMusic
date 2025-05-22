import Foundation

let docDir = "/Users/theobattaglia/Library/Containers/theo.ArtistMusicNew/Data/Documents/"
let files = ["artists.json", "songs.json", "playlists.json"]

for file in files {
    let path = docDir + file
    guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
        print("Could not read \(file)")
        continue
    }
    guard var jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
        print("Could not parse \(file)")
        continue
    }
    var changed = false
    for i in 0..<jsonArray.count {
        if let artwork = jsonArray[i]["artworkURL"] as? String {
            // Remove file:// prefix if present
            let filePath = artwork.hasPrefix("file://") ? String(artwork.dropFirst("file://".count)) : artwork
            if filePath.isEmpty || !FileManager.default.fileExists(atPath: filePath) {
                jsonArray[i]["artworkURL"] = nil
                changed = true
            } else if artwork.hasPrefix("file://") {
                // Convert to plain path
                jsonArray[i]["artworkURL"] = filePath
                changed = true
            }
        }
    }
    if changed {
        if let newData = try? JSONSerialization.data(withJSONObject: jsonArray, options: [.prettyPrinted]) {
            try? newData.write(to: URL(fileURLWithPath: path))
            print("Cleaned \(file)")
        }
    } else {
        print("No changes needed for \(file)")
    }
} 