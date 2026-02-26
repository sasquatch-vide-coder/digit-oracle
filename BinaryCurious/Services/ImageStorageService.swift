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

        return StorageStats(fileCount: contents.count, totalBytes: totalBytes)
    }

    // MARK: - Paths

    func thumbnailURL(for fileName: String) -> URL {
        imagesDirectory.appendingPathComponent(fileName)
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
