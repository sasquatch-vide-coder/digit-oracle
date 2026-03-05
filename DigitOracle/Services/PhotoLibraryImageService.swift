import Photos
import UIKit

final class PhotoLibraryImageService {
    static let shared = PhotoLibraryImageService()

    private func assetHasResources(_ identifier: String) -> Bool {
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        guard let asset = result.firstObject else { return false }
        return !PHAssetResource.assetResources(for: asset).isEmpty
    }

    func loadFullImage(identifier: String) async -> UIImage? {
        guard assetHasResources(identifier) else { return nil }

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
                let isCancelled = (info?[PHImageCancelledKey] as? Bool) ?? false
                let hasError = info?[PHImageErrorKey] != nil
                if !isDegraded || isCancelled || hasError {
                    continuation.resume(returning: isDegraded ? nil : image)
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
        return result.count > 0 && assetHasResources(identifier)
    }

    func findMissingIdentifiers(from identifiers: [String]) -> Set<String> {
        guard !identifiers.isEmpty else { return [] }

        // Pass 1: find assets not returned by fetchAssets at all (permanently deleted)
        let found = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        var foundIDs = Set<String>()
        found.enumerateObjects { asset, _, _ in
            foundIDs.insert(asset.localIdentifier)
        }
        var missing = Set(identifiers).subtracting(foundIDs)

        // Pass 2: check each found asset actually has resources
        // (catches Recently Deleted — asset exists but resources are empty)
        for id in foundIDs {
            if !assetHasResources(id) {
                missing.insert(id)
            }
        }

        return missing
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
