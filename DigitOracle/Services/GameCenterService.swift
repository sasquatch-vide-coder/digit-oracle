import GameKit
import SwiftData

@Observable
@MainActor
final class GameCenterService {
    static let shared = GameCenterService()

    var isAuthenticated = false
    var localPlayerDisplayName: String?

    private var hasBackfilled = false

    private init() {}

    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] _, error in
            Task { @MainActor in
                guard let self else { return }
                self.isAuthenticated = GKLocalPlayer.local.isAuthenticated
                if self.isAuthenticated {
                    self.localPlayerDisplayName = GKLocalPlayer.local.displayName
                    if !self.hasBackfilled {
                        self.hasBackfilled = true
                    }
                }
            }
        }
    }

    func backfillScoresAndAchievements(context: ModelContext) {
        guard isAuthenticated else { return }

        let sightings = (try? context.fetch(FetchDescriptor<Sighting>())) ?? []
        let albums = (try? context.fetch(FetchDescriptor<Album>())) ?? []
        let achievements = (try? context.fetch(FetchDescriptor<Achievement>())) ?? []

        let totalSightings = sightings.count
        let longestStreak = StatsCalculator.longestStreak(from: sightings)

        submitScores(totalSightings: totalSightings, longestStreak: longestStreak)
        reportAchievements(achievements)
    }

    func submitScores(totalSightings: Int, longestStreak: Int) {
        guard isAuthenticated else { return }

        Task {
            do {
                try await GKLeaderboard.submitScore(
                    totalSightings,
                    context: 0,
                    player: GKLocalPlayer.local,
                    leaderboardIDs: [Constants.GameCenter.leaderboardTotalSightings]
                )
                try await GKLeaderboard.submitScore(
                    longestStreak,
                    context: 0,
                    player: GKLocalPlayer.local,
                    leaderboardIDs: [Constants.GameCenter.leaderboardLongestStreak]
                )
            } catch {
                // Game Center submission failed silently — non-critical
            }
        }
    }

    func reportAchievements(_ achievements: [Achievement]) {
        guard isAuthenticated else { return }

        let gcAchievements = achievements.map { achievement -> GKAchievement in
            let gcID = Constants.GameCenter.achievementPrefix + achievement.key
            let gka = GKAchievement(identifier: gcID)
            gka.percentComplete = achievement.isUnlocked ? 100.0 : achievement.progress * 100.0
            gka.showsCompletionBanner = false
            return gka
        }

        guard !gcAchievements.isEmpty else { return }

        Task {
            do {
                try await GKAchievement.report(gcAchievements)
            } catch {
                // Game Center achievement report failed silently — non-critical
            }
        }
    }
}
