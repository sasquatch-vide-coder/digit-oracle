import Foundation
import SwiftData

enum PreviewSampleData {
    static let ownerID = Constants.defaultOwnerID

    static func makeSampleSightings() -> [Sighting] {
        [
            {
                let s = Sighting(
                    ownerUserID: ownerID,
                    imageFileName: "sample_1.jpg",
                    captureDate: Date.now.addingTimeInterval(-86400),
                    notes: "Spotted on a license plate in the parking lot!",
                    sourceType: "camera",
                    category: "natural",
                    rarityScore: 3,
                    latitude: 37.7749,
                    longitude: -122.4194
                )
                s.locationName = "San Francisco, CA"
                s.contains47 = true
                s.detectedText = "License: ABC 47D"
                return s
            }(),
            {
                let s = Sighting(
                    ownerUserID: ownerID,
                    imageFileName: "sample_2.jpg",
                    captureDate: Date.now.addingTimeInterval(-172800),
                    notes: "Room 47 at the hotel",
                    sourceType: "camera",
                    category: "architectural",
                    rarityScore: 2
                )
                return s
            }(),
            {
                let s = Sighting(
                    ownerUserID: ownerID,
                    imageFileName: "sample_3.jpg",
                    captureDate: Date.now.addingTimeInterval(-259200),
                    notes: "Page 47 of my novel - great chapter!",
                    sourceType: "library",
                    category: "printed",
                    rarityScore: 1
                )
                return s
            }(),
            {
                let s = Sighting(
                    ownerUserID: ownerID,
                    imageFileName: "sample_4.jpg",
                    captureDate: Date.now.addingTimeInterval(-3600),
                    notes: "Receipt total was exactly $47.00",
                    sourceType: "camera",
                    category: "serendipitous",
                    rarityScore: 5,
                    latitude: 40.7128,
                    longitude: -74.0060
                )
                s.locationName = "New York, NY"
                s.contains47 = true
                s.detectedText = "TOTAL: $47.00"
                return s
            }(),
            {
                let s = Sighting(
                    ownerUserID: ownerID,
                    imageFileName: "sample_5.jpg",
                    captureDate: Date.now.addingTimeInterval(-7200),
                    notes: "47% battery at exactly 4:47 PM",
                    sourceType: "library",
                    category: "digital",
                    rarityScore: 4
                )
                return s
            }()
        ]
    }

    @MainActor
    static var previewContainer: ModelContainer {
        let schema = Schema([
            Sighting.self,
            Album.self,
            Tag.self,
            UserProfile.self,
            Achievement.self,
            Challenge.self,
            TimeCapsule.self
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])

        for sighting in makeSampleSightings() {
            container.mainContext.insert(sighting)
        }

        return container
    }
}
