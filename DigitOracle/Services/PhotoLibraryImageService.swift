import Photos
import UIKit

final class PhotoLibraryImageService {
    static let shared = PhotoLibraryImageService()

    func loadFullImage(identifier: String) async -> UIImage? {
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        guard let asset = result.firstObject else { return nil }

        let targetSize = CGSize(
            width: CGFloat(asset.pixelWidth),
            height: CGFloat(asset.pixelHeight)
        )

        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isSynchronous = false
            options.isNetworkAccessAllowed = true
            options.resizeMode = .none

            PHImageManager.default().requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFit,
                options: options
            ) { image, info in
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if !isDegraded {
                    continuation.resume(returning: image)
                }
            }
        }
    }

    func saveToPhotoLibrary(_ image: UIImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            var localID: String?
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
                localID = request.placeholderForCreatedAsset?.localIdentifier
            }) { success, error in
                if success, let id = localID {
                    continuation.resume(returning: id)
                } else {
                    continuation.resume(throwing: error ?? PhotoLibraryError.saveFailed)
                }
            }
        }
    }

    func assetExists(identifier: String) -> Bool {
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        return result.count > 0
    }
}

enum PhotoLibraryError: LocalizedError {
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .saveFailed:
            "Failed to save photo to library"
        }
    }
}
