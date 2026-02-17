#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$ROOT_DIR/OpenDisk/Assets.xcassets/AppIcon.appiconset"
mkdir -p "$OUT_DIR"

TMP_SWIFT="$(mktemp /tmp/opendisk-icon-XXXXXX).swift"
cat > "$TMP_SWIFT" <<'SWIFT'
import AppKit
import Foundation

let outputPath = CommandLine.arguments[1]
let outputURL = URL(fileURLWithPath: outputPath)

let sizes: [(String, CGFloat)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024)
]

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let background = NSBezierPath(roundedRect: rect, xRadius: size * 0.22, yRadius: size * 0.22)
    let gradient = NSGradient(colors: [NSColor(calibratedRed: 0.65, green: 0.85, blue: 1.0, alpha: 1), NSColor(calibratedRed: 0.23, green: 0.51, blue: 0.96, alpha: 1)])!
    gradient.draw(in: background, angle: -45)

    let center = NSPoint(x: size * 0.46, y: size * 0.54)

    let diskOuter = NSBezierPath(ovalIn: NSRect(x: center.x - size * 0.22, y: center.y - size * 0.22, width: size * 0.44, height: size * 0.44))
    NSColor.white.withAlphaComponent(0.93).setFill()
    diskOuter.fill()

    let diskMid = NSBezierPath(ovalIn: NSRect(x: center.x - size * 0.13, y: center.y - size * 0.13, width: size * 0.26, height: size * 0.26))
    NSColor(calibratedRed: 0.62, green: 0.80, blue: 0.98, alpha: 0.65).setFill()
    diskMid.fill()

    let diskCore = NSBezierPath(ovalIn: NSRect(x: center.x - size * 0.055, y: center.y - size * 0.055, width: size * 0.11, height: size * 0.11))
    NSColor(calibratedRed: 0.34, green: 0.64, blue: 0.97, alpha: 0.85).setFill()
    diskCore.fill()

    let lensCenter = NSPoint(x: size * 0.67, y: size * 0.36)
    let lensOuter = NSBezierPath(ovalIn: NSRect(x: lensCenter.x - size * 0.14, y: lensCenter.y - size * 0.14, width: size * 0.28, height: size * 0.28))
    NSColor.white.withAlphaComponent(0.9).setFill()
    lensOuter.fill()

    let lensInner = NSBezierPath(ovalIn: NSRect(x: lensCenter.x - size * 0.093, y: lensCenter.y - size * 0.093, width: size * 0.186, height: size * 0.186))
    NSColor(calibratedRed: 0.80, green: 0.93, blue: 1.0, alpha: 1).setFill()
    lensInner.fill()

    let handle = NSBezierPath(roundedRect: NSRect(x: size * 0.71, y: size * 0.17, width: size * 0.2, height: size * 0.06), xRadius: size * 0.03, yRadius: size * 0.03)
    var transform = AffineTransform(rotationByDegrees: 45)
    transform.translate(x: size * 0.07, y: -size * 0.29)
    handle.transform(using: transform)
    NSColor(calibratedRed: 0.06, green: 0.66, blue: 0.91, alpha: 1).setFill()
    handle.fill()

    image.unlockFocus()
    return image
}

for (name, size) in sizes {
    let image = drawIcon(size: size)
    guard
        let tiffData = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiffData),
        let pngData = bitmap.representation(using: .png, properties: [:])
    else {
        continue
    }

    let url = outputURL.appendingPathComponent("\(name).png")
    try pngData.write(to: url)
}
SWIFT

xcrun swift "$TMP_SWIFT" "$OUT_DIR"
rm -f "$TMP_SWIFT"

echo "Generated app icons in $OUT_DIR"
