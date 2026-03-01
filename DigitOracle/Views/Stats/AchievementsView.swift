import SwiftUI
import SwiftData

struct AchievementsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Achievement.key) private var achievements: [Achievement]
    @State private var selectedAchievement: Achievement?

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    private var unlockedCount: Int {
        achievements.filter(\.isUnlocked).count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary
                Text("\(unlockedCount) / \(achievements.count)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.accentColor)
                Text("Rites of Passage Unlocked")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // Grid
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(achievements) { achievement in
                        Button {
                            selectedAchievement = achievement
                        } label: {
                            AchievementBadge(achievement: achievement)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Rites of Passage")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedAchievement) { achievement in
            AchievementDetailSheet(achievement: achievement)
        }
        .task {
            AchievementEngine.syncDefinitions(context: modelContext)
        }
    }
}

// MARK: - Detail Sheet

struct AchievementDetailSheet: View {
    let achievement: Achievement
    @Environment(\.dismiss) private var dismiss

    private var definition: AchievementDef? {
        AchievementDefinitions.definition(for: achievement.key)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Large icon in gold circle
                ZStack {
                    Circle()
                        .fill(achievement.isUnlocked ? Color.goldPrimary.opacity(0.2) : Color.secondary.opacity(0.1))
                        .frame(width: 120, height: 120)

                    Circle()
                        .stroke(achievement.isUnlocked ? Color.goldPrimary : Color.secondary.opacity(0.3), lineWidth: 3)
                        .frame(width: 120, height: 120)

                    Image(systemName: achievement.iconName)
                        .font(.system(size: 48))
                        .foregroundColor(achievement.isUnlocked ? .goldPrimary : .secondary)
                }
                .padding(.top, 32)

                // Name
                Text(achievement.name)
                    .font(.oracleProphecy(size: 24))
                    .foregroundColor(achievement.isUnlocked ? .goldPrimary : .textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                // Description
                Text(achievement.descriptionText)
                    .font(.oracleBody())
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 32)

                // Progress or unlock date
                if achievement.isUnlocked {
                    Label {
                        Text("Unlocked \(achievement.unlockedAt?.formatted(date: .long, time: .omitted) ?? "")")
                            .font(.subheadline)
                    } icon: {
                        Image(systemName: "checkmark.seal.fill")
                    }
                    .foregroundColor(.goldPrimary)
                } else if let def = definition, def.target > 1 {
                    VStack(spacing: 8) {
                        ProgressView(value: achievement.progress)
                            .tint(.goldPrimary)
                            .padding(.horizontal, 48)

                        Text("\(Int(achievement.progress * Double(def.target))) / \(def.target)")
                            .font(.subheadline.bold())
                            .foregroundColor(.textSecondary)
                    }
                } else {
                    Text("Not yet unlocked")
                        .font(.subheadline)
                        .foregroundColor(.textDimmed)
                }

                Button("Dismiss") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.goldPrimary)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .frame(maxWidth: .infinity)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Badge

struct AchievementBadge: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.1))
                    .frame(width: 64, height: 64)

                if achievement.isUnlocked {
                    Image(systemName: achievement.iconName)
                        .font(.title2)
                        .foregroundColor(.accentColor)
                } else {
                    ZStack {
                        Image(systemName: achievement.iconName)
                            .font(.title2)
                            .foregroundStyle(.secondary.opacity(0.4))

                        // Progress ring
                        if achievement.progress > 0 {
                            Circle()
                                .trim(from: 0, to: achievement.progress)
                                .stroke(Color.accentColor.opacity(0.5), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .frame(width: 64, height: 64)
                                .rotationEffect(.degrees(-90))
                        }
                    }
                }
            }

            Text(achievement.name)
                .font(.caption2.bold())
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundStyle(achievement.isUnlocked ? .primary : .secondary)

            if achievement.isUnlocked {
                Text(achievement.unlockedAt?.formatted(date: .abbreviated, time: .omitted) ?? "")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            } else {
                Text(achievement.descriptionText)
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Celebration Overlay

struct AchievementCelebrationView: View {
    let achievement: Achievement
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.3
    @State private var opacity: CGFloat = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 16) {
                Text("Rite of Passage Unlocked!")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.2))
                        .frame(width: 100, height: 100)

                    Image(systemName: achievement.iconName)
                        .font(.system(size: 44))
                        .foregroundColor(.accentColor)
                }

                Text(achievement.name)
                    .font(.title2.bold())

                Text(achievement.descriptionText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button("Awesome!") { onDismiss() }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 8)
            }
            .padding(32)
            .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 24))
            .padding(40)
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
        .sensoryFeedback(.success, trigger: scale)
    }
}
