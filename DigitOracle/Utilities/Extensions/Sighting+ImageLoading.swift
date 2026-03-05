import UIKit

extension Sighting {
    /// Loads the best available image from disk.
    /// - Parameter preferThumbnail: If `true` (default), tries thumbnail first for faster display.
    ///   If `false`, tries full image first for sharing/OCR.
    func loadBestImage(preferThumbnail: Bool = true) -> UIImage? {
        if preferThumbnail {
            if let thumbName = thumbnailFileName,
               let thumb = ImageStorageService.shared.loadImage(fileName: thumbName) {
                return thumb
            }
            guard hasLocalFullImage else { return nil }
            return ImageStorageService.shared.loadImage(fileName: imageFileName)
        } else {
            if hasLocalFullImage,
               let full = ImageStorageService.shared.loadImage(fileName: imageFileName) {
                return full
            }
            if let thumbName = thumbnailFileName {
                return ImageStorageService.shared.loadImage(fileName: thumbName)
            }
            return nil
        }
    }
}
