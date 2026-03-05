import SwiftUI
import SwiftData

struct StatsOverviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Sighting.captureDate, order: .reverse) private var sightings: [Sighting]
    @Query(sort: \Challenge.startDate, order: .reverse) private var challenges: [Challenge]
    @Query private var profiles: [UserProfile]
    @State private var challengeEngine = ChallengeEngine()

    private var stats: SightingStats {
        StatsCalculator.calculate(from: sightings)
    }

    private var activeChallenges: [Challenge] {
        challenges.filter(\.isActive)
    }

    private var streakFreezes: Int {
        profiles.first?.streakFreezes ?? 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HeroCard(displayName: profiles.first?.displayName, totalCount: stats.totalCount)
                QuickStatsGrid(stats: stats)
                StreakCard(currentStreak: stats.currentStreak, longestStreak: stats.longestStreak, bestMonth: stats.bestMonth)

                if sightings.contains(where: { $0.coordinate != nil }) {
                    NavigationLink(value: StatsDestination.heatmap) {
                        MapPreviewCard(citiesVisited: stats.citiesVisited)
                    }
                    .buttonStyle(.plain)
                }

                NavigationLink(value: StatsDestination.challenges) {
                    ChallengesCard(activeChallenges: activeChallenges, streakFreezes: streakFreezes)
                }
                .buttonStyle(.plain)

                NavigationLink(value: StatsDestination.leaderboard) {
                    LeaderboardCard()
                }
                .buttonStyle(.plain)

                NavigationLink(value: StatsDestination.achievements) {
                    AchievementsCard()
                }
                .buttonStyle(.plain)

                NavigationLink(value: StatsDestination.vessels) {
                    VesselsCard(categoryBreakdown: stats.categoryBreakdown)
                }
                .buttonStyle(.plain)

                NavigationLink(value: StatsDestination.devotions) {
                    DevotionsCard(rarityBreakdown: stats.rarityBreakdown)
                }
                .buttonStyle(.plain)

                NavigationLink(value: StatsDestination.memories) {
                    MemoriesCard()
                }
                .buttonStyle(.plain)

                NavigationLink(value: StatsDestination.wrapped) {
                    WrappedCard()
                }
                .buttonStyle(.plain)

                NavigationLink(value: StatsDestination.digest) {
                    DigestCard()
                }
                .buttonStyle(.plain)

                NavigationLink(value: StatsDestination.calendar) {
                    CalendarPreviewCard(sightingsByDay: stats.sightingsByDay)
                }
                .buttonStyle(.plain)

            }
            .padding()
        }
        .navigationTitle("Oracle's Eye")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(value: StatsDestination.settings) {
                    Image(systemName: "gearshape")
                }
            }
        }
        .onAppear {
            challengeEngine.ensureChallenges(context: modelContext)
        }
        .navigationDestination(for: StatsDestination.self) { dest in
            switch dest {
            case .calendar:
                CalendarHeatmapView()
            case .vessels:
                VesselsView()
            case .devotions:
                DevotionsView()
            case .heatmap:
                HeatmapView()
            case .achievements:
                AchievementsView()
            case .challenges:
                ChallengeListView()
            case .leaderboard:
                LeaderboardView()
            case .wrapped:
                WrappedView()
            case .memories:
                OnThisDayView()
            case .digest:
                MonthlyDigestView()
            case .settings:
                SettingsView()
            }
        }
    }

}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .oracleCard(cornerRadius: 12)
    }
}

// MARK: - Stats Navigation

enum StatsDestination: Hashable {
    case calendar
    case vessels
    case devotions
    case heatmap
    case achievements
    case challenges
    case leaderboard
    case wrapped
    case memories
    case digest
    case settings
}

// MARK: - Mini Calendar Grid (last 7 weeks)

struct MiniCalendarGrid: View {
    let sightingsByDay: [Date: Int]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 7)
    private let calendar = Calendar.current

    private var last49Days: [Date] {
        let today = calendar.startOfDay(for: .now)
        return (0..<49).reversed().compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 3) {
            ForEach(last49Days, id: \.self) { day in
                let count = sightingsByDay[day] ?? 0
                RoundedRectangle(cornerRadius: 2)
                    .fill(intensityColor(for: count))
                    .frame(height: 14)
            }
        }
    }

    private func intensityColor(for count: Int) -> Color {
        switch count {
        case 0: return Color.secondary.opacity(0.15)
        case 1: return Color.goldPrimary.opacity(0.35)
        case 2: return Color.goldPrimary.opacity(0.55)
        case 3: return Color.goldPrimary.opacity(0.75)
        default: return Color.goldPrimary
        }
    }
}
