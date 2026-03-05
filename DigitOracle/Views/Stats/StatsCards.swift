import SwiftUI

// MARK: - Hero Card

struct HeroCard: View {
    let displayName: String?
    let totalCount: Int

    var body: some View {
        VStack(spacing: 8) {
            if let name = displayName {
                Text(name)
                    .font(.oracleHeading(size: 22))
                    .foregroundColor(.goldPrimary)
            }
            Text("\(totalCount)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundColor(.accentColor)
            Text("Total Visions")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Quick Stats Grid

struct QuickStatsGrid: View {
    let stats: SightingStats

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(title: "Revealed", value: "\(stats.verifiedCount)", icon: "sparkles", color: .goldPrimary)
            StatCard(title: "Consecrated", value: "\(stats.favoriteCount)", icon: "heart.fill", color: .red)
            StatCard(title: "Pilgrimages", value: "\(stats.citiesVisited)", icon: "mappin.circle.fill", color: .goldPrimary)
            StatCard(title: "Weekly Rite", value: String(format: "%.1f", stats.averagePerWeek), icon: "chart.line.uptrend.xyaxis", color: .goldPrimary)
        }
    }
}

// MARK: - Streak Card

struct StreakCard: View {
    let currentStreak: Int
    let longestStreak: Int
    let bestMonth: (month: String, count: Int)?

    var body: some View {
        HStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("\(currentStreak)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.orange)
                Text("Current Streak")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()
                .frame(height: 50)

            VStack(spacing: 4) {
                Text("\(longestStreak)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.orange)
                Text("Longest Streak")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let best = bestMonth {
                Divider()
                    .frame(height: 50)
                VStack(spacing: 4) {
                    Text("\(best.count)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.orange)
                    Text(best.month)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .oracleCard()
    }
}

// MARK: - Calendar Preview Card

struct CalendarPreviewCard: View {
    let sightingsByDay: [Date: Int]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Sacred Calendar", systemImage: "calendar")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            MiniCalendarGrid(sightingsByDay: sightingsByDay)
        }
        .oracleCard()
    }
}

// MARK: - Vessels Card

struct VesselsCard: View {
    let categoryBreakdown: [(category: String, count: Int)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Vessels", systemImage: "chart.pie.fill")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if categoryBreakdown.isEmpty {
                Text("No visions yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(categoryBreakdown.prefix(4), id: \.category) { item in
                    HStack {
                        Text(item.category)
                            .font(.subheadline)
                        Spacer()
                        Text("\(item.count)")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .oracleCard()
    }
}

// MARK: - Devotions Card

struct DevotionsCard: View {
    let rarityBreakdown: [(rarity: Int, count: Int)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Devotions", systemImage: "chart.bar.fill")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if rarityBreakdown.isEmpty {
                Text("No visions yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(rarityBreakdown.prefix(4), id: \.rarity) { item in
                    HStack {
                        Text(Constants.Rarity.label(for: item.rarity))
                            .font(.subheadline)
                        Spacer()
                        Text("\(item.count)")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .oracleCard()
    }
}

// MARK: - Wrapped Card

struct WrappedCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("The Unveiling", systemImage: "sparkles.rectangle.stack")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("Thy \(Date.now.formatted(.dateTime.month(.wide))) unveiled")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .oracleCard()
    }
}

// MARK: - Memories Card

struct MemoriesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Déjà Vu", systemImage: "clock.arrow.circlepath")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("See thy past visions from \(Date.now.formatted(.dateTime.month(.wide).day()))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .oracleCard()
    }
}

// MARK: - Digest Card

struct DigestCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("The Codex", systemImage: "doc.text.magnifyingglass")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("Sacred records by moon cycle")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .oracleCard()
    }
}

// MARK: - Challenges Card

struct ChallengesCard: View {
    let activeChallenges: [Challenge]
    let streakFreezes: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Trials", systemImage: "target")
                    .font(.headline)
                Spacer()
                if streakFreezes > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "snowflake")
                            .font(.caption)
                        Text("\(streakFreezes)")
                            .font(.caption.bold())
                    }
                    .foregroundColor(.cyan)
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if activeChallenges.isEmpty {
                Text("No active trials -- the Oracle awaits.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(activeChallenges.prefix(2)) { challenge in
                    HStack(spacing: 8) {
                        Image(systemName: "circle")
                            .font(.caption)
                            .foregroundColor(.orange)
                        VStack(alignment: .leading) {
                            Text(challenge.title)
                                .font(.caption.bold())
                            Text(challenge.descriptionText)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .oracleCard()
    }
}

// MARK: - Leaderboard Card

struct LeaderboardCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Sacred Rankings", systemImage: "list.number")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("Compete with fellow seekers")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .oracleCard()
    }
}

// MARK: - Achievements Card

struct AchievementsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Rites of Passage", systemImage: "trophy.fill")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("Walk the path and prove thy devotion")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Map Preview Card

struct MapPreviewCard: View {
    let citiesVisited: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Vision Map", systemImage: "map.fill")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("\(citiesVisited) locations")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .oracleCard()
    }
}
