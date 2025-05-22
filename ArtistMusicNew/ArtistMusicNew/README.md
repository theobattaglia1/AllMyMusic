# Artist Music New

A modern music player app for managing artists, songs, and playlists.

## Features

- Artist management with songs and playlists
- Global music player with expandable view
- Library view for all songs and playlists
- iCloud sync support
- Background audio playback
- Modern SwiftUI interface

## Requirements

- iOS 16.0+
- Xcode 14.0+
- Swift 5.7+
- Apple Developer Account (for iCloud sync)

## Setup

1. Clone the repository
2. Open `ArtistMusicNew.xcodeproj` in Xcode
3. Sign in with your Apple Developer account
4. Update the following in Xcode:
   - Bundle Identifier (e.g., `com.yourdomain.ArtistMusicNew`)
   - Team (your development team)
   - iCloud Container identifier (in Signing & Capabilities)
5. Build and run the app

## Capabilities

The app requires the following capabilities:

- iCloud (CloudKit)
- Background Modes (Audio)
- App Sandbox
- User Selected File Access
- Network Client
- Media Device Discovery

## Permissions

The app requires the following permissions:

- Microphone access (for audio recording)
- Music library access (for playing music)
- Documents folder access (for file management)

## Architecture

- SwiftUI for the user interface
- MVVM architecture
- CloudKit for iCloud sync
- AVFoundation for audio playback
- FileManager for local storage

## License

This project is licensed under the MIT License - see the LICENSE file for details. 