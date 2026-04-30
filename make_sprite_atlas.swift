import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct RGBA {
    var r: UInt8
    var g: UInt8
    var b: UInt8
    var a: UInt8
}

struct Crop {
    let source: String
    let x: Int
    let y: Int
    let w: Int
    let h: Int
}

enum MaskMode {
    case frogAndTongue
    case fly
}

func loadRGBA(_ url: URL) throws -> (pixels: [UInt8], width: Int, height: Int, bytesPerRow: Int) {
    guard
        let source = CGImageSourceCreateWithURL(url as CFURL, nil),
        let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
    else {
        throw NSError(domain: "sprites", code: 1)
    }

    let width = image.width
    let height = image.height
    let bytesPerRow = width * 4
    var pixels = [UInt8](repeating: 0, count: bytesPerRow * height)
    guard let context = CGContext(
        data: &pixels,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: bytesPerRow,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        throw NSError(domain: "sprites", code: 2)
    }
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    return (pixels, width, height, bytesPerRow)
}

func alphaFor(_ r: Int, _ g: Int, _ b: Int, mode: MaskMode) -> UInt8 {
    switch mode {
    case .frogAndTongue:
        let isGreen = g > 70 && g > r + 18 && g > b + 22
        let isOrange = r > 150 && g > 45 && g < 180 && b < 95 && r > g + 25
        if isGreen {
            return UInt8(min(255, max(80, (g - max(r, b)) * 5)))
        }
        if isOrange {
            return UInt8(min(255, max(120, (r - b) * 2)))
        }
        return 0
    case .fly:
        let isBlue = b > 85 && b > r + 22 && b >= g + 8
        return isBlue ? UInt8(min(255, max(80, (b - max(r, g) / 2) * 2))) : 0
    }
}

func makeSheet(crops: [Crop], sourceDir: URL, destination: URL, mode: MaskMode) throws {
    guard let first = crops.first else { return }
    let frameW = first.w
    let frameH = first.h
    let sheetW = frameW * crops.count
    let sheetH = frameH
    var output = [UInt8](repeating: 0, count: sheetW * sheetH * 4)

    var cache: [String: (pixels: [UInt8], width: Int, height: Int, bytesPerRow: Int)] = [:]

    for (frameIndex, crop) in crops.enumerated() {
        if cache[crop.source] == nil {
            cache[crop.source] = try loadRGBA(sourceDir.appendingPathComponent(crop.source))
        }
        guard let image = cache[crop.source] else { continue }

        for yy in 0..<crop.h {
            for xx in 0..<crop.w {
                let sx = crop.x + xx
                let sy = crop.y + yy
                guard sx >= 0, sx < image.width, sy >= 0, sy < image.height else { continue }
                let si = sy * image.bytesPerRow + sx * 4
                let r = Int(image.pixels[si])
                let g = Int(image.pixels[si + 1])
                let b = Int(image.pixels[si + 2])
                let a = alphaFor(r, g, b, mode: mode)
                guard a > 0 else { continue }

                let dx = frameIndex * frameW + xx
                let di = (yy * sheetW + dx) * 4
                output[di] = UInt8(r)
                output[di + 1] = UInt8(g)
                output[di + 2] = UInt8(b)
                output[di + 3] = a
            }
        }
    }

    guard let provider = CGDataProvider(data: Data(output) as CFData),
          let cgImage = CGImage(
            width: sheetW,
            height: sheetH,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: sheetW * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
          ),
          let destinationRef = CGImageDestinationCreateWithURL(destination as CFURL, UTType.png.identifier as CFString, 1, nil)
    else {
        throw NSError(domain: "sprites", code: 3)
    }

    CGImageDestinationAddImage(destinationRef, cgImage, nil)
    CGImageDestinationFinalize(destinationRef)
}

func makeSprite(crop: Crop, sourceDir: URL, destination: URL, mode: MaskMode) throws {
    try makeSheet(crops: [crop], sourceDir: sourceDir, destination: destination, mode: mode)
}

func makeFrameSequence(crops: [Crop], sourceDir: URL, destinationDir: URL, mode: MaskMode) throws {
    try FileManager.default.createDirectory(at: destinationDir, withIntermediateDirectories: true)
    for (index, crop) in crops.enumerated() {
        let destination = destinationDir.appendingPathComponent(String(format: "frame_%04d.png", index))
        try makeSprite(crop: crop, sourceDir: sourceDir, destination: destination, mode: mode)
    }
}

func makeGridAtlas(crops: [Crop], sourceDir: URL, destination: URL, columns: Int, mode: MaskMode) throws {
    guard let first = crops.first else { return }
    let frameW = first.w
    let frameH = first.h
    let rows = Int(ceil(Double(crops.count) / Double(columns)))
    let sheetW = frameW * columns
    let sheetH = frameH * rows
    var output = [UInt8](repeating: 0, count: sheetW * sheetH * 4)
    var cache: [String: (pixels: [UInt8], width: Int, height: Int, bytesPerRow: Int)] = [:]

    for (frameIndex, crop) in crops.enumerated() {
        if cache[crop.source] == nil {
            cache[crop.source] = try loadRGBA(sourceDir.appendingPathComponent(crop.source))
        }
        guard let image = cache[crop.source] else { continue }

        let column = frameIndex % columns
        let row = frameIndex / columns

        for yy in 0..<crop.h {
            for xx in 0..<crop.w {
                let sx = crop.x + xx
                let sy = crop.y + yy
                guard sx >= 0, sx < image.width, sy >= 0, sy < image.height else { continue }
                let si = sy * image.bytesPerRow + sx * 4
                let r = Int(image.pixels[si])
                let g = Int(image.pixels[si + 1])
                let b = Int(image.pixels[si + 2])
                let a = alphaFor(r, g, b, mode: mode)
                guard a > 0 else { continue }

                let dx = column * frameW + xx
                let dy = row * frameH + yy
                let di = (dy * sheetW + dx) * 4
                output[di] = UInt8(r)
                output[di + 1] = UInt8(g)
                output[di + 2] = UInt8(b)
                output[di + 3] = a
            }
        }
    }

    guard let provider = CGDataProvider(data: Data(output) as CFData),
          let cgImage = CGImage(
            width: sheetW,
            height: sheetH,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: sheetW * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
          ),
          let destinationRef = CGImageDestinationCreateWithURL(destination as CFURL, UTType.png.identifier as CFString, 1, nil)
    else {
        throw NSError(domain: "sprites", code: 4)
    }

    CGImageDestinationAddImage(destinationRef, cgImage, nil)
    CGImageDestinationFinalize(destinationRef)
}

func writeRGBA(_ pixels: [UInt8], width: Int, height: Int, destination: URL) throws {
    guard let provider = CGDataProvider(data: Data(pixels) as CFData),
          let cgImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
          ),
          let destinationRef = CGImageDestinationCreateWithURL(destination as CFURL, UTType.png.identifier as CFString, 1, nil)
    else {
        throw NSError(domain: "sprites", code: 5)
    }

    CGImageDestinationAddImage(destinationRef, cgImage, nil)
    CGImageDestinationFinalize(destinationRef)
}

func makeOrangeCleanedAtlas(source: URL, destination: URL, frameWidth: Int, frameHeight: Int, columns: Int, framesToClean: ClosedRange<Int>) throws {
    var image = try loadRGBA(source)
    let frames = Set(framesToClean)

    for frame in frames {
        let column = frame % columns
        let row = frame / columns
        let startX = column * frameWidth
        let startY = row * frameHeight

        for y in startY..<(startY + frameHeight) {
            for x in startX..<(startX + frameWidth) {
                guard x >= 0, x < image.width, y >= 0, y < image.height else { continue }
                let index = y * image.bytesPerRow + x * 4
                let r = Int(image.pixels[index])
                let g = Int(image.pixels[index + 1])
                let b = Int(image.pixels[index + 2])
                let a = Int(image.pixels[index + 3])
                let isOrange = a > 8 && r > 135 && g > 35 && g < 195 && b < 115 && r > Int(Double(g) * 1.08) && r > b + 45
                if isOrange {
                    image.pixels[index + 3] = 0
                }
            }
        }
    }

    try writeRGBA(image.pixels, width: image.width, height: image.height, destination: destination)
}

let frameDir = URL(fileURLWithPath: "frames", isDirectory: true)
let riveFrameDir = URL(fileURLWithPath: "rive_frames", isDirectory: true)
let outDir = URL(fileURLWithPath: "sprites", isDirectory: true)
try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

let hasLegacyFrames = FileManager.default.fileExists(atPath: frameDir.path)
if hasLegacyFrames {
    let frameNames = (0..<24).map { String(format: "frame_%02d.png", $0) }
    let frogCrops = frameNames.map { Crop(source: $0, x: 450, y: 500, w: 360, h: 220) }
    try makeSheet(crops: frogCrops, sourceDir: frameDir, destination: outDir.appendingPathComponent("frog_sheet.png"), mode: .frogAndTongue)
}

if FileManager.default.fileExists(atPath: riveFrameDir.path) {
    let riveFrameNames = (try FileManager.default.contentsOfDirectory(atPath: riveFrameDir.path))
        .filter { $0.hasPrefix("frame_") && $0.hasSuffix(".png") }
        .sorted()
    let riveFrogCrops = riveFrameNames.map { Crop(source: $0, x: 120, y: 100, w: 360, h: 360) }
    try makeFrameSequence(
        crops: riveFrogCrops,
        sourceDir: riveFrameDir,
        destinationDir: outDir.appendingPathComponent("rive_frog_frames", isDirectory: true),
        mode: .frogAndTongue
    )
}

let dedupedRiveFrameDir = outDir.appendingPathComponent("rive_frog_frames_deduped", isDirectory: true)
let hasDedupedFrames = FileManager.default.fileExists(atPath: dedupedRiveFrameDir.path)
if hasDedupedFrames {
    let dedupedFrameNames = (try FileManager.default.contentsOfDirectory(atPath: dedupedRiveFrameDir.path))
        .filter { $0.hasPrefix("frame_") && $0.hasSuffix(".png") }
        .sorted()
    let atlasCrops = dedupedFrameNames.map { Crop(source: $0, x: 0, y: 0, w: 360, h: 360) }
    try makeGridAtlas(
        crops: atlasCrops,
        sourceDir: dedupedRiveFrameDir,
        destination: outDir.appendingPathComponent("frog_atlas.png"),
        columns: 20,
        mode: .frogAndTongue
    )
    try makeOrangeCleanedAtlas(
        source: outDir.appendingPathComponent("frog_atlas.png"),
        destination: outDir.appendingPathComponent("frog_atlas_clean.png"),
        frameWidth: 360,
        frameHeight: 360,
        columns: 20,
        framesToClean: 26...115
    )

    let frogManifest = """
    {
      "source": "OpenAI DevDay frog frames derived from froge-loop.riv",
      "image": "sprites/frog_atlas_clean.png",
      "frameWidth": 360,
      "frameHeight": 360,
      "columns": 20,
      "frames": \(dedupedFrameNames.count),
      "scale": 1.18,
      "mouthOffset": { "x": 136, "y": 196 },
      "tongueAnchor": { "x": 136, "y": 242 },
      "tongueAnchors": {
        "left": { "x": 98, "y": 236 },
        "right": { "x": 174, "y": 236 },
        "up": { "x": 136, "y": 202 },
        "down": { "x": 136, "y": 258 }
      },
      "tongueTips": {
        "attackLeft": { "x": 8, "y": 248 },
        "attackRight": { "x": 310, "y": 248 },
        "attackUp": { "x": 136, "y": 34 }
      },
      "eyeGlowAnchors": [
        { "x": 96, "y": 190 },
        { "x": 176, "y": 190 }
      ],
      "animations": {
        "idle": {
          "frames": [23],
          "fps": 6,
          "loop": true,
          "notes": "True resting hold identified from long deduped source holds. No tongue or chew frames."
        },
        "idleBlink": {
          "frames": [20, 21, 22, 23],
          "fps": 10,
          "loop": false
        },
        "attackRight": {
          "frames": [26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54],
          "fps": 30,
          "notes": "Authored right-facing orange glyph tongue from extracted source frames.",
          "loop": false
        },
        "attackLeft": {
          "frames": [55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90],
          "fps": 30,
          "notes": "Authored left-facing orange glyph tongue from extracted source frames.",
          "loop": false
        },
        "attackUp": {
          "frames": [91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115],
          "fps": 30,
          "notes": "Authored upward orange glyph tongue from extracted source frames.",
          "loop": false
        },
        "attackHorizontal": {
          "frames": [24, 24, 25, 25],
          "fps": 18,
          "notes": "Tongue-free fallback anticipation for off-axis dynamic tongue.",
          "loop": false
        },
        "attackVertical": {
          "frames": [91, 91, 92, 92],
          "fps": 18,
          "notes": "Tongue-free fallback anticipation for off-axis dynamic tongue.",
          "loop": false
        },
        "catchChew": {
          "frames": [116, 120, 136, 140, 141, 142, 143, 144, 145, 146, 147, 148, 23],
          "fps": 14,
          "loop": false,
          "notes": "Success chew/swallow follow-through only. Never used as idle."
        },
        "missRecover": {
          "frames": [54, 23],
          "fps": 14,
          "notes": "Quick tongue-free return from strike hold to rest.",
          "loop": false
        }
      }
    }
    """
    try frogManifest.write(to: outDir.appendingPathComponent("frog_manifest.json"), atomically: true, encoding: .utf8)
}

if hasLegacyFrames {
    let flyCrops = [
        Crop(source: "frame_00.png", x: 570, y: 140, w: 150, h: 90),
        Crop(source: "frame_05.png", x: 650, y: 120, w: 150, h: 90),
    ]
    try makeSheet(crops: flyCrops, sourceDir: frameDir, destination: outDir.appendingPathComponent("fly_sheet.png"), mode: .fly)
}

let manifest = """
{
  "source": "OpenAI DevDay frog/fly assets derived from froge-loop.riv",
  "frog": {
    "image": "sprites/frog_sheet.png",
    "frameWidth": 360,
    "frameHeight": 220,
    "frames": 24,
    "crop": { "x": 450, "y": 500, "width": 360, "height": 220 },
    "mouthOffset": { "x": 190, "y": 103 },
    "scale": 0.6,
    "strikeFrames": [5, 13, 21],
    "blinkFrames": [3, 11, 19]
  },
  "frogFrameSequence": {
    "directory": "sprites/rive_frog_frames_deduped",
    "framePattern": "frame_%04d.png",
    "frameWidth": 360,
    "frameHeight": 360,
    "frames": 436,
    "originalFrames": 1328,
    "fps": 60,
    "source": "froge-loop.riv via scripts/export_rive_frames.mjs",
    "frameMap": "sprites/rive_frog_frame_map.json",
    "crop": { "x": 120, "y": 100, "width": 360, "height": 360 }
  },
  "fly": {
    "image": "sprites/fly_sheet.png",
    "frameWidth": 150,
    "frameHeight": 90,
    "frames": 2
  }
}
"""
if hasLegacyFrames {
    try manifest.write(to: outDir.appendingPathComponent("manifest.json"), atomically: true, encoding: .utf8)
    print("wrote sprites/frog_sheet.png, sprites/fly_sheet.png, sprites/manifest.json")
}
if hasDedupedFrames {
    print("wrote sprites/frog_atlas.png, sprites/frog_atlas_clean.png, sprites/frog_manifest.json")
}
