//
//  OnAudioFileDropShim.swift
//  ArtistMusicNew
//
//  Adds `.onAudioFileDrop { [URL] in }` using the modern
//  SwiftUI `dropDestination(for:action:)` API.
//  macOS 15 / iOS 18 compatible.
//

import SwiftUI
import UniformTypeIdentifiers

public extension View {

    /// Legacy-style drop handler for external audio files.
    @ViewBuilder
    func onAudioFileDrop(_ handler: @escaping ([URL]) -> Void) -> some View {
        self.dropDestination(for: URL.self) { urls, _ in
            handler(urls)            // forward to caller
            return true              // tell the system we accepted it
        }
    }
}
