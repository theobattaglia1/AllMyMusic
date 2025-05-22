//
//  FileDropHelper.swift
//  ArtistMusicNew
//
//  Created by Theo on 2025-05-22.
//

import Foundation
import UniformTypeIdentifiers

// ---------------------------------------------------------------------------
// MARK: Accepted audio types for drag-&-drop
// ---------------------------------------------------------------------------

/// Every UTI / UTType Finder may expose for a normal audio file.
public let acceptedAudioTypes: [UTType] = [
    .mp3,
    .mpeg4Audio,                              // .m4a
    .wav,
    .aiff,
    UTType("com.apple.protected-mpeg-4-audio")!, // Apple-Music-protected
    .fileURL                                  // fallback – regular files
]

// ---------------------------------------------------------------------------
// MARK:  Copy helper – central place that ALL views call
// ---------------------------------------------------------------------------

/// Copies *source* to **~/Documents/<folderName>** (created if needed)
/// and returns the final URL.  Overwrite = *false* – if the file already
/// exists we tack `_<n>` onto the filename.
@discardableResult
public func copyFile(_ source: URL,
                     into folderName: String = "AudioFiles",
                     overwrite: Bool = false) throws -> URL
{
    let fm   = FileManager.default
    let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let dir  = docs.appendingPathComponent(folderName, isDirectory: true)
    try fm.createDirectory(at: dir, withIntermediateDirectories: true)

    var dest = dir.appendingPathComponent(source.lastPathComponent)

    if !overwrite {
        var counter = 1
        let base = dest.deletingPathExtension().lastPathComponent
        let ext  = dest.pathExtension
        while fm.fileExists(atPath: dest.path) {
            dest = dir.appendingPathComponent("\(base)_\(counter).\(ext)")
            counter += 1
        }
    }

    _ = try? fm.removeItem(at: dest)               // if overwrite=true
    try fm.copyItem(at: source, to: dest)
    return dest
}

/// *Legacy name* kept so older code still compiles.
@discardableResult
public func copyFileToDocuments(_ src: URL,
                                folderName: String = "AudioFiles") throws -> URL
{
    try copyFile(src, into: folderName)
}
