import Foundation
import SwiftData

@Model
final class Challenge {
    var id: UUID
    var title: String
    var descriptionText: String
    var challengeType: String
    var category: String?
    var startDate: Date
    var endDate: Date
    var isCompleted: Bool
    var completedSightingID: UUID?

    var isActive: Bool {
        let now = Date.now
        return now >= startDate && now <= endDate && !isCompleted
    }

    var isExpired: Bool {
        Date.now > endDate && !isCompleted
    }

    init(
        title: String,
        descriptionText: String,
        challengeType: String,
        category: String? = nil,
        startDate: Date,
        endDate: Date
    ) {
        self.id = UUID()
        self.title = title
        self.descriptionText = descriptionText
        self.challengeType = challengeType
        self.category = category
        self.startDate = startDate
        self.endDate = endDate
        self.isCompleted = false
    }
}
