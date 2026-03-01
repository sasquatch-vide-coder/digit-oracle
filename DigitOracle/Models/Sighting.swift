import Foundation
import SwiftData
import CoreLocation

@Model
final class Sighting {
    // MARK: - Identity (cloud-ready)
    var id: UUID
    var ownerUserID: UUID

    // MARK: - Image
    var imageFileName: String
    var thumbnailFileName: String?
    var hasLocalFullImage: Bool
    // MARK: - Timestamps
    var captureDate: Date
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Location
    var latitude: Double?
    var longitude: Double?
    var locationName: String?

    // MARK: - User Input
    var notes: String
    var isFavorite: Bool
    var category: String?
    var rarityScore: Int
    var rarityAutoScore: Int?

    // MARK: - OCR
    var detectedText: String?
    var contains47: Bool
    var matchedNumbers: [Int] = []
    var matchCountsData: String = "{}"

    var matchCounts: [String: Int] {
        get {
            guard let data = matchCountsData.data(using: .utf8),
                  let dict = try? JSONDecoder().decode([String: Int].self, from: data) else { return [:] }
            return dict
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let str = String(data: data, encoding: .utf8) {
                matchCountsData = str
            }
        }
    }

    var containsTrackedNumber: Bool {
        !matchedNumbers.isEmpty
    }

    var totalMatchCount: Int {
        matchCounts.values.reduce(0, +)
    }

    // MARK: - Source
    var sourceType: String
    var sourceIdentifier: String?
    var imageHash: String?

    // MARK: - Relationships
    @Relationship(deleteRule: .nullify, inverse: \Tag.sightings)
    var tags: [Tag]

    @Relationship(deleteRule: .nullify, inverse: \Album.sightings)
    var albums: [Album]

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(
        ownerUserID: UUID,
        imageFileName: String,
        captureDate: Date = .now,
        notes: String = "",
        sourceType: String = "camera",
        category: String? = nil,
        rarityScore: Int = 1,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.id = UUID()
        self.ownerUserID = ownerUserID
        self.imageFileName = imageFileName
        self.captureDate = captureDate
        self.createdAt = .now
        self.updatedAt = .now
        self.notes = notes
        self.isFavorite = false
        self.contains47 = false
        self.sourceType = sourceType
        self.category = category
        self.rarityScore = rarityScore
        self.latitude = latitude
        self.longitude = longitude
        self.hasLocalFullImage = true
        self.tags = []
        self.albums = []
    }
}
