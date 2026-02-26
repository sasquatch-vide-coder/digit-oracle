import SwiftUI
import SwiftData

struct ChallengeListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Challenge.startDate, order: .reverse) private var challenges: [Challenge]
    @State private var challengeEngine = ChallengeEngine()

    private var activeChallenges: [Challenge] {
        challenges.filter(\.isActive)
    }

    private var completedChallenges: [Challenge] {
        challenges.filter(\.isCompleted)
    }

    private var expiredChallenges: [Challenge] {
        challenges.filter(\.isExpired)
    }

    var body: some View {
        List {
            if !activeChallenges.isEmpty {
                Section("Active") {
                    ForEach(activeChallenges) { challenge in
                        ChallengeRow(challenge: challenge)
                    }
                }
            }

            if !completedChallenges.isEmpty {
                Section("Completed") {
                    ForEach(completedChallenges) { challenge in
                        ChallengeRow(challenge: challenge)
                    }
                }
            }

            if !expiredChallenges.isEmpty {
                Section("Expired") {
                    ForEach(expiredChallenges) { challenge in
                        ChallengeRow(challenge: challenge)
                    }
                }
            }

            if challenges.isEmpty {
                ContentUnavailableView(
                    "No Challenges Yet",
                    systemImage: "target",
                    description: Text("Challenges appear automatically each day and week.")
                )
            }
        }
        .navigationTitle("Challenges")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            challengeEngine.ensureChallenges(context: modelContext)
        }
    }
}

// MARK: - Challenge Row

struct ChallengeRow: View {
    let challenge: Challenge

    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(challenge.title)
                        .font(.subheadline.bold())

                    if challenge.challengeType == "weekly" {
                        Text("WEEKLY")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.2), in: Capsule())
                            .foregroundColor(.purple)
                    }
                }

                Text(challenge.descriptionText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                if challenge.isActive {
                    Text(timeRemaining)
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }

            Spacer()

            if let template = findTemplate() {
                if case .streakFreeze(let count) = template.reward {
                    HStack(spacing: 2) {
                        Image(systemName: "snowflake")
                            .font(.caption2)
                        Text("+\(count)")
                            .font(.caption2.bold())
                    }
                    .foregroundColor(.cyan)
                }
            }
        }
        .opacity(challenge.isExpired ? 0.5 : 1.0)
    }

    private var statusColor: Color {
        if challenge.isCompleted { return .green }
        if challenge.isExpired { return .secondary }
        return .orange
    }

    private var statusIcon: String {
        if challenge.isCompleted { return "checkmark.circle.fill" }
        if challenge.isExpired { return "xmark.circle" }
        return "target"
    }

    private var timeRemaining: String {
        let remaining = challenge.endDate.timeIntervalSince(.now)
        if remaining <= 0 { return "Expired" }

        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60

        if hours >= 24 {
            let days = hours / 24
            return "\(days)d \(hours % 24)h remaining"
        }
        return "\(hours)h \(minutes)m remaining"
    }

    private func findTemplate() -> ChallengeTemplate? {
        let all = ChallengeTemplates.daily + ChallengeTemplates.weekly
        return all.first { $0.title == challenge.title }
    }
}

// MARK: - Challenge Celebration

struct ChallengeCelebrationView: View {
    let challenge: Challenge
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.3
    @State private var opacity: CGFloat = 0

    private var template: ChallengeTemplate? {
        let all = ChallengeTemplates.daily + ChallengeTemplates.weekly
        return all.first { $0.title == challenge.title }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 16) {
                Text("Challenge Complete!")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 100, height: 100)
                    Image(systemName: "target")
                        .font(.system(size: 44))
                        .foregroundColor(.orange)
                }

                Text(challenge.title)
                    .font(.title2.bold())

                Text(challenge.descriptionText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if let template, case .streakFreeze(let count) = template.reward {
                    HStack(spacing: 4) {
                        Image(systemName: "snowflake")
                        Text("+\(count) streak freeze\(count == 1 ? "" : "s") earned!")
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(.cyan)
                }

                Button("Nice!") { onDismiss() }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
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
