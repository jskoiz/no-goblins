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

let frameDir = URL(fileURLWithPath: "frames", isDirectory: true)
let riveFrameDir = URL(fileURLWithPath: "rive_frames", isDirectory: true)
let outDir = URL(fileURLWithPath: "sprites", isDirectory: true)
try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

let frameNames = (0..<24).map { String(format: "frame_%02d.png", $0) }
let frogCrops = frameNames.map { Crop(source: $0, x: 450, y: 500, w: 360, h: 220) }
try makeSheet(crops: frogCrops, sourceDir: frameDir, destination: outDir.appendingPathComponent("frog_sheet.png"), mode: .frogAndTongue)

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

let flyCrops = [
    Crop(source: "frame_00.png", x: 570, y: 140, w: 150, h: 90),
    Crop(source: "frame_05.png", x: 650, y: 120, w: 150, h: 90),
]
try makeSheet(crops: flyCrops, sourceDir: frameDir, destination: outDir.appendingPathComponent("fly_sheet.png"), mode: .fly)

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
try manifest.write(to: outDir.appendingPathComponent("manifest.json"), atomically: true, encoding: .utf8)
print("wrote sprites/frog_sheet.png, sprites/fly_sheet.png, sprites/manifest.json")
