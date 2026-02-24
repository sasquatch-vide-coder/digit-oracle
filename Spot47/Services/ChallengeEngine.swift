import Foundation
import SwiftData

@Observable
class ChallengeEngine {
    var completedChallenge: Challenge?

    /// Ensure today's daily and this week's weekly challenges exist.
    func ensureChallenges(context: ModelContext) {
        let challenges = (try? context.fetch(FetchDescriptor<Challenge>())) ?? []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        // Daily challenge
        let hasDaily = challenges.contains { c in
            c.challengeType == "daily" && calendar.isDate(c.startDate, inSameDayAs: today)
        }
        if !hasDaily {
            let template = ChallengeTemplates.dailyForDate()
            guard let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: today) else { return }
            let challenge = Challenge(
                title: template.title,
                descriptionText: template.description,
                challengeType: "daily",
                category: template.category,
                startDate: today,
                endDate: endOfDay
            )
            context.insert(challenge)
        }

        // Weekly challenge
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else { return }
        let hasWeekly = challenges.contains { c in
            c.challengeType == "weekly" && c.startDate >= startOfWeek && c.startDate < startOfWeek.addingTimeInterval(7 * 86400)
        }
        if !hasWeekly {
            let template = ChallengeTemplates.weeklyForDate()
            guard let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek),
                  let endOfWeekDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endOfWeek) else { return }
            let challenge = Challenge(
                title: template.title,
                descriptionText: template.description,
                challengeType: "weekly",
                category: template.category,
                startDate: startOfWeek,
                endDate: endOfWeekDay
            )
            context.insert(challenge)
        }

        try? context.save()
    }

    /// Check if a new sighting completes any active challenges.
    func checkCompletion(sighting: Sighting, context: ModelContext) {
        let challenges = (try? context.fetch(FetchDescriptor<Challenge>())) ?? []

        completedChallenge = nil

        for challenge in challenges where challenge.isActive {
            if matches(sighting: sighting, challenge: challenge) {
                challenge.isCompleted = true
                challenge.completedSightingID = sighting.id

                // Award streak freezes
                let template = findTemplate(for: challenge)
                if case .streakFreeze(let count) = template?.reward {
                    awardStreakFreezes(count: count, context: context)
                }

                completedChallenge = challenge
                break  // Only complete one challenge per sighting
            }
        }

        try? context.save()
    }

    /// Consume a streak freeze if available. Returns true if freeze was used.
    func consumeStreakFreeze(context: ModelContext) -> Bool {
        let profiles = (try? context.fetch(FetchDescriptor<UserProfile>())) ?? []
        guard let profile = profiles.first, profile.streakFreezes > 0 else { return false }
        profile.streakFreezes -= 1
        try? context.save()
        return true
    }

    // MARK: - Private

    private func matches(sighting: Sighting, challenge: Challenge) -> Bool {
        // Category match
        if let requiredCategory = challenge.category {
            guard sighting.category == requiredCategory else { return false }
        }

        // Find template for additional requirements
        if let template = findTemplate(for: challenge) {
            if template.requiresVerified && !sighting.contains47 { return false }
            if template.requiresLocation && sighting.locationName == nil { return false }
            if let minRarity = template.minRarity, sighting.rarityScore < minRarity { return false }
        }

        return true
    }

    private func findTemplate(for challenge: Challenge) -> ChallengeTemplate? {
        let allTemplates = ChallengeTemplates.daily + ChallengeTemplates.weekly
        return allTemplates.first { $0.title == challenge.title }
    }

    private func awardStreakFreezes(count: Int, context: ModelContext) {
        let profiles = (try? context.fetch(FetchDescriptor<UserProfile>())) ?? []
        let profile: UserProfile
        if let existing = profiles.first {
            profile = existing
        } else {
            profile = UserProfile(displayName: "Spotter")
            context.insert(profile)
        }
        profile.streakFreezes += count
    }
}
