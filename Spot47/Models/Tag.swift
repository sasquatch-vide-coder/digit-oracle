import Foundation
import SwiftData

@Model
final class Tag {
    var id: UUID
    var name: String
    var colorHex: String?

    @Relationship(deleteRule: .nullify)
    var sightings: [Sighting]

    init(name: String, colorHex: String? = nil) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.sightings = []
    }
}
