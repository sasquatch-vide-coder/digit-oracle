import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var displayName: String
    var avatarFileName: String?
    var joinedDate: Date
    var isLocalOnly: Bool
    var friendIDs: [UUID]
    var bio: String
    var streakFreezes: Int

    init(displayName: String) {
        self.id = UUID()
        self.displayName = displayName
        self.joinedDate = .now
        self.isLocalOnly = true
        self.friendIDs = []
        self.bio = ""
        self.streakFreezes = 0
    }
}
