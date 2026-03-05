import SwiftUI
import GameKit

struct LeaderboardView: View {
    enum LeaderboardType: String, CaseIterable {
        case totalSightings = "Total Visions"
        case longestStreak = "Longest Streak"

        var leaderboardID: String {
            switch self {
            case .totalSightings: Constants.GameCenter.leaderboardTotalSightings
            case .longestStreak: Constants.GameCenter.leaderboardLongestStreak
            }
        }
    }

    enum PlayerScope: String, CaseIterable {
        case global = "Global"
        case friends = "Friends"

        var gkScope: GKLeaderboard.PlayerScope {
            switch self {
            case .global: .global
            case .friends: .friendsOnly
            }
        }
    }

    @State private var selectedType: LeaderboardType = .totalSightings
    @State private var selectedScope: PlayerScope = .global
    @State private var entries: [GKLeaderboard.Entry] = []
    @State private var localPlayerEntry: GKLeaderboard.Entry?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            Picker("Leaderboard", selection: $selectedType) {
                ForEach(LeaderboardType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            Picker("Scope", selection: $selectedScope) {
                ForEach(PlayerScope.allCases, id: \.self) { scope in
                    Text(scope.rawValue).tag(scope)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            Group {
                if !GameCenterService.shared.isAuthenticated {
                    ContentUnavailableView {
                        Label("Game Center Required", systemImage: "person.crop.circle.badge.questionmark")
                    } description: {
                        Text("Sign in to Game Center to view the sacred rankings.")
                    }
                } else if isLoading {
                    ProgressView("Consulting the cosmic rankings...")
                        .frame(maxHeight: .infinity)
                } else if let errorMessage {
                    ContentUnavailableView {
                        Label("Unable to Load", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(errorMessage)
                    }
                } else if entries.isEmpty {
                    ContentUnavailableView {
                        Label("No Rankings Yet", systemImage: "list.number")
                    } description: {
                        Text("The sacred rankings await their first entries.")
                    }
                } else {
                    leaderboardList
                }
            }
        }
        .navigationTitle("Sacred Rankings")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: "\(selectedType.rawValue)-\(selectedScope.rawValue)") {
            await loadEntries()
        }
    }

    private var leaderboardList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(entries, id: \.rank) { entry in
                    leaderboardRow(entry: entry, isLocal: entry.player == GKLocalPlayer.local)
                }
            }
            .padding(.horizontal)

            if let localEntry = localPlayerEntry,
               !entries.contains(where: { $0.player == GKLocalPlayer.local }) {
                VStack(spacing: 4) {
                    Divider().padding(.horizontal)
                    Text("Thy Standing")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    leaderboardRow(entry: localEntry, isLocal: true)
                        .padding(.horizontal)
                }
            }
        }
    }

    private func leaderboardRow(entry: GKLeaderboard.Entry, isLocal: Bool) -> some View {
        HStack(spacing: 12) {
            Text("#\(entry.rank)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(rankColor(entry.rank))
                .frame(width: 44, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.player.displayName)
                    .font(.subheadline.bold())
                    .lineLimit(1)
            }

            Spacer()

            Text("\(entry.formattedScore)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(Color.goldPrimary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            isLocal ? Color.goldPrimary.opacity(0.1) : Color.clear,
            in: RoundedRectangle(cornerRadius: 10)
        )
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: .yellow
        case 2: .gray
        case 3: .orange
        default: .secondary
        }
    }

    private func loadEntries() async {
        guard GameCenterService.shared.isAuthenticated else { return }

        isLoading = true
        errorMessage = nil

        do {
            let leaderboards = try await GKLeaderboard.loadLeaderboards(IDs: [selectedType.leaderboardID])
            guard let leaderboard = leaderboards.first else {
                entries = []
                isLoading = false
                return
            }

            let (local, fetchedEntries, _) = try await leaderboard.loadEntries(
                for: selectedScope.gkScope,
                timeScope: .allTime,
                range: NSRange(location: 1, length: 100)
            )

            localPlayerEntry = local
            entries = fetchedEntries
        } catch {
            errorMessage = "The Oracle could not reach the rankings."
            entries = []
        }

        isLoading = false
    }
}
