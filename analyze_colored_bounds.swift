import CoreGraphics
import Foundation
import ImageIO

struct Box {
    var minX = Int.max
    var minY = Int.max
    var maxX = Int.min
    var maxY = Int.min

    mutating func add(_ x: Int, _ y: Int) {
        minX = min(minX, x)
        minY = min(minY, y)
        maxX = max(maxX, x)
        maxY = max(maxY, y)
    }

    var isEmpty: Bool { minX == Int.max }
    var description: String {
        if isEmpty { return "empty" }
        return "x=\(minX)..\(maxX) y=\(minY)..\(maxY) w=\(maxX - minX + 1) h=\(maxY - minY + 1)"
    }
}

func loadRGBA(_ url: URL) throws -> (pixels: [UInt8], width: Int, height: Int, bytesPerRow: Int) {
    guard
        let source = CGImageSourceCreateWithURL(url as CFURL, nil),
        let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
    else {
        throw NSError(domain: "bounds", code: 1)
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
        throw NSError(domain: "bounds", code: 2)
    }
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    return (pixels, width, height, bytesPerRow)
}

let dir = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "frames", isDirectory: true)
let files = (try FileManager.default.contentsOfDirectory(atPath: dir.path))
    .filter { $0.hasSuffix(".png") && $0.hasPrefix("frame_") && !$0.contains("zoom") }
    .sorted()

for name in files {
    let (pixels, width, height, row) = try loadRGBA(dir.appendingPathComponent(name))
    var green = Box()
    var blue = Box()
    var orange = Box()
    for y in 0..<height {
        for x in 0..<width {
            let i = y * row + x * 4
            let r = Int(pixels[i])
            let g = Int(pixels[i + 1])
            let b = Int(pixels[i + 2])
            if g > 110 && r < 130 && b < 120 {
                green.add(x, y)
            }
            if b > 130 && g > 70 && r < 120 {
                blue.add(x, y)
            }
            if r > 160 && g > 55 && g < 170 && b < 80 {
                orange.add(x, y)
            }
        }
    }
    print("\(name) green \(green.description) blue \(blue.description) orange \(orange.description)")
}
