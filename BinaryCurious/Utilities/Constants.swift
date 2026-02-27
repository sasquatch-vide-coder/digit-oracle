import Foundation

enum Constants {
    static let appName = "Binary Curious"
    static let deepLinkScheme = "binarycurious"
    static let appGroupIdentifier = "group.com.binarycurious.app"

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

        static let throttleIntervalKey = "ocr_throttle_interval"
        static let cooldownDurationKey = "ocr_cooldown_duration"
        static let confirmationFramesKey = "ocr_confirmation_frames"
    }

    enum OCR {
        static let useFastMode = false
        static let useFastModeKey = "ocr_use_fast_mode"
        static let useLanguageCorrection = true
        static let useLanguageCorrectionKey = "ocr_use_language_correction"
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

    enum TrackedNumbers {
        static let maxTrackedNumbers = 10
        static let defaultNumbers: [Int] = [47]
        static let suggestedNumbers = [7, 21, 47, 69]
    }
}
