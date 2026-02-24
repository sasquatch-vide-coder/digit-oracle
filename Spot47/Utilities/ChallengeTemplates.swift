import Foundation

struct ChallengeTemplate {
    let title: String
    let description: String
    let category: String?        // required sighting category, nil = any
    let requiresVerified: Bool   // must be OCR-verified
    let requiresLocation: Bool   // must have GPS
    let minRarity: Int?          // minimum rarity score
    let timeWindow: String       // "daily" or "weekly"
    let reward: ChallengeReward
}

enum ChallengeReward {
    case streakFreeze(Int)
    case none

    var displayText: String {
        switch self {
        case .streakFreeze(let count): "\(count) streak freeze\(count == 1 ? "" : "s")"
        case .none: "Bragging rights"
        }
    }

    var iconName: String {
        switch self {
        case .streakFreeze: "snowflake"
        case .none: "star.fill"
        }
    }
}

enum ChallengeTemplates {

    static let daily: [ChallengeTemplate] = [
        ChallengeTemplate(title: "Quick Spot", description: "Capture any 47 sighting today", category: nil, requiresVerified: false, requiresLocation: false, minRarity: nil, timeWindow: "daily", reward: .none),
        ChallengeTemplate(title: "Verified Find", description: "Capture a sighting where OCR detects 47", category: nil, requiresVerified: true, requiresLocation: false, minRarity: nil, timeWindow: "daily", reward: .streakFreeze(1)),
        ChallengeTemplate(title: "Print Spotter", description: "Find a 47 in printed text (book, receipt, sign)", category: "printed", requiresVerified: false, requiresLocation: false, minRarity: nil, timeWindow: "daily", reward: .none),
        ChallengeTemplate(title: "Digital Detective", description: "Spot a 47 on a screen or display", category: "digital", requiresVerified: false, requiresLocation: false, minRarity: nil, timeWindow: "daily", reward: .none),
        ChallengeTemplate(title: "Nature Walk", description: "Find a 47 in the natural world", category: "natural", requiresVerified: false, requiresLocation: false, minRarity: nil, timeWindow: "daily", reward: .streakFreeze(1)),
        ChallengeTemplate(title: "Location Tag", description: "Capture a sighting with location data", category: nil, requiresVerified: false, requiresLocation: true, minRarity: nil, timeWindow: "daily", reward: .none),
        ChallengeTemplate(title: "Handwritten Hunt", description: "Find a handwritten 47", category: "handwritten", requiresVerified: false, requiresLocation: false, minRarity: nil, timeWindow: "daily", reward: .streakFreeze(1)),
    ]

    static let weekly: [ChallengeTemplate] = [
        ChallengeTemplate(title: "Rare Find", description: "Capture a Rare or better sighting this week", category: nil, requiresVerified: false, requiresLocation: false, minRarity: 3, timeWindow: "weekly", reward: .streakFreeze(2)),
        ChallengeTemplate(title: "Serendipity", description: "Find an unexpected 47 this week", category: "serendipitous", requiresVerified: false, requiresLocation: false, minRarity: nil, timeWindow: "weekly", reward: .streakFreeze(2)),
        ChallengeTemplate(title: "Architectural Eye", description: "Spot a 47 in architecture this week", category: "architectural", requiresVerified: false, requiresLocation: false, minRarity: nil, timeWindow: "weekly", reward: .streakFreeze(1)),
        ChallengeTemplate(title: "Triple Threat", description: "Capture 3 sightings this week", category: nil, requiresVerified: false, requiresLocation: false, minRarity: nil, timeWindow: "weekly", reward: .streakFreeze(2)),
        ChallengeTemplate(title: "Explorer", description: "Capture a sighting with a new location", category: nil, requiresVerified: false, requiresLocation: true, minRarity: nil, timeWindow: "weekly", reward: .streakFreeze(1)),
        ChallengeTemplate(title: "Legendary Quest", description: "Capture a Legendary sighting this week", category: nil, requiresVerified: false, requiresLocation: false, minRarity: 5, timeWindow: "weekly", reward: .streakFreeze(3)),
    ]

    /// Pick a random daily template using the date as seed for consistency.
    static func dailyForDate(_ date: Date = .now) -> ChallengeTemplate {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        let index = dayOfYear % daily.count
        return daily[index]
    }

    /// Pick a random weekly template using the week number as seed.
    static func weeklyForDate(_ date: Date = .now) -> ChallengeTemplate {
        let weekOfYear = Calendar.current.component(.weekOfYear, from: date)
        let index = weekOfYear % weekly.count
        return weekly[index]
    }
}
