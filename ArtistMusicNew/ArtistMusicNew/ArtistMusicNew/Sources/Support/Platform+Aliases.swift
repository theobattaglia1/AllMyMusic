//  Platform+Aliases.swift
//  ArtistMusicNew
//
//  Cross-platform typealiases, Image init, PNG helper & appBackground color.

import SwiftUI

// ─── cross-platform aliases ─────────────────────────────────────────
#if canImport(UIKit)
import UIKit
public typealias UXImage = UIImage
public typealias UXColor = UIColor
#else
import AppKit
public typealias UXImage = NSImage
public typealias UXColor = NSColor
#endif

// ─── Image(uxImage:) initializer ────────────────────────────────────
extension Image {
    /// Create from a UXImage on both platforms.
    init(uxImage: UXImage) {
        #if canImport(UIKit)
        self.init(uiImage: uxImage)
        #else
        self.init(nsImage: uxImage)
        #endif
    }
}

// ─── pngDataCompat() helper ─────────────────────────────────────────
extension UXImage {
    /// Returns PNG data on both iOS and macOS.
    func pngDataCompat() -> Data? {
        #if canImport(UIKit)
        return self.pngData()
        #else
        guard
            let tiff = tiffRepresentation,
            let rep  = NSBitmapImageRep(data: tiff)
        else { return nil }
        return rep.representation(using: .png, properties: [:])
        #endif
    }
}

// ─── cross-platform “app background” color ──────────────────────────
extension Color {
    /// Use as `.background(.appBackground)` everywhere.
    static var appBackground: Color {
        #if canImport(UIKit)
        return Color(UXColor.systemBackground)
        #else
        return Color(UXColor.windowBackgroundColor)
        #endif
    }
}
