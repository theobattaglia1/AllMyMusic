#!/usr/bin/env bash
# 1) Image(uxImage: …) & Image(uxImage: …) → Image(uxImage:…)
grep -rlE 'Image\((uiImage|nsImage):' . \
  | xargs sed -i '' -E \
      's/Image\((uiImage|nsImage):[[:space:]]*([^)]+)\)/Image(uxImage: \2)/g'

# 2) .pngDataCompat() → .pngDataCompat()
grep -rl '\.pngData\(\)' . \
  | xargs sed -i '' \
      's/\.pngDataCompat()/\.pngDataCompat()/g'

# 3) Add bonus Image(fileURL:) if not already present
ALIASES="ArtistMusicNew/Sources/Support/Platform+Aliases.swift"
if ! grep -q "init?(fileURL: URL)" "$ALIASES"; then
  cat << 'EOF' >> "$ALIASES"

// — bonus initializer: load Image straight from URL on any platform
extension Image {
  init?(fileURL: URL) {
    #if canImport(UIKit)
    guard let ui = UIImage(contentsOfFile: fileURL.path) else { return nil }
    self.init(uiImage: ui)
    #else
    guard let ns = NSImage(contentsOf: fileURL) else { return nil }
    self.init(nsImage: ns)
    #endif
  }
}
EOF
  echo "— appended Image(fileURL:) initializer to $ALIASES"
fi
