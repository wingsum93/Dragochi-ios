import AppKit
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Deterministic portrait-style avatar generator for Assets.xcassets/person.
// Goal: match the semi-realistic illustrated teammate portraits in the provided UI screenshot.

struct RGBA {
    let r: CGFloat
    let g: CGFloat
    let b: CGFloat
    let a: CGFloat

    var cg: CGColor { CGColor(red: r, green: g, blue: b, alpha: a) }
    var ns: NSColor { NSColor(calibratedRed: r, green: g, blue: b, alpha: a) }
}

func hex(_ value: UInt32, alpha: CGFloat = 1.0) -> RGBA {
    let r = CGFloat((value >> 16) & 0xFF) / 255
    let g = CGFloat((value >> 8) & 0xFF) / 255
    let b = CGFloat(value & 0xFF) / 255
    return RGBA(r: r, g: g, b: b, a: alpha)
}

enum GenderKind {
    case male
    case female
}

enum HairStyle {
    // Male-leaning
    case buzz
    case shortPart
    case quiff
    case curlyTop
    case undercut

    // Female-leaning
    case bob
    case longStraight
    case longWavy
    case ponytail
}

enum FacialHair {
    case none
    case stubble
    case beard
}

struct AvatarSpec {
    let name: String // M1..M10, F1..F5
    let kind: GenderKind
    let skin: RGBA
    let hair: RGBA
    let eyes: RGBA
    let shirt: RGBA
    let hairStyle: HairStyle
    let facialHair: FacialHair
    let seed: UInt32
}

// MARK: - Deterministic RNG for subtle grain

struct XorShift32 {
    private var state: UInt32

    init(seed: UInt32) {
        self.state = seed == 0 ? 0xA3C59AC3 : seed
    }

    mutating func next() -> UInt32 {
        var x = state
        x ^= x << 13
        x ^= x >> 17
        x ^= x << 5
        state = x
        return x
    }

    mutating func nextUnit() -> CGFloat {
        let v = next()
        return CGFloat(Double(v) / Double(UInt32.max))
    }
}

// MARK: - PNG writer

func writePNG(_ image: CGImage, to url: URL) throws {
    guard let dst = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        throw NSError(domain: "avatar-gen", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create PNG destination"])
    }
    CGImageDestinationAddImage(dst, image, nil)
    if !CGImageDestinationFinalize(dst) {
        throw NSError(domain: "avatar-gen", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to finalize PNG"])
    }
}

// MARK: - Drawing helpers

func makeRadialGradient(colors: [CGColor], locations: [CGFloat]) -> CGGradient {
    CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: locations)!
}

func makeLinearGradient(colors: [CGColor], locations: [CGFloat]) -> CGGradient {
    CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: locations)!
}

func drawNoise(in ctx: CGContext, rect: CGRect, seed: UInt32, intensity: CGFloat) {
    guard intensity > 0 else { return }
    var rng = XorShift32(seed: seed)
    // Coarse grain for speed: sample a small grid and upscale via alpha rectangles.
    let step = max(2, Int(rect.width / 32))
    for y in stride(from: Int(rect.minY), to: Int(rect.maxY), by: step) {
        for x in stride(from: Int(rect.minX), to: Int(rect.maxX), by: step) {
            let n = (rng.nextUnit() - 0.5) * 2 // [-1, 1]
            let a = max(0, min(intensity, abs(n) * intensity))
            ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: a * 0.15))
            ctx.fill(CGRect(x: CGFloat(x), y: CGFloat(y), width: CGFloat(step), height: CGFloat(step)))
        }
    }
}

func ovalPath(in rect: CGRect) -> CGPath {
    CGPath(ellipseIn: rect, transform: nil)
}

func roundedRectPath(in rect: CGRect, radius: CGFloat) -> CGPath {
    CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

// MARK: - Portrait pieces

func hairPath(style: HairStyle, headRect: CGRect, canvas: CGFloat) -> CGPath {
    let s = canvas
    let cx = headRect.midX
    let top = headRect.minY
    let left = headRect.minX
    let right = headRect.maxX
    let bottom = headRect.maxY

    let path = CGMutablePath()

    switch style {
    case .buzz:
        // Tight cap.
        let r = headRect.width * 0.52
        path.addEllipse(in: CGRect(x: cx - r * 0.95, y: top - r * 0.10, width: r * 1.9, height: r * 1.2))

    case .shortPart:
        path.move(to: CGPoint(x: left - s * 0.01, y: bottom - s * 0.10))
        path.addCurve(to: CGPoint(x: right + s * 0.02, y: bottom - s * 0.12),
                      control1: CGPoint(x: left + s * 0.03, y: top - s * 0.04),
                      control2: CGPoint(x: right - s * 0.06, y: top - s * 0.06))
        path.addCurve(to: CGPoint(x: left - s * 0.01, y: bottom - s * 0.10),
                      control1: CGPoint(x: right + s * 0.04, y: bottom - s * 0.02),
                      control2: CGPoint(x: left + s * 0.10, y: bottom + s * 0.01))
        path.closeSubpath()

    case .quiff:
        path.move(to: CGPoint(x: left - s * 0.02, y: bottom - s * 0.12))
        path.addCurve(to: CGPoint(x: cx, y: top - s * 0.05),
                      control1: CGPoint(x: left + s * 0.02, y: top - s * 0.05),
                      control2: CGPoint(x: cx - s * 0.05, y: top - s * 0.10))
        path.addCurve(to: CGPoint(x: right + s * 0.03, y: bottom - s * 0.10),
                      control1: CGPoint(x: cx + s * 0.12, y: top - s * 0.03),
                      control2: CGPoint(x: right - s * 0.02, y: top - s * 0.02))
        path.addCurve(to: CGPoint(x: left - s * 0.02, y: bottom - s * 0.12),
                      control1: CGPoint(x: right + s * 0.05, y: bottom + s * 0.02),
                      control2: CGPoint(x: left + s * 0.12, y: bottom + s * 0.03))
        path.closeSubpath()

    case .curlyTop:
        // A scalloped top.
        let baseY = bottom - s * 0.12
        path.move(to: CGPoint(x: left - s * 0.01, y: baseY))
        let bumps = 5
        for i in 0..<bumps {
            let t0 = CGFloat(i) / CGFloat(bumps)
            let t1 = CGFloat(i + 1) / CGFloat(bumps)
            let x0 = left + (right - left) * t0
            let x1 = left + (right - left) * t1
            let mid = (x0 + x1) / 2
            path.addQuadCurve(to: CGPoint(x: x1, y: baseY),
                              control: CGPoint(x: mid, y: top - s * 0.06 - (CGFloat(i % 2) * s * 0.01)))
        }
        path.addCurve(to: CGPoint(x: left - s * 0.01, y: baseY),
                      control1: CGPoint(x: right + s * 0.05, y: bottom - s * 0.02),
                      control2: CGPoint(x: left + s * 0.10, y: bottom + s * 0.02))
        path.closeSubpath()

    case .undercut:
        // High top with tighter sides.
        let topY = top - s * 0.04
        path.move(to: CGPoint(x: left + s * 0.03, y: bottom - s * 0.12))
        path.addCurve(to: CGPoint(x: right - s * 0.03, y: bottom - s * 0.12),
                      control1: CGPoint(x: left + s * 0.02, y: topY),
                      control2: CGPoint(x: right - s * 0.02, y: topY))
        path.addCurve(to: CGPoint(x: left + s * 0.03, y: bottom - s * 0.12),
                      control1: CGPoint(x: right + s * 0.02, y: bottom - s * 0.04),
                      control2: CGPoint(x: left - s * 0.02, y: bottom - s * 0.04))
        path.closeSubpath()

    case .bob:
        // Rounded bob framing cheeks.
        let hairRect = headRect.insetBy(dx: -s * 0.03, dy: -s * 0.01).offsetBy(dx: 0, dy: s * 0.02)
        path.addRoundedRect(in: hairRect, cornerWidth: hairRect.width * 0.45, cornerHeight: hairRect.width * 0.45)

    case .longStraight:
        let hairRect = CGRect(x: left - s * 0.07, y: top - s * 0.02, width: headRect.width + s * 0.14, height: headRect.height + s * 0.20)
        path.addRoundedRect(in: hairRect, cornerWidth: hairRect.width * 0.40, cornerHeight: hairRect.width * 0.40)

    case .longWavy:
        // Long hair with slight waves.
        let baseTop = top - s * 0.02
        let baseBottom = bottom + s * 0.20
        path.move(to: CGPoint(x: left - s * 0.08, y: bottom - s * 0.08))
        path.addCurve(to: CGPoint(x: left - s * 0.06, y: baseBottom),
                      control1: CGPoint(x: left - s * 0.14, y: bottom + s * 0.06),
                      control2: CGPoint(x: left - s * 0.10, y: baseBottom - s * 0.06))
        path.addCurve(to: CGPoint(x: right + s * 0.06, y: baseBottom),
                      control1: CGPoint(x: cx - s * 0.10, y: baseBottom + s * 0.06),
                      control2: CGPoint(x: cx + s * 0.10, y: baseBottom + s * 0.06))
        path.addCurve(to: CGPoint(x: right + s * 0.08, y: bottom - s * 0.08),
                      control1: CGPoint(x: right + s * 0.10, y: baseBottom - s * 0.06),
                      control2: CGPoint(x: right + s * 0.14, y: bottom + s * 0.06))
        path.addCurve(to: CGPoint(x: cx, y: baseTop),
                      control1: CGPoint(x: right + s * 0.02, y: top - s * 0.06),
                      control2: CGPoint(x: cx + s * 0.14, y: top - s * 0.08))
        path.addCurve(to: CGPoint(x: left - s * 0.08, y: bottom - s * 0.08),
                      control1: CGPoint(x: cx - s * 0.16, y: top - s * 0.08),
                      control2: CGPoint(x: left - s * 0.02, y: top - s * 0.06))
        path.closeSubpath()

    case .ponytail:
        let mainRect = CGRect(x: left - s * 0.06, y: top - s * 0.02, width: headRect.width + s * 0.12, height: headRect.height + s * 0.16)
        path.addRoundedRect(in: mainRect, cornerWidth: mainRect.width * 0.42, cornerHeight: mainRect.width * 0.42)
        // Pony tail blob
        let tailR = s * 0.085
        let tailCenter = CGPoint(x: right + s * 0.10, y: bottom + s * 0.03)
        path.addEllipse(in: CGRect(x: tailCenter.x - tailR, y: tailCenter.y - tailR, width: tailR * 2, height: tailR * 2))
    }

    return path
}

func drawPortrait(spec: AvatarSpec, size: Int) throws -> CGImage {
    let s = CGFloat(size)
    guard let ctx = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        throw NSError(domain: "avatar-gen", code: 10, userInfo: [NSLocalizedDescriptionKey: "Failed to create CGContext"])
    }

    ctx.setAllowsAntialiasing(true)
    ctx.setShouldAntialias(true)
    ctx.interpolationQuality = .high

    ctx.clear(CGRect(x: 0, y: 0, width: s, height: s))

    // Use an iOS-like coordinate space for easier layout (origin at top-left).
    ctx.translateBy(x: 0, y: s)
    ctx.scaleBy(x: 1, y: -1)

    // Clip to circle for transparent outside.
    let circleRect = CGRect(x: 0, y: 0, width: s, height: s)
    ctx.saveGState()
    ctx.addEllipse(in: circleRect)
    ctx.clip()

    // Background: neutral light gradient + soft vignette.
    let bgTop = hex(0xF4F2EE).cg
    let bgMid = hex(0xECE9E3).cg
    let bgBottom = hex(0xDDE2E6).cg
    let bgGrad = makeLinearGradient(colors: [bgTop, bgMid, bgBottom], locations: [0, 0.55, 1])
    ctx.drawLinearGradient(
        bgGrad,
        start: CGPoint(x: s * 0.18, y: s * 0.92),
        end: CGPoint(x: s * 0.86, y: s * 0.12),
        options: []
    )

    // Vignette
    let vig = makeRadialGradient(
        colors: [
            CGColor(red: 0, green: 0, blue: 0, alpha: 0.0),
            CGColor(red: 0, green: 0, blue: 0, alpha: 0.14)
        ],
        locations: [0.55, 1.0]
    )
    ctx.drawRadialGradient(
        vig,
        startCenter: CGPoint(x: s * 0.46, y: s * 0.62),
        startRadius: s * 0.05,
        endCenter: CGPoint(x: s * 0.50, y: s * 0.54),
        endRadius: s * 0.70,
        options: []
    )

    // Subtle grain to avoid "too vector".
    drawNoise(in: ctx, rect: circleRect, seed: spec.seed &+ UInt32(size), intensity: 0.10)

    // Layout
    let headW = s * 0.46
    let headH = s * 0.52
    let headRect = CGRect(x: s * 0.27, y: s * 0.18, width: headW, height: headH)
    let neckRect = CGRect(x: s * 0.455, y: s * 0.56, width: s * 0.11, height: s * 0.13)
    let shouldersRect = CGRect(x: s * 0.10, y: s * 0.60, width: s * 0.80, height: s * 0.50)

    // Shirt/shoulders
    ctx.saveGState()
    let shirtPath = roundedRectPath(in: shouldersRect, radius: s * 0.18)
    ctx.addPath(shirtPath)
    ctx.clip()
    let shirtTop = RGBA(
        r: min(1, spec.shirt.r + 0.10),
        g: min(1, spec.shirt.g + 0.10),
        b: min(1, spec.shirt.b + 0.10),
        a: 1
    )
    let shirtBottom = RGBA(
        r: max(0, spec.shirt.r - 0.12),
        g: max(0, spec.shirt.g - 0.12),
        b: max(0, spec.shirt.b - 0.12),
        a: 1
    )
    let shirtGrad = makeLinearGradient(colors: [shirtTop.cg, spec.shirt.cg, shirtBottom.cg], locations: [0, 0.55, 1])
    ctx.drawLinearGradient(shirtGrad,
                           start: CGPoint(x: shouldersRect.midX, y: shouldersRect.maxY),
                           end: CGPoint(x: shouldersRect.midX, y: shouldersRect.minY),
                           options: [])
    // Collar shadow
    ctx.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.08))
    ctx.fill(CGRect(x: s * 0.36, y: s * 0.62, width: s * 0.28, height: s * 0.06))
    ctx.restoreGState()

    // Neck
    ctx.saveGState()
    let neckPath = roundedRectPath(in: neckRect, radius: s * 0.04)
    ctx.addPath(neckPath)
    ctx.clip()
    let neckTop = RGBA(r: min(1, spec.skin.r + 0.06), g: min(1, spec.skin.g + 0.06), b: min(1, spec.skin.b + 0.06), a: 1)
    let neckGrad = makeLinearGradient(colors: [neckTop.cg, spec.skin.cg], locations: [0, 1])
    ctx.drawLinearGradient(neckGrad, start: CGPoint(x: neckRect.minX, y: neckRect.maxY), end: CGPoint(x: neckRect.maxX, y: neckRect.minY), options: [])
    ctx.restoreGState()

    // Face
    ctx.saveGState()
    let facePath = ovalPath(in: headRect)
    ctx.addPath(facePath)
    ctx.clip()

    let faceLight = RGBA(r: min(1, spec.skin.r + 0.10), g: min(1, spec.skin.g + 0.08), b: min(1, spec.skin.b + 0.06), a: 1)
    let faceShadow = RGBA(r: max(0, spec.skin.r - 0.10), g: max(0, spec.skin.g - 0.09), b: max(0, spec.skin.b - 0.08), a: 1)
    let faceGrad = makeRadialGradient(colors: [faceLight.cg, spec.skin.cg, faceShadow.cg], locations: [0.0, 0.55, 1.0])
    ctx.drawRadialGradient(
        faceGrad,
        startCenter: CGPoint(x: headRect.minX + headRect.width * 0.35, y: headRect.maxY - headRect.height * 0.35),
        startRadius: s * 0.02,
        endCenter: CGPoint(x: headRect.midX, y: headRect.midY),
        endRadius: headRect.width * 0.75,
        options: []
    )

    // Chin shadow
    ctx.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.10))
    let chin = CGRect(x: headRect.minX + headRect.width * 0.25, y: headRect.minY + headRect.height * 0.02, width: headRect.width * 0.50, height: headRect.height * 0.16)
    ctx.fillEllipse(in: chin)

    ctx.restoreGState()

    // Hair (behind face for long styles)
    let hairBehind = (spec.hairStyle == .longStraight || spec.hairStyle == .longWavy || spec.hairStyle == .ponytail || spec.hairStyle == .bob)
    if hairBehind {
        ctx.saveGState()
        ctx.addPath(hairPath(style: spec.hairStyle, headRect: headRect, canvas: s))
        ctx.setFillColor(spec.hair.cg)
        ctx.setShadow(offset: CGSize(width: 0, height: s * 0.01), blur: s * 0.04, color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.20))
        ctx.fillPath()
        ctx.restoreGState()
    }

    // Features (eyes/brows/mouth)
    let eyeY = headRect.minY + headRect.height * 0.62
    let eyeDX = headRect.width * 0.16
    let eyeW = headRect.width * 0.10
    let eyeH = headRect.height * 0.06
    let leftEye = CGRect(x: headRect.midX - eyeDX - eyeW / 2, y: eyeY, width: eyeW, height: eyeH)
    let rightEye = CGRect(x: headRect.midX + eyeDX - eyeW / 2, y: eyeY, width: eyeW, height: eyeH)

    ctx.saveGState()
    ctx.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.18))
    ctx.fillEllipse(in: leftEye.insetBy(dx: -eyeW * 0.15, dy: -eyeH * 0.30))
    ctx.fillEllipse(in: rightEye.insetBy(dx: -eyeW * 0.15, dy: -eyeH * 0.30))

    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.85))
    ctx.fillEllipse(in: leftEye.insetBy(dx: eyeW * 0.12, dy: eyeH * 0.12))
    ctx.fillEllipse(in: rightEye.insetBy(dx: eyeW * 0.12, dy: eyeH * 0.12))

    ctx.setFillColor(spec.eyes.cg)
    ctx.fillEllipse(in: leftEye.insetBy(dx: eyeW * 0.28, dy: eyeH * 0.20))
    ctx.fillEllipse(in: rightEye.insetBy(dx: eyeW * 0.28, dy: eyeH * 0.20))

    ctx.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.45))
    ctx.fillEllipse(in: leftEye.insetBy(dx: eyeW * 0.42, dy: eyeH * 0.34))
    ctx.fillEllipse(in: rightEye.insetBy(dx: eyeW * 0.42, dy: eyeH * 0.34))

    // Highlights
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.65))
    ctx.fillEllipse(in: CGRect(x: leftEye.minX + eyeW * 0.55, y: leftEye.minY + eyeH * 0.45, width: eyeW * 0.18, height: eyeH * 0.25))
    ctx.fillEllipse(in: CGRect(x: rightEye.minX + eyeW * 0.55, y: rightEye.minY + eyeH * 0.45, width: eyeW * 0.18, height: eyeH * 0.25))

    // Brows
    ctx.setStrokeColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.40))
    ctx.setLineWidth(max(1, floor(s * 0.016)))
    ctx.setLineCap(.round)
    let browY = headRect.minY + headRect.height * 0.70
    ctx.move(to: CGPoint(x: leftEye.midX - eyeW * 0.50, y: browY))
    ctx.addLine(to: CGPoint(x: leftEye.midX + eyeW * 0.50, y: browY + s * 0.006))
    ctx.move(to: CGPoint(x: rightEye.midX - eyeW * 0.50, y: browY + s * 0.006))
    ctx.addLine(to: CGPoint(x: rightEye.midX + eyeW * 0.50, y: browY))
    ctx.strokePath()

    // Mouth
    ctx.setStrokeColor(CGColor(red: 0.35, green: 0.12, blue: 0.12, alpha: 0.55))
    ctx.setLineWidth(max(1, floor(s * 0.014)))
    let mouthY = headRect.minY + headRect.height * 0.36
    ctx.move(to: CGPoint(x: headRect.midX - headRect.width * 0.12, y: mouthY))
    ctx.addQuadCurve(to: CGPoint(x: headRect.midX + headRect.width * 0.12, y: mouthY),
                     control: CGPoint(x: headRect.midX, y: mouthY - s * 0.012))
    ctx.strokePath()

    ctx.restoreGState()

    // Hair (front/top for short styles)
    if !hairBehind {
        ctx.saveGState()
        let hp = hairPath(style: spec.hairStyle, headRect: headRect, canvas: s)
        ctx.addPath(hp)
        ctx.setFillColor(spec.hair.cg)
        ctx.setShadow(offset: CGSize(width: 0, height: s * 0.01), blur: s * 0.03, color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.18))
        ctx.fillPath()

        // Hair highlight band
        ctx.addPath(hp)
        ctx.clip()
        let hl = makeLinearGradient(
            colors: [CGColor(red: 1, green: 1, blue: 1, alpha: 0.18), CGColor(red: 1, green: 1, blue: 1, alpha: 0.0)],
            locations: [0, 1]
        )
        ctx.drawLinearGradient(hl,
                               start: CGPoint(x: headRect.minX, y: headRect.maxY),
                               end: CGPoint(x: headRect.maxX, y: headRect.minY),
                               options: [])
        ctx.restoreGState()
    } else {
        // Part line / hair highlight for long styles
        ctx.saveGState()
        let hp = hairPath(style: spec.hairStyle, headRect: headRect, canvas: s)
        ctx.addPath(hp)
        ctx.clip()
        let hl = makeLinearGradient(
            colors: [CGColor(red: 1, green: 1, blue: 1, alpha: 0.10), CGColor(red: 1, green: 1, blue: 1, alpha: 0.0)],
            locations: [0, 1]
        )
        ctx.drawLinearGradient(hl,
                               start: CGPoint(x: headRect.minX + headRect.width * 0.10, y: headRect.maxY),
                               end: CGPoint(x: headRect.maxX, y: headRect.minY),
                               options: [])
        ctx.restoreGState()
    }

    // Facial hair (subtle)
    if spec.facialHair != .none {
        ctx.saveGState()
        let strength: CGFloat = (spec.facialHair == .beard) ? 0.22 : 0.12
        ctx.setFillColor(CGColor(red: 0.12, green: 0.08, blue: 0.06, alpha: strength))
        let beardRect = CGRect(x: headRect.minX + headRect.width * 0.22, y: headRect.minY + headRect.height * 0.10, width: headRect.width * 0.56, height: headRect.height * 0.26)
        ctx.fillEllipse(in: beardRect)
        drawNoise(in: ctx, rect: beardRect, seed: spec.seed ^ 0xBEEFBEEF, intensity: 0.12)
        ctx.restoreGState()
    }

    // Soft edge darkening (gives depth like portrait renders).
    let edge = makeRadialGradient(
        colors: [CGColor(red: 0, green: 0, blue: 0, alpha: 0.0), CGColor(red: 0, green: 0, blue: 0, alpha: 0.10)],
        locations: [0.70, 1.0]
    )
    ctx.drawRadialGradient(edge, startCenter: CGPoint(x: s * 0.50, y: s * 0.55), startRadius: s * 0.10, endCenter: CGPoint(x: s * 0.50, y: s * 0.50), endRadius: s * 0.60, options: [])

    ctx.restoreGState() // end circle clip

    guard let out = ctx.makeImage() else {
        throw NSError(domain: "avatar-gen", code: 11, userInfo: [NSLocalizedDescriptionKey: "Failed to create CGImage"])
    }
    return out
}

// MARK: - Specs

let specs: [AvatarSpec] = [
    // Male (10)
    .init(name: "M1", kind: .male, skin: hex(0xE9C7A4), hair: hex(0x3B2F2A), eyes: hex(0x2F5D7C), shirt: hex(0x2B7A78), hairStyle: .shortPart, facialHair: .stubble, seed: 0xA11C_0001),
    .init(name: "M2", kind: .male, skin: hex(0xD9B08C), hair: hex(0x2D2A28), eyes: hex(0x3A6A4C), shirt: hex(0x3D5A80), hairStyle: .quiff, facialHair: .none, seed: 0xA11C_0002),
    .init(name: "M3", kind: .male, skin: hex(0xCFA27C), hair: hex(0x6B4F3A), eyes: hex(0x2C4B6A), shirt: hex(0x2E4F4F), hairStyle: .undercut, facialHair: .none, seed: 0xA11C_0003),
    .init(name: "M4", kind: .male, skin: hex(0xB9805A), hair: hex(0x1E1B1A), eyes: hex(0x274C3C), shirt: hex(0x355070), hairStyle: .curlyTop, facialHair: .stubble, seed: 0xA11C_0004),
    .init(name: "M5", kind: .male, skin: hex(0xF0D5BB), hair: hex(0x7A5C44), eyes: hex(0x2B4F73), shirt: hex(0x4F772D), hairStyle: .shortPart, facialHair: .none, seed: 0xA11C_0005),
    .init(name: "M6", kind: .male, skin: hex(0x8D5B3C), hair: hex(0x171615), eyes: hex(0x2F5D7C), shirt: hex(0x2A9D8F), hairStyle: .buzz, facialHair: .beard, seed: 0xA11C_0006),
    .init(name: "M7", kind: .male, skin: hex(0xD8B28C), hair: hex(0xB8895B), eyes: hex(0x3A6A4C), shirt: hex(0x6D597A), hairStyle: .quiff, facialHair: .none, seed: 0xA11C_0007),
    .init(name: "M8", kind: .male, skin: hex(0xBC8A62), hair: hex(0x3A2E2A), eyes: hex(0x2C4B6A), shirt: hex(0x457B9D), hairStyle: .undercut, facialHair: .stubble, seed: 0xA11C_0008),
    .init(name: "M9", kind: .male, skin: hex(0xF2D6C2), hair: hex(0x2A2928), eyes: hex(0x274C3C), shirt: hex(0x264653), hairStyle: .curlyTop, facialHair: .none, seed: 0xA11C_0009),
    .init(name: "M10", kind: .male, skin: hex(0xA86D4C), hair: hex(0x141312), eyes: hex(0x2B4F73), shirt: hex(0x3A86FF), hairStyle: .buzz, facialHair: .beard, seed: 0xA11C_000A),

    // Female (5)
    .init(name: "F1", kind: .female, skin: hex(0xF0D1BB), hair: hex(0x2B2422), eyes: hex(0x2F5D7C), shirt: hex(0x5E548E), hairStyle: .longStraight, facialHair: .none, seed: 0xF11C_0011),
    .init(name: "F2", kind: .female, skin: hex(0xD7B28D), hair: hex(0x5A3B2E), eyes: hex(0x3A6A4C), shirt: hex(0x2A9D8F), hairStyle: .longWavy, facialHair: .none, seed: 0xF11C_0012),
    .init(name: "F3", kind: .female, skin: hex(0xB9825C), hair: hex(0x1F1B1A), eyes: hex(0x2C4B6A), shirt: hex(0xE07A5F), hairStyle: .ponytail, facialHair: .none, seed: 0xF11C_0013),
    .init(name: "F4", kind: .female, skin: hex(0xEAC8A6), hair: hex(0xB8895B), eyes: hex(0x274C3C), shirt: hex(0x3D5A80), hairStyle: .bob, facialHair: .none, seed: 0xF11C_0014),
    .init(name: "F5", kind: .female, skin: hex(0x8D5B3C), hair: hex(0x2A2928), eyes: hex(0x2B4F73), shirt: hex(0x6D597A), hairStyle: .longWavy, facialHair: .none, seed: 0xF11C_0015),
]

func resolveAssetsRoot() -> URL {
    URL(fileURLWithPath: "/Users/ericho/iosHub/Dragochi/Dragochi/Assets.xcassets/person", isDirectory: true)
}

let fm = FileManager.default
let assetsRoot = resolveAssetsRoot()

for spec in specs {
    let setDir = assetsRoot.appendingPathComponent("\(spec.name).imageset", isDirectory: true)
    guard fm.fileExists(atPath: setDir.path) else {
        throw NSError(domain: "avatar-gen", code: 20, userInfo: [NSLocalizedDescriptionKey: "Missing imageset directory: \(setDir.path)"])
    }

    for scale in [1, 2, 3] {
        let size = 64 * scale
        let img = try drawPortrait(spec: spec, size: size)
        let outURL = setDir.appendingPathComponent("\(spec.name)@\(scale)x.png")
        try writePNG(img, to: outURL)
    }
}

print("Generated \(specs.count) portrait avatars (45 PNGs).")
