import Vision
import UIKit

struct OCRResult: Codable {
    let fullText: String?
    let contains47: Bool
    let matchCount: Int
    let matchedNumbers: [Int]
    let matchCounts: [String: Int]

    var containsTrackedNumber: Bool {
        !matchedNumbers.isEmpty
    }
}

struct DetectionResult: Codable {
    let ocr: OCRResult
    let locations: [CodableRect]

    var locationRects: [CGRect] {
        locations.map(\.cgRect)
    }

    static let empty = DetectionResult(
        ocr: OCRResult(fullText: nil, contains47: false, matchCount: 0, matchedNumbers: [], matchCounts: [:]),
        locations: []
    )

    init(ocr: OCRResult, rects: [CGRect]) {
        self.ocr = ocr
        self.locations = rects.map { CodableRect(cgRect: $0) }
    }

    init(ocr: OCRResult, locations: [CodableRect]) {
        self.ocr = ocr
        self.locations = locations
    }
}

struct CodableRect: Codable {
    let x, y, width, height: CGFloat
    var cgRect: CGRect { CGRect(x: x, y: y, width: width, height: height) }
    init(cgRect: CGRect) {
        x = cgRect.origin.x; y = cgRect.origin.y
        width = cgRect.width; height = cgRect.height
    }
}

final class OCRService {
    static let shared = OCRService()

    // MARK: - Detection Cache

    /// Save detection results to a JSON file alongside the image.
    func saveDetection(_ result: DetectionResult, for imageFileName: String) {
        let jsonName = imageFileName.replacingOccurrences(of: "_full.jpg", with: "_detection.json")
        let url = ImageStorageService.shared.thumbnailURL(for: jsonName)
        try? JSONEncoder().encode(result).write(to: url)
    }

    /// Load cached detection results, if available.
    func loadDetection(for imageFileName: String) -> DetectionResult? {
        let jsonName = imageFileName.replacingOccurrences(of: "_full.jpg", with: "_detection.json")
        let url = ImageStorageService.shared.thumbnailURL(for: jsonName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(DetectionResult.self, from: data)
    }

    // MARK: - Public API

    /// Single entry point: runs Vision once and returns both OCR results and highlight locations.
    func detect(in image: UIImage) async -> DetectionResult {
        let upright = normalizedImage(image)
        guard let cgImage = upright.cgImage else { return .empty }

        let patterns = TrackedNumberService.shared.patterns
        let raw = await performDetection(cgImage: cgImage, patterns: patterns)
        return DetectionResult(ocr: raw.ocrResult, rects: raw.rects)
    }

    // MARK: - Detection

    private struct RawDetectionResult {
        let ocrResult: OCRResult
        let rects: [CGRect]
    }

    private static let visionQueue = DispatchQueue(label: "com.digitoracle.vision", qos: .userInitiated, attributes: .concurrent)

    private func performDetection(cgImage: CGImage, patterns: [String]) async -> RawDetectionResult {
        await withCheckedContinuation { continuation in
            Self.visionQueue.async {
                let request = VNRecognizeTextRequest { request, _ in
                    guard let observations = request.results as? [VNRecognizedTextObservation] else {
                        continuation.resume(returning: RawDetectionResult(
                            ocrResult: OCRResult(fullText: nil, contains47: false, matchCount: 0, matchedNumbers: [], matchCounts: [:]),
                            rects: []))
                        return
                    }

                    var allTextParts: [String] = []
                    var rects: [CGRect] = []
                    var perNumberCounts: [String: Int] = [:]

                    for observation in observations {
                        let candidates = observation.topCandidates(5)
                        guard let top = candidates.first else { continue }

                        // Prefer a candidate that contains a pattern match,
                        // but only if its confidence is at least 40% of the top candidate's.
                        let matchingCandidate = candidates.first(where: { c in
                            patterns.contains(where: { c.string.contains($0) }) && c.confidence >= top.confidence * 0.4
                        })
                        let chosen = matchingCandidate ?? top

                        let text = chosen.string
                        allTextParts.append(text)

                        // Collect bounding boxes and counts in a single pass
                        for pattern in patterns {
                            var searchRange = text.startIndex..<text.endIndex
                            while let range = text.range(of: pattern, range: searchRange) {
                                perNumberCounts[pattern, default: 0] += 1
                                if let boundingBox = try? chosen.boundingBox(for: range) {
                                    rects.append(boundingBox.boundingBox)
                                } else {
                                    rects.append(observation.boundingBox)
                                }
                                searchRange = range.upperBound..<text.endIndex
                            }
                        }
                    }

                    let allText = allTextParts.joined(separator: " ")

                    var matched: [Int] = []
                    for (pattern, count) in perNumberCounts where count > 0 {
                        if let num = Int(pattern) { matched.append(num) }
                    }

                    let count47 = perNumberCounts["47"] ?? 0
                    let totalCount = perNumberCounts.values.reduce(0, +)

                    continuation.resume(returning: RawDetectionResult(
                        ocrResult: OCRResult(
                            fullText: allText.isEmpty ? nil : allText,
                            contains47: count47 > 0,
                            matchCount: totalCount,
                            matchedNumbers: matched,
                            matchCounts: perNumberCounts),
                        rects: rects))
                }

                request.recognitionLevel = UserDefaults.standard.bool(forKey: Constants.OCR.useFastModeKey) ? .fast : .accurate
                request.usesLanguageCorrection = UserDefaults.standard.bool(forKey: Constants.OCR.useLanguageCorrectionKey)
                request.customWords = patterns
                request.automaticallyDetectsLanguage = true

                let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(returning: RawDetectionResult(
                        ocrResult: OCRResult(fullText: nil, contains47: false, matchCount: 0, matchedNumbers: [], matchCounts: [:]),
                        rects: []))
                }
            }
        }
    }

    // MARK: - Image Helpers

    private func normalizedImage(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }


}
