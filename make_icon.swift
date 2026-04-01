#!/usr/bin/swift
import AppKit
import CoreGraphics

let canvas = 1024
let size = CGSize(width: canvas, height: canvas)

let img = NSImage(size: size, flipped: false) { rect in
    guard let ctx = NSGraphicsContext.current?.cgContext else { return false }

    // ── Background: indigo → blue diagonal gradient ──────────────────────
    let bgColors = [
        CGColor(red: 0.23, green: 0.13, blue: 0.66, alpha: 1),  // #3B1FA8
        CGColor(red: 0.11, green: 0.31, blue: 0.85, alpha: 1)   // #1D4ED8
    ] as CFArray
    let bgSpace = CGColorSpaceCreateDeviceRGB()
    let bgGrad  = CGGradient(colorsSpace: bgSpace, colors: bgColors, locations: [0, 1])!
    ctx.drawLinearGradient(bgGrad,
        start: CGPoint(x: 0, y: canvas),
        end:   CGPoint(x: canvas, y: 0),
        options: [])

    // ── Card shadow ───────────────────────────────────────────────────────
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 48,
                  color: CGColor(red: 0.07, green: 0.05, blue: 0.27, alpha: 0.55))
    let cardRect = CGRect(x: 220, y: 195, width: 584, height: 644)
    let cardPath = CGPath(roundedRect: cardRect, cornerWidth: 56, cornerHeight: 56, transform: nil)
    ctx.addPath(cardPath); ctx.fillPath()
    ctx.restoreGState()

    // ── Card body: white-to-lavender gradient ─────────────────────────────
    let cardColors = [
        CGColor(red: 1.0,  green: 1.0,  blue: 1.0,  alpha: 1),
        CGColor(red: 0.94, green: 0.93, blue: 1.0,  alpha: 1)
    ] as CFArray
    let cardGrad = CGGradient(colorsSpace: bgSpace, colors: cardColors, locations: [0, 1])!
    ctx.saveGState()
    ctx.addPath(cardPath); ctx.clip()
    ctx.drawLinearGradient(cardGrad,
        start: CGPoint(x: 220, y: 839),
        end:   CGPoint(x: 804, y: 195),
        options: [])
    ctx.restoreGState()

    // ── Clip tab: indigo pill at top-center ───────────────────────────────
    let tabRect = CGRect(x: 374, y: 156, width: 276, height: 98)
    let tabPath = CGPath(roundedRect: tabRect, cornerWidth: 34, cornerHeight: 34, transform: nil)
    let tabColors = [
        CGColor(red: 0.39, green: 0.40, blue: 0.95, alpha: 1),  // #6366F1
        CGColor(red: 0.26, green: 0.22, blue: 0.79, alpha: 1)   // #4338CA
    ] as CFArray
    let tabGrad = CGGradient(colorsSpace: bgSpace, colors: tabColors, locations: [0, 1])!
    ctx.saveGState()
    ctx.addPath(tabPath); ctx.clip()
    ctx.drawLinearGradient(tabGrad,
        start: CGPoint(x: 374, y: 254),
        end:   CGPoint(x: 374, y: 156),
        options: [])
    ctx.restoreGState()

    // Hole in clip tab
    let holeRect = CGRect(x: 422, y: 174, width: 180, height: 62)
    let holePath = CGPath(roundedRect: holeRect, cornerWidth: 22, cornerHeight: 22, transform: nil)
    ctx.saveGState()
    ctx.addPath(holePath); ctx.clip()
    ctx.drawLinearGradient(bgGrad,
        start: CGPoint(x: 422, y: 236),
        end:   CGPoint(x: 602, y: 174),
        options: [])
    ctx.restoreGState()

    // ── Horizontal rule below clip ────────────────────────────────────────
    ctx.setFillColor(CGColor(red: 0.78, green: 0.78, blue: 0.95, alpha: 0.45))
    ctx.fill(CGRect(x: 220, y: 294, width: 584, height: 1.5))

    // ── Row 1 — selected/highlighted ──────────────────────────────────────
    let row1Bg = CGPath(roundedRect: CGRect(x: 252, y: 314, width: 520, height: 66),
                        cornerWidth: 14, cornerHeight: 14, transform: nil)
    ctx.saveGState()
    ctx.addPath(row1Bg)
    ctx.setFillColor(CGColor(red: 0.39, green: 0.40, blue: 0.95, alpha: 0.12))
    ctx.fillPath()
    ctx.restoreGState()

    // Row 1 content indicator dot
    ctx.saveGState()
    let dotPath = CGPath(ellipseIn: CGRect(x: 280, y: 338, width: 18, height: 18), transform: nil)
    ctx.addPath(dotPath)
    ctx.setFillColor(CGColor(red: 0.39, green: 0.40, blue: 0.95, alpha: 0.55))
    ctx.fillPath()
    ctx.restoreGState()

    // Row 1 lines
    func fillRoundedRect(_ rect: CGRect, radius: CGFloat, color: CGColor) {
        let p = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
        ctx.addPath(p); ctx.setFillColor(color); ctx.fillPath()
    }

    fillRoundedRect(CGRect(x: 314, y: 335, width: 290, height: 13), radius: 6.5,
                    color: CGColor(red: 0.27, green: 0.20, blue: 0.79, alpha: 0.75))
    fillRoundedRect(CGRect(x: 314, y: 355, width: 200, height: 10), radius: 5,
                    color: CGColor(red: 0.39, green: 0.40, blue: 0.95, alpha: 0.40))

    // Enter key badge (top-right of row 1)
    let badgeRect = CGRect(x: 724, y: 334, width: 30, height: 28)
    let badgePath = CGPath(roundedRect: badgeRect, cornerWidth: 7, cornerHeight: 7, transform: nil)
    ctx.saveGState()
    ctx.addPath(badgePath)
    ctx.setFillColor(CGColor(red: 0.39, green: 0.40, blue: 0.95, alpha: 0.22))
    ctx.fillPath()
    ctx.restoreGState()

    // ── Rows 2-5 ─────────────────────────────────────────────────────────
    let rowsData: [(y: CGFloat, w1: CGFloat, w2: CGFloat, alpha: CGFloat)] = [
        (y: 412, w1: 260, w2: 170, alpha: 0.28),
        (y: 466, w1: 310, w2: 210, alpha: 0.22),
        (y: 520, w1: 230, w2: 150, alpha: 0.18),
        (y: 574, w1: 280, w2: 180, alpha: 0.13),
    ]
    let lineColor1 = CGColor(red: 0.27, green: 0.20, blue: 0.79, alpha: 1)
    let lineColor2 = CGColor(red: 0.39, green: 0.40, blue: 0.95, alpha: 1)

    for row in rowsData {
        fillRoundedRect(CGRect(x: 314, y: row.y, width: row.w1, height: 13), radius: 6.5,
                        color: lineColor1.copy(alpha: row.alpha)!)
        fillRoundedRect(CGRect(x: 314, y: row.y + 20, width: row.w2, height: 10), radius: 5,
                        color: lineColor2.copy(alpha: row.alpha * 0.65)!)
    }

    return true
}

// Export at all required macOS sizes
let sizes: [(Int, Int)] = [
    (16, 1), (16, 2), (32, 1), (32, 2),
    (128, 1), (128, 2), (256, 1), (256, 2),
    (512, 1), (512, 2)
]

let outDir = "Clipse/Resources/Assets.xcassets/AppIcon.appiconset"

for (pts, scale) in sizes {
    let px = pts * scale
    let exportSize = CGSize(width: px, height: px)
    let exportImg  = NSImage(size: exportSize, flipped: false) { _ in
        img.draw(in: CGRect(origin: .zero, size: exportSize))
        return true
    }
    guard let tiff   = exportImg.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png    = bitmap.representation(using: .png, properties: [:]) else { continue }

    let scaleStr = scale == 1 ? "" : "@\(scale)x"
    let filename = "AppIcon-\(pts)\(scaleStr).png"
    try! png.write(to: URL(fileURLWithPath: "\(outDir)/\(filename)"))
    print("✓ \(filename) (\(px)×\(px)px)")
}

print("Done.")
