import Vision
import UIKit

struct OCRResult {
    let fullText: String?
    let contains47: Bool
    let matchCount: Int
}

final class OCRService {
    static let shared = OCRService()

    func detectText(in image: UIImage) async -> OCRResult {
        guard let cgImage = image.cgImage else {
            return OCRResult(fullText: nil, contains47: false, matchCount: 0)
        }

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: OCRResult(fullText: nil, contains47: false, matchCount: 0))
                    return
                }

                let allText = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: " ")

                // Count occurrences of "47" in the text
                var count = 0
                var searchRange = allText.startIndex..<allText.endIndex
                while let range = allText.range(of: "47", range: searchRange) {
                    count += 1
                    searchRange = range.upperBound..<allText.endIndex
                }

                continuation.resume(returning: OCRResult(
                    fullText: allText.isEmpty ? nil : allText,
                    contains47: count > 0,
                    matchCount: count
                ))
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false

            let cgOrientation = CGImagePropertyOrientation(image.imageOrientation)
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: cgOrientation)
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: OCRResult(fullText: nil, contains47: false, matchCount: 0))
            }
        }
    }

    /// Returns Vision-normalized bounding boxes for each "47" found in the image.
    func detectLocations(in image: UIImage) async -> [CGRect] {
        guard let cgImage = image.cgImage else { return [] }

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                var rects: [CGRect] = []
                for observation in observations {
                    guard let candidate = observation.topCandidates(1).first else { continue }
                    let text = candidate.string

                    let charCount = text.count
                    let box = observation.boundingBox
                    var searchRange = text.startIndex..<text.endIndex
                    while let range = text.range(of: "47", range: searchRange) {
                        let startFrac = CGFloat(text.distance(from: text.startIndex, to: range.lowerBound)) / CGFloat(charCount)
                        let endFrac = CGFloat(text.distance(from: text.startIndex, to: range.upperBound)) / CGFloat(charCount)
                        rects.append(CGRect(
                            x: box.origin.x + startFrac * box.width,
                            y: box.origin.y,
                            width: (endFrac - startFrac) * box.width,
                            height: box.height
                        ))
                        searchRange = range.upperBound..<text.endIndex
                    }
                }

                continuation.resume(returning: rects)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false

            let cgOrientation = CGImagePropertyOrientation(image.imageOrientation)
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: cgOrientation)
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: [])
            }
        }
    }
}

extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
