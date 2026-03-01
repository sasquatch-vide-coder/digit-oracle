import Photos
import UIKit

struct LibraryScanResult: Identifiable {
    let id: String  // PHAsset localIdentifier
    let asset: PHAsset
    let scanImage: UIImage    // 600px image used for OCR/hash
    let thumbnail: UIImage    // 300px display thumbnail
    let detection: DetectionResult
    let hash: String?
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

    static let lastScanDateKey = "lastLibraryScanDate"

    var state: ScanState = .idle
    var scannedCount = 0
    var totalCount = 0
    var matches: [LibraryScanResult] = []
    var errorMessage: String?
    var scanStartDate: Date?
    var onMatch: ((LibraryScanResult) -> Void)?

    var lastScanDate: Date? {
        UserDefaults.standard.object(forKey: Self.lastScanDateKey) as? Date
    }

    private var scanTask: Task<Void, Never>?
    private var excludedIdentifiers: Set<String> = []
    private var excludedHashes: Set<String> = []
    private var sinceDate: Date?

    // MARK: - Permissions

    var authorizationStatus: PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func requestAccess() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        return status == .authorized || status == .limited
    }

    // MARK: - Scanning

    func startScan(excludingIdentifiers: Set<String> = [], excludingHashes: Set<String> = [], sinceDate: Date? = nil) {
        guard state != .scanning else { return }
        state = .scanning
        scannedCount = 0
        totalCount = 0
        matches = []
        errorMessage = nil
        scanStartDate = .now
        excludedIdentifiers = excludingIdentifiers
        excludedHashes = excludingHashes
        self.sinceDate = sinceDate

        scanTask = Task { await performScan() }
    }

    func resetLastScanDate() {
        UserDefaults.standard.removeObject(forKey: Self.lastScanDateKey)
    }

    func cancel() {
        scanTask?.cancel()
        scanTask = nil
        if state == .scanning {
            state = .cancelled
        }
    }

    private func performScan() async {
        // Capture excluded sets locally to avoid @Observable access from background tasks
        let excluded = excludedIdentifiers
        let excludedHashSet = excludedHashes
        let scanSinceDate = sinceDate

        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        if let scanSinceDate {
            fetchOptions.predicate = NSPredicate(format: "creationDate >= %@", scanSinceDate as NSDate)
        }
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
                    return await self?.processAsset(asset, excludedHashes: excludedHashSet)
                }
            }

            for await result in group {
                if Task.isCancelled { break }

                await MainActor.run {
                    scannedCount += 1
                    if let result {
                        matches.append(result)
                        onMatch?(result)
                    }
                }

                // Add next task
                if index < assetList.count {
                    let asset = assetList[index]
                    index += 1
                    group.addTask { [weak self] in
                        guard !Task.isCancelled else { return nil }
                        return await self?.processAsset(asset, excludedHashes: excludedHashSet)
                    }
                }
            }
        }

        if !Task.isCancelled {
            await MainActor.run {
                state = .completed
                UserDefaults.standard.set(Date.now, forKey: Self.lastScanDateKey)
            }
        }
    }

    private func processAsset(_ asset: PHAsset, excludedHashes: Set<String>) async -> LibraryScanResult? {
        guard let image = await loadImage(from: asset, targetSize: CGSize(width: 600, height: 600)) else {
            return nil
        }

        // Skip if a perceptually identical image was already imported
        let hash = ImageStorageService.perceptualHash(of: image)
        if !excludedHashes.isEmpty,
           let hash,
           excludedHashes.contains(hash) {
            return nil
        }

        let detection = await OCRService.shared.detect(in: image)

        guard detection.ocr.containsTrackedNumber else { return nil }

        // Generate a smaller thumbnail for display
        let thumbnail = await loadImage(from: asset, targetSize: CGSize(width: 300, height: 300)) ?? image

        return LibraryScanResult(
            id: asset.localIdentifier,
            asset: asset,
            scanImage: image,
            thumbnail: thumbnail,
            detection: detection,
            hash: hash,
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

}
