import Photos
import UIKit

struct LibraryScanResult: Identifiable {
    let id: String  // PHAsset localIdentifier
    let asset: PHAsset
    let thumbnail: UIImage
    let ocrResult: OCRResult
    let creationDate: Date?
}

@Observable
final class LibraryScannerService {
    enum ScanState {
        case idle
        case scanning
        case completed
        case cancelled
    }

    var state: ScanState = .idle
    var scannedCount = 0
    var totalCount = 0
    var matches: [LibraryScanResult] = []
    var errorMessage: String?

    private var scanTask: Task<Void, Never>?
    private var excludedIdentifiers: Set<String> = []

    // MARK: - Permissions

    var authorizationStatus: PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func requestAccess() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        return status == .authorized || status == .limited
    }

    // MARK: - Scanning

    func startScan(excludingIdentifiers: Set<String> = []) {
        guard state != .scanning else { return }
        state = .scanning
        scannedCount = 0
        totalCount = 0
        matches = []
        errorMessage = nil
        excludedIdentifiers = excludingIdentifiers

        scanTask = Task { await performScan() }
    }

    func cancel() {
        scanTask?.cancel()
        scanTask = nil
        if state == .scanning {
            state = .cancelled
        }
    }

    private func performScan() async {
        // Capture excluded set locally to avoid @Observable access from background tasks
        let excluded = excludedIdentifiers

        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)

        // Collect assets, filtering out already-imported ones upfront
        var assetList: [PHAsset] = []
        assetList.reserveCapacity(assets.count)
        assets.enumerateObjects { asset, _, _ in
            if !excluded.contains(asset.localIdentifier) {
                assetList.append(asset)
            }
        }

        await MainActor.run {
            totalCount = assetList.count
        }

        guard !assetList.isEmpty else {
            await MainActor.run { state = .completed }
            return
        }

        // Process with limited concurrency
        await withTaskGroup(of: LibraryScanResult?.self) { group in
            var inFlight = 0
            var index = 0
            let maxConcurrent = 4

            // Seed initial batch
            while index < assetList.count && inFlight < maxConcurrent {
                let asset = assetList[index]
                index += 1
                inFlight += 1
                group.addTask { [weak self] in
                    guard !Task.isCancelled else { return nil }
                    return await self?.processAsset(asset)
                }
            }

            for await result in group {
                if Task.isCancelled { break }

                await MainActor.run {
                    scannedCount += 1
                    if let result {
                        matches.append(result)
                    }
                }

                // Add next task
                if index < assetList.count {
                    let asset = assetList[index]
                    index += 1
                    group.addTask { [weak self] in
                        guard !Task.isCancelled else { return nil }
                        return await self?.processAsset(asset)
                    }
                }
            }
        }

        if !Task.isCancelled {
            await MainActor.run { state = .completed }
        }
    }

    private func processAsset(_ asset: PHAsset) async -> LibraryScanResult? {
        guard let image = await loadImage(from: asset, targetSize: CGSize(width: 600, height: 600)) else {
            return nil
        }

        let ocrResult = await OCRService.shared.detectText(in: image)

        guard ocrResult.containsTrackedNumber else { return nil }

        // Generate a smaller thumbnail for display
        let thumbnail = await loadImage(from: asset, targetSize: CGSize(width: 300, height: 300)) ?? image

        return LibraryScanResult(
            id: asset.localIdentifier,
            asset: asset,
            thumbnail: thumbnail,
            ocrResult: ocrResult,
            creationDate: asset.creationDate
        )
    }

    private func loadImage(from asset: PHAsset, targetSize: CGSize) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isSynchronous = false
            options.isNetworkAccessAllowed = true
            options.resizeMode = .fast

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

    // MARK: - Import

    func loadFullImage(for result: LibraryScanResult) async -> UIImage? {
        let size = CGSize(
            width: CGFloat(result.asset.pixelWidth),
            height: CGFloat(result.asset.pixelHeight)
        )
        return await loadImage(from: result.asset, targetSize: size)
    }
}
