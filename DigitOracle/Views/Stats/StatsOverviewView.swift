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
                heroCard
                quickStats
                streakCard

                if sightings.contains(where: { $0.coordinate != nil }) {
                    NavigationLink(value: StatsDestination.heatmap) {
                        mapPreviewCard
                    }
                    .buttonStyle(.plain)
                }

                NavigationLink(value: StatsDestination.challenges) {
                    challengesCard
                }
                .buttonStyle(.plain)

                NavigationLink(value: StatsDestination.achievements) {
                    achievementsCard
                }
                .buttonStyle(.plain)

                NavigationLink(value: StatsDestination.vessels) {
                    vesselsCard
                }
                .buttonStyle(.plain)

                NavigationLink(value: StatsDestination.devotions) {
                    devotionsCard
                }
                .buttonStyle(.plain)

                NavigationLink(value: StatsDestination.memories) {
                    memoriesCard
                }
                .buttonStyle(.plain)

                NavigationLink(value: StatsDestination.wrapped) {
                    wrappedCard
                }
                .buttonStyle(.plain)

                NavigationLink(value: StatsDestination.digest) {
                    digestCard
                }
                .buttonStyle(.plain)

                NavigationLink(value: StatsDestination.calendar) {
                    calendarPreview
                }
                .buttonStyle(.plain)

            }
            .padding()
        }
        .navigationTitle("Profile")
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

    // MARK: - Hero Card

    private var heroCard: some View {
        VStack(spacing: 8) {
            if let name = profiles.first?.displayName {
                Text(name)
                    .font(.oracleHeading(size: 22))
                    .foregroundColor(.goldPrimary)
            }
            Text("\(stats.totalCount)")
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

    // MARK: - Quick Stats Grid

    private var quickStats: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(title: "Revealed", value: "\(stats.verifiedCount)", icon: "sparkles", color: .goldPrimary)
            StatCard(title: "Favorites", value: "\(stats.favoriteCount)", icon: "heart.fill", color: .red)
            StatCard(title: "Locations", value: "\(stats.citiesVisited)", icon: "mappin.circle.fill", color: .goldPrimary)
            StatCard(title: "Avg / Week", value: String(format: "%.1f", stats.averagePerWeek), icon: "chart.line.uptrend.xyaxis", color: .goldPrimary)
        }
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        HStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("\(stats.currentStreak)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.orange)
                Text("Current Streak")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()
                .frame(height: 50)

            VStack(spacing: 4) {
                Text("\(stats.longestStreak)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.orange)
                Text("Longest Streak")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let best = stats.bestMonth {
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
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Calendar Preview

    private var calendarPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Sacred Calendar", systemImage: "calendar")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            MiniCalendarGrid(sightingsByDay: stats.sightingsByDay)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Vessels Card

    private var vesselsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Vessels", systemImage: "chart.pie.fill")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if stats.categoryBreakdown.isEmpty {
                Text("No visions yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(stats.categoryBreakdown.prefix(4), id: \.category) { item in
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
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Devotions Card

    private var devotionsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Devotions", systemImage: "chart.bar.fill")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if stats.rarityBreakdown.isEmpty {
                Text("No visions yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(stats.rarityBreakdown.prefix(4), id: \.rarity) { item in
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
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Wrapped Card

    private var wrappedCard: some View {
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
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Memories Card

    private var memoriesCard: some View {
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
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Digest Card

    private var digestCard: some View {
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
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Challenges Card

    private var challengesCard: some View {
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
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Achievements Card

    private var achievementsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Rites of Passage", systemImage: "trophy.fill")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("Track thy progress and unlock sacred badges")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Map Preview

    private var mapPreviewCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Vision Map", systemImage: "map.fill")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("\(stats.citiesVisited) locations")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
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
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
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
