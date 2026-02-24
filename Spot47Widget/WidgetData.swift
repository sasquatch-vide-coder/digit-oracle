import Foundation
import UIKit

/// Reads shared data from App Group UserDefaults. Mirror of WidgetDataService read-side.
enum WidgetData {
    private static let suiteName = "group.com.spot47.app"
    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    static var totalCount: Int {
        defaults?.integer(forKey: "widget_totalCount") ?? 0
    }

    static var currentStreak: Int {
        defaults?.integer(forKey: "widget_currentStreak") ?? 0
    }

    static var verifiedCount: Int {
        defaults?.integer(forKey: "widget_verifiedCount") ?? 0
    }

    static var latestNotes: String {
        defaults?.string(forKey: "widget_lastSightingNotes") ?? "No sightings yet"
    }

    static var latestDate: Date? {
        defaults?.object(forKey: "widget_lastSightingDate") as? Date
    }

    static var latestCategory: String {
        defaults?.string(forKey: "widget_lastSightingCategory") ?? ""
    }

    // MARK: - Sighting List with Images

    struct SharedSighting {
        let id: String
        let fileName: String
        let notes: String
        let date: Date?
        let category: String
        let location: String?
    }

    static var sharedSightings: [SharedSighting] {
        guard let jsonString = defaults?.string(forKey: "widget_sightingList"),
              let data = jsonString.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [[String: String]]
        else { return [] }

        let formatter = ISO8601DateFormatter()
        return array.compactMap { dict in
            guard let id = dict["id"],
                  let fileName = dict["fileName"],
                  let notes = dict["notes"],
                  let category = dict["category"]
            else { return nil }

            let date = dict["date"].flatMap { formatter.date(from: $0) }
            return SharedSighting(
                id: id,
                fileName: fileName,
                notes: notes,
                date: date,
                category: category,
                location: dict["location"]
            )
        }
    }

    static func loadImage(fileName: String) -> UIImage? {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: suiteName
        ) else { return nil }

        let url = container
            .appendingPathComponent("WidgetImages")
            .appendingPathComponent(fileName)
        return UIImage(contentsOfFile: url.path)
    }
}
