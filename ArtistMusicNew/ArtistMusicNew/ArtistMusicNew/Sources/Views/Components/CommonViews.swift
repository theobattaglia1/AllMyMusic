//
//  CommonViews.swift
//  ArtistMusicNew
//

import SwiftUI

// ─────────────────────────────── Song Row ────────────────────────────────────
struct SongRow: View {
    let song: Song
    @EnvironmentObject private var player: EnhancedAudioPlayer
    @Binding var selectedSongID: UUID?

    private var isPlaying:  Bool { player.currentSong?.id == song.id && player.isPlaying }
    private var isSelected: Bool { selectedSongID == song.id }

    var body: some View {
        Button {                           // whole row is the tap target
            selectedSongID = song.id
        } label: {
            rowContent
        }
        .buttonStyle(.plain)
        .background(isSelected ? Color.accentColor.opacity(0.12) : .clear)
        .contentShape(Rectangle())
        .draggable(song)
        .onTapGesture(count: 2) { player.playSong(song) }
    }

    // ── row layout ───────────────────────────────────────────────────────────
    private var rowContent: some View {
        HStack(spacing: 12) {
            artwork
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.callout)
                    .lineLimit(1)
                    .foregroundStyle(isPlaying ? .blue :
                                     (isSelected ? .accentColor : .primary))

                if !song.version.isEmpty {
                    Text(song.version)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            Button {
                isPlaying ? player.pause() : player.playSong(song)
            } label: {
                Image(systemName: isPlaying ? "pause.circle.fill"
                                            : "play.circle.fill")
                    .font(.title2)
            }
            .buttonStyle(.plain)

            Text(timeString(isPlaying ? player.currentTime : song.duration))
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }

    // artwork thumbnail -------------------------------------------------------
    @ViewBuilder
    private var artwork: some View {
        if let url  = song.artworkURL,
           let data = try? Data(contentsOf: url),
           let img  = UXImage(data: data) {
#if os(macOS)
            Image(nsImage: img)
#else
            Image(uiImage: img)
#endif
       
        } else {
            Color.gray.opacity(0.3)          // ← no resizable/fill here
        }
    }

    private func timeString(_ secs: TimeInterval) -> String {
        String(format: "%d:%02d", Int(secs) / 60, Int(secs) % 60)
    }
}

// ───────────────────────────── Playlist Card ────────────────────────────────
struct PlaylistCard: View {
    let playlist: Playlist

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            cover
                .frame(width: 160, height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name)
                    .font(.subheadline)
                    .lineLimit(1)

                Text("\(playlist.songs.count) songs")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)
        }
    }

    // playlist cover ----------------------------------------------------------
    @ViewBuilder
    private var cover: some View {
        if let url  = playlist.artworkURL,
           let data = try? Data(contentsOf: url),
           let img  = UXImage(data: data) {
#if os(macOS)
            Image(nsImage: img)
#else
            Image(uiImage: img)
#endif

        } else {
            Color.gray.opacity(0.3)
        }
    }
}

// ───────────────────────────── card() helper ────────────────────────────────
private struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
#if os(macOS)
        let bg = Color(UXColor.windowBackgroundColor)
#else
        let bg = Color(UXColor.systemBackground)
#endif
        content
            .padding()
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 4)
    }
}

extension View {
    /// Apply a padded, rounded, shadowed “card” look.
    func card() -> some View { modifier(CardModifier()) }
}
