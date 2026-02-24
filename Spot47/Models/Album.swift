import Foundation
import SwiftData

@Model
final class Album {
    var id: UUID
    var ownerUserID: UUID
    var name: String
    var albumDescription: String
    var coverImageFileName: String?
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .nullify)
    var sightings: [Sighting]

    init(
        ownerUserID: UUID,
        name: String,
        albumDescription: String = ""
    ) {
        self.id = UUID()
        self.ownerUserID = ownerUserID
        self.name = name
        self.albumDescription = albumDescription
        self.createdAt = .now
        self.updatedAt = .now
        self.sightings = []
    }
}
