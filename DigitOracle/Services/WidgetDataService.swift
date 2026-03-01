import Foundation

/// Writes key stats to App Group UserDefaults so widgets can read them.
enum WidgetDataService {
    private static let suiteName = Constants.appGroupIdentifier
    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    // Keys
    private static let totalCountKey = "widget_totalCount"
    private static let currentStreakKey = "widget_currentStreak"
    private static let lastSightingNotes = "widget_lastSightingNotes"
    private static let lastSightingDate = "widget_lastSightingDate"
    private static let lastSightingCategory = "widget_lastSightingCategory"
    private static let verifiedCountKey = "widget_verifiedCount"
    private static let sightingListKey = "widget_sightingList"

    private static let maxSharedSightings = 5
    private static let sharedImagesDirName = "WidgetImages"

    private static var sharedImagesDirectory: URL? {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Constants.appGroupIdentifier
        ) else { return nil }
        let dir = container.appendingPathComponent(sharedImagesDirName)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// Call after every sighting save to update widget data.
    static func update(from sightings: [Sighting]) {
        guard let defaults else { return }

        defaults.set(sightings.count, forKey: totalCountKey)
        defaults.set(StatsCalculator.currentStreak(from: sightings), forKey: currentStreakKey)
        defaults.set(sightings.filter(\.containsTrackedNumber).count, forKey: verifiedCountKey)

        // Write tracked numbers so widgets can read them
        defaults.set(TrackedNumberService.shared.trackedNumbers, forKey: "tracked_numbers")

        if let latest = sightings.max(by: { $0.captureDate < $1.captureDate }) {
            defaults.set(latest.notes, forKey: lastSightingNotes)
            defaults.set(latest.captureDate, forKey: lastSightingDate)
            defaults.set(latest.category ?? "", forKey: lastSightingCategory)
        }

        shareThumbnails(from: sightings)
    }

    // MARK: - Thumbnail Sharing

    private static func shareThumbnails(from sightings: [Sighting]) {
        guard let sharedDir = sharedImagesDirectory, let defaults else { return }

        // Pick most recent sightings that have thumbnails
        let recent = sightings
            .sorted { $0.captureDate > $1.captureDate }
            .prefix(maxSharedSightings)

        var entries: [[String: String]] = []
        var keptFileNames: Set<String> = []

        for sighting in recent {
            guard let thumbFileName = sighting.thumbnailFileName else { continue }

            let sharedFileName = sighting.id.uuidString + "_widget.jpg"
            let destURL = sharedDir.appendingPathComponent(sharedFileName)
            keptFileNames.insert(sharedFileName)

            // Copy thumbnail to shared container if not already there
            if !FileManager.default.fileExists(atPath: destURL.path) {
                let sourceURL = ImageStorageService.shared.thumbnailURL(for: thumbFileName)
                try? FileManager.default.copyItem(at: sourceURL, to: destURL)
            }

            var entry: [String: String] = [
                "id": sighting.id.uuidString,
                "fileName": sharedFileName,
                "notes": sighting.notes,
                "date": ISO8601DateFormatter().string(from: sighting.captureDate),
                "category": sighting.category ?? ""
            ]
            if let locationName = sighting.locationName {
                entry["location"] = locationName
            }
            entries.append(entry)
        }

        // Save sighting list as JSON
        if let jsonData = try? JSONSerialization.data(withJSONObject: entries),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            defaults.set(jsonString, forKey: sightingListKey)
        }

        // Clean up old images no longer in the set
        if let files = try? FileManager.default.contentsOfDirectory(atPath: sharedDir.path) {
            for file in files where !keptFileNames.contains(file) {
                try? FileManager.default.removeItem(at: sharedDir.appendingPathComponent(file))
            }
        }
    }

    // MARK: - Read (for widgets)

    static var totalCount: Int {
        defaults?.integer(forKey: totalCountKey) ?? 0
    }

    static var currentStreak: Int {
        defaults?.integer(forKey: currentStreakKey) ?? 0
    }

    static var verifiedCount: Int {
        defaults?.integer(forKey: verifiedCountKey) ?? 0
    }

    static var latestNotes: String {
        defaults?.string(forKey: lastSightingNotes) ?? "No sightings yet"
    }

    static var latestDate: Date? {
        defaults?.object(forKey: lastSightingDate) as? Date
    }

    static var latestCategory: String {
        defaults?.string(forKey: lastSightingCategory) ?? ""
    }
}
