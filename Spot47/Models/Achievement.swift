import Foundation
import SwiftData

@Model
final class Achievement {
    var id: UUID
    var key: String
    var name: String
    var descriptionText: String
    var iconName: String
    var unlockedAt: Date?
    var progress: Double

    var isUnlocked: Bool {
        unlockedAt != nil
    }

    init(
        key: String,
        name: String,
        descriptionText: String,
        iconName: String
    ) {
        self.id = UUID()
        self.key = key
        self.name = name
        self.descriptionText = descriptionText
        self.iconName = iconName
        self.progress = 0.0
    }
}
