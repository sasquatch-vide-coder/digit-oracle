import Foundation
import SwiftData

@Model
final class TimeCapsule {
    var id: UUID
    var name: String
    var sealedDate: Date
    var openDate: Date
    var isOpened: Bool
    var sightingIDs: [UUID]
    var message: String?

    var canOpen: Bool {
        Date.now >= openDate
    }

    var daysUntilOpen: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: .now, to: openDate)
        return max(0, components.day ?? 0)
    }

    init(
        name: String,
        openDate: Date,
        sightingIDs: [UUID],
        message: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.sealedDate = .now
        self.openDate = openDate
        self.isOpened = false
        self.sightingIDs = sightingIDs
        self.message = message
    }
}
