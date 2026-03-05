import UIKit

final class ImageStorageService {
    static let shared = ImageStorageService()

    private let fileManager = FileManager.default

    private var imagesDirectory: URL {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let directory = documentsURL.appendingPathComponent(Constants.ImageStorage.directoryName)
        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }

    // MARK: - Save

    /// Saves a full-resolution image and its thumbnail to disk.
    /// Returns (fullFileName, thumbFileName).
    func saveImage(_ image: UIImage, id: UUID) throws -> (full: String, thumbnail: String) {
        let fullFileName = "\(id.uuidString)\(Constants.ImageStorage.fullSuffix).jpg"
        let thumbFileName = "\(id.uuidString)\(Constants.ImageStorage.thumbSuffix).jpg"

        let fullURL = imagesDirectory.appendingPathComponent(fullFileName)
        let thumbURL = imagesDirectory.appendingPathComponent(thumbFileName)

        let normalized = normalizeOrientation(image)
        guard let fullData = normalized.jpegData(compressionQuality: Constants.ImageStorage.jpegCompression) else {
            throw ImageStorageError.compressionFailed
        }
        try fullData.write(to: fullURL)

        let thumbnail = generateThumbnail(from: normalized, size: Constants.ImageStorage.thumbnailSize)
        guard let thumbData = thumbnail.jpegData(compressionQuality: Constants.ImageStorage.jpegCompression) else {
            throw ImageStorageError.compressionFailed
        }
        try thumbData.write(to: thumbURL)

        return (fullFileName, thumbFileName)
    }

    /// Saves only a thumbnail to disk (no full-resolution copy).
    /// Returns the thumbnail filename.
    func saveThumbnailOnly(_ image: UIImage, id: UUID) throws -> String {
        let thumbFileName = "\(id.uuidString)\(Constants.ImageStorage.thumbSuffix).jpg"
        let thumbURL = imagesDirectory.appendingPathComponent(thumbFileName)

        let normalized = normalizeOrientation(image)
        let thumbnail = generateThumbnail(from: normalized, size: Constants.ImageStorage.thumbnailSize)
        guard let thumbData = thumbnail.jpegData(compressionQuality: Constants.ImageStorage.jpegCompression) else {
            throw ImageStorageError.compressionFailed
        }
        try thumbData.write(to: thumbURL)

        return thumbFileName
    }

    // MARK: - Load

    func loadImage(fileName: String) -> UIImage? {
        let url = imagesDirectory.appendingPathComponent(fileName)
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    // MARK: - Delete

    func deleteImage(fileName: String) throws {
        let url = imagesDirectory.appendingPathComponent(fileName)
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    func deleteImages(for sightingID: UUID) throws {
        let fullFileName = "\(sightingID.uuidString)\(Constants.ImageStorage.fullSuffix).jpg"
        let thumbFileName = "\(sightingID.uuidString)\(Constants.ImageStorage.thumbSuffix).jpg"

        try? deleteImage(fileName: fullFileName)
        try? deleteImage(fileName: thumbFileName)
    }

    func deleteAllImages() {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: imagesDirectory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else { return }
        for url in contents {
            try? fileManager.removeItem(at: url)
        }
    }

    // MARK: - Stats

    struct StorageStats {
        let fileCount: Int
        let totalBytes: Int64
    }

    func calculateStorageStats() -> StorageStats {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: imagesDirectory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: .skipsHiddenFiles
        ) else {
            return StorageStats(fileCount: 0, totalBytes: 0)
        }

        var totalBytes: Int64 = 0
        for url in contents {
            if let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize {
                totalBytes += Int64(size)
            }
        }

        let imageCount = contents.filter { $0.lastPathComponent.contains(Constants.ImageStorage.fullSuffix) }.count
        return StorageStats(fileCount: imageCount, totalBytes: totalBytes)
    }

    // MARK: - Paths

    func thumbnailURL(for fileName: String) -> URL {
        imagesDirectory.appendingPathComponent(fileName)
    }

    // MARK: - Perceptual Hash

    /// Computes an 8x8 average perceptual hash for duplicate detection.
    /// Returns a 16-character hex string, or nil if the image can't be processed.
    static func perceptualHash(of image: UIImage) -> String? {
        // Normalize orientation so the same photo always produces the same hash
        // regardless of whether it was loaded via PHImageManager or PhotosPicker
        let cgImage: CGImage
        if image.imageOrientation == .up, let cg = image.cgImage {
            cgImage = cg
        } else {
            let renderer = UIGraphicsImageRenderer(size: image.size)
            let normalized = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: image.size))
            }
            guard let cg = normalized.cgImage else { return nil }
            cgImage = cg
        }

        let size = 8
        let colorSpace = CGColorSpaceCreateDeviceGray()

        guard let context = CGContext(
            data: nil,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: size,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }

        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size, height: size))

        guard let data = context.data else { return nil }
        let pixels = data.bindMemory(to: UInt8.self, capacity: size * size)

        // Compute mean pixel value
        var sum = 0
        for i in 0..<(size * size) {
            sum += Int(pixels[i])
        }
        let mean = sum / (size * size)

        // Build 64-bit hash: 1 if pixel >= mean, 0 otherwise
        var hash: UInt64 = 0
        for i in 0..<(size * size) {
            if pixels[i] >= mean {
                hash |= (1 << (63 - i))
            }
        }

        return String(format: "%016llx", hash)
    }

    /// Hamming distance between two 16-char hex hash strings.
    static func hashDistance(_ a: String, _ b: String) -> Int? {
        guard let va = UInt64(a, radix: 16),
              let vb = UInt64(b, radix: 16) else { return nil }
        return (va ^ vb).nonzeroBitCount
    }

    /// Returns true if two perceptual hashes are within the duplicate threshold.
    static func isPerceptualDuplicate(_ a: String, _ b: String) -> Bool {
        guard let distance = hashDistance(a, b) else { return false }
        return distance <= Constants.Duplicates.hashDistanceThreshold
    }

    // MARK: - Orientation Normalization

    private func normalizeOrientation(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }

    // MARK: - Thumbnail Generation

    private func generateThumbnail(from image: UIImage, size: CGFloat) -> UIImage {
        let aspectRatio = image.size.width / image.size.height
        let targetSize: CGSize
        if aspectRatio > 1 {
            targetSize = CGSize(width: size, height: size / aspectRatio)
        } else {
            targetSize = CGSize(width: size * aspectRatio, height: size)
        }

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}

enum ImageStorageError: LocalizedError {
    case compressionFailed

    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            "Failed to compress image data"
        }
    }
}
