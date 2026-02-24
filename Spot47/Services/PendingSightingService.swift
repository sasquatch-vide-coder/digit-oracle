import Foundation
import UIKit

struct PendingSighting: Codable {
    let id: UUID
    let notes: String
    let captureDate: Date
    let sourceType: String
}

enum PendingSightingService {
    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: Constants.appGroupIdentifier)
    }

    static var pendingDirectory: URL? {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Constants.appGroupIdentifier
        ) else { return nil }
        let dir = container.appendingPathComponent(Constants.PendingShares.directoryName)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    // MARK: - Write (called by share extension)

    static func savePending(id: UUID, image: UIImage, notes: String) throws {
        guard let dir = pendingDirectory else { return }

        let itemDir = dir.appendingPathComponent(id.uuidString)
        try FileManager.default.createDirectory(at: itemDir, withIntermediateDirectories: true)

        // Write image first (so metadata presence signals completion)
        let imageURL = itemDir.appendingPathComponent(Constants.PendingShares.imageFileName)
        guard let imageData = image.jpegData(compressionQuality: Constants.ImageStorage.jpegCompression) else {
            return
        }
        try imageData.write(to: imageURL)

        // Write metadata last
        let metadata = PendingSighting(
            id: id,
            notes: notes,
            captureDate: .now,
            sourceType: "share"
        )
        let metadataURL = itemDir.appendingPathComponent(Constants.PendingShares.metadataFileName)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(metadata)
        try jsonData.write(to: metadataURL)

        setHasPendingItems(true)
    }

    // MARK: - Read (called by main app)

    static var hasPendingItems: Bool {
        defaults?.bool(forKey: Constants.PendingShares.hasPendingKey) ?? false
    }

    static func setHasPendingItems(_ value: Bool) {
        defaults?.set(value, forKey: Constants.PendingShares.hasPendingKey)
    }

    static func loadAllPending() -> [(metadata: PendingSighting, image: UIImage)] {
        guard let dir = pendingDirectory else { return [] }
        guard let contents = try? FileManager.default.contentsOfDirectory(atPath: dir.path) else { return [] }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        var results: [(metadata: PendingSighting, image: UIImage)] = []

        for itemName in contents {
            let itemDir = dir.appendingPathComponent(itemName)
            let metadataURL = itemDir.appendingPathComponent(Constants.PendingShares.metadataFileName)
            let imageURL = itemDir.appendingPathComponent(Constants.PendingShares.imageFileName)

            // Only process items that have both metadata and image
            guard FileManager.default.fileExists(atPath: metadataURL.path),
                  FileManager.default.fileExists(atPath: imageURL.path),
                  let metadataData = try? Data(contentsOf: metadataURL),
                  let metadata = try? decoder.decode(PendingSighting.self, from: metadataData),
                  let image = UIImage(contentsOfFile: imageURL.path)
            else { continue }

            results.append((metadata: metadata, image: image))
        }

        return results
    }

    static func deletePendingItem(id: UUID) throws {
        guard let dir = pendingDirectory else { return }
        let itemDir = dir.appendingPathComponent(id.uuidString)
        if FileManager.default.fileExists(atPath: itemDir.path) {
            try FileManager.default.removeItem(at: itemDir)
        }
    }

    static func deleteAllPending() throws {
        guard let dir = pendingDirectory else { return }
        if FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.removeItem(at: dir)
        }
    }
}
