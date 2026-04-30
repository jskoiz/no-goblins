import AVFoundation
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let args = CommandLine.arguments
guard args.count >= 3 else {
    fputs("usage: extract_frames.swift <input.mp4> <output-dir>\n", stderr)
    exit(2)
}

let inputURL = URL(fileURLWithPath: args[1])
let outputURL = URL(fileURLWithPath: args[2], isDirectory: true)
try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

let asset = AVAsset(url: inputURL)
let duration = CMTimeGetSeconds(asset.duration)
let generator = AVAssetImageGenerator(asset: asset)
generator.appliesPreferredTrackTransform = true
generator.requestedTimeToleranceBefore = .zero
generator.requestedTimeToleranceAfter = .zero

let frameCount = 24
var metadata: [[String: Any]] = []

for index in 0..<frameCount {
    let seconds = duration * Double(index) / Double(frameCount)
    let time = CMTime(seconds: seconds, preferredTimescale: 600)
    do {
        let image = try generator.copyCGImage(at: time, actualTime: nil)
        let name = String(format: "frame_%02d.png", index)
        let destinationURL = outputURL.appendingPathComponent(name)
        guard let destination = CGImageDestinationCreateWithURL(destinationURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            throw NSError(domain: "extract_frames", code: 1)
        }
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)
        metadata.append(["file": name, "seconds": seconds, "width": image.width, "height": image.height])
    } catch {
        fputs("failed at \(seconds): \(error)\n", stderr)
    }
}

let data = try JSONSerialization.data(withJSONObject: ["duration": duration, "frames": metadata], options: [.prettyPrinted, .sortedKeys])
try data.write(to: outputURL.appendingPathComponent("metadata.json"))
