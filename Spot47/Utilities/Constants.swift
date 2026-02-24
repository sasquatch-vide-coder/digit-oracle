import Foundation

enum Constants {
    static let appName = "Spot47"
    static let deepLinkScheme = "spot47"
    static let appGroupIdentifier = "group.com.spot47.app"

    static let defaultOwnerID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    enum ImageStorage {
        static let directoryName = "SightingImages"
        static let fullSuffix = "_full"
        static let thumbSuffix = "_thumb"
        static let jpegCompression: CGFloat = 0.8
        static let thumbnailSize: CGFloat = 300
    }

    enum PendingShares {
        static let directoryName = "PendingShares"
        static let metadataFileName = "metadata.json"
        static let imageFileName = "image.jpg"
        static let hasPendingKey = "share_hasPendingItems"
    }

    enum LiveDetector {
        static let throttleInterval: TimeInterval = 0.5
        static let cooldownDuration: TimeInterval = 3.0
        static let confirmationFrames = 2
    }

    enum Rarity {
        static let common = 1
        static let uncommon = 2
        static let rare = 3
        static let epic = 4
        static let legendary = 5

        static func label(for score: Int) -> String {
            switch score {
            case 1: "Common"
            case 2: "Uncommon"
            case 3: "Rare"
            case 4: "Epic"
            case 5: "Legendary"
            default: "Unknown"
            }
        }
    }
}
