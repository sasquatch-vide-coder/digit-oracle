import Vision
import UIKit

struct OCRResult {
    let fullText: String?
    let contains47: Bool
    let matchCount: Int
    let matchedNumbers: [Int]
    let matchCounts: [String: Int]

    var containsTrackedNumber: Bool {
        !matchedNumbers.isEmpty
    }
}

final class OCRService {
    static let shared = OCRService()

    func detectText(in image: UIImage) async -> OCRResult {
        guard let cgImage = image.cgImage else {
            return OCRResult(fullText: nil, contains47: false, matchCount: 0, matchedNumbers: [], matchCounts: [:])
        }

        let patterns = TrackedNumberService.shared.patterns

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: OCRResult(fullText: nil, contains47: false, matchCount: 0, matchedNumbers: [], matchCounts: [:]))
                    return
                }

                // For each observation, prefer a candidate that contains a tracked pattern
                let allText = observations
                    .compactMap { observation -> String? in
                        let candidates = observation.topCandidates(5)
                        guard !candidates.isEmpty else { return nil }
                        for candidate in candidates {
                            if patterns.contains(where: { candidate.string.contains($0) }) {
                                return candidate.string
                            }
                        }
                        return candidates.first?.string
                    }
                    .joined(separator: " ")

                // Count occurrences of each tracked number
                var perNumberCounts: [String: Int] = [:]
                var matched: [Int] = []

                for pattern in patterns {
                    var count = 0
                    var searchRange = allText.startIndex..<allText.endIndex
                    while let range = allText.range(of: pattern, range: searchRange) {
                        count += 1
                        searchRange = range.upperBound..<allText.endIndex
                    }
                    if count > 0 {
                        perNumberCounts[pattern] = count
                        if let num = Int(pattern) {
                            matched.append(num)
                        }
                    }
                }

                // Legacy: count "47" specifically
                let count47 = perNumberCounts["47"] ?? 0
                let totalCount = perNumberCounts.values.reduce(0, +)

                continuation.resume(returning: OCRResult(
                    fullText: allText.isEmpty ? nil : allText,
                    contains47: count47 > 0,
                    matchCount: totalCount,
                    matchedNumbers: matched,
                    matchCounts: perNumberCounts
                ))
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
            request.customWords = patterns
            request.automaticallyDetectsLanguage = true

            let cgOrientation = CGImagePropertyOrientation(image.imageOrientation)
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: cgOrientation)
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: OCRResult(fullText: nil, contains47: false, matchCount: 0, matchedNumbers: [], matchCounts: [:]))
            }
        }
    }

    /// Returns Vision-normalized bounding boxes for each tracked number found in the image.
    func detectLocations(in image: UIImage) async -> [CGRect] {
        guard let cgImage = image.cgImage else { return [] }

        let patterns = TrackedNumberService.shared.patterns

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                var rects: [CGRect] = []
                for observation in observations {
                    let candidates = observation.topCandidates(5)
                    guard !candidates.isEmpty else { continue }
                    // Prefer a candidate that contains a tracked pattern
                    let candidate = candidates.first(where: { c in
                        patterns.contains(where: { c.string.contains($0) })
                    }) ?? candidates.first!
                    let text = candidate.string

                    let charCount = text.count
                    let box = observation.boundingBox

                    for pattern in patterns {
                        var searchRange = text.startIndex..<text.endIndex
                        while let range = text.range(of: pattern, range: searchRange) {
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
                }

                continuation.resume(returning: rects)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
            request.customWords = patterns
            request.automaticallyDetectsLanguage = true

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
