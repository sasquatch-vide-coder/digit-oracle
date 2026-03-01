import SwiftUI

struct NumberSelectionView: View {
    let isOnboarding: Bool

    @State private var service = TrackedNumberService.shared
    @State private var customNumberText = ""
    @State private var showError = false
    @State private var headerVisible = false
    @State private var gridVisible = false
    @State private var tappedNumber: Int?
    @Environment(\.dismiss) private var dismiss

    private let accentGradient = LinearGradient.goldShimmer

    var body: some View {
        let content = ScrollView {
            VStack(spacing: 28) {
                if isOnboarding {
                    headerSection
                }

                suggestedSection
                customEntrySection
                currentSelectionsSection

                if isOnboarding {
                    startButton
                        .padding(.top, 8)
                }
            }
            .padding()
        }
        .navigationTitle(isOnboarding ? "" : "Sacred Numbers")
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.selection, trigger: tappedNumber)

        if isOnboarding {
            NavigationStack {
                content
            }
        } else {
            content
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.goldDark.opacity(0.3))
                    .frame(width: 100, height: 100)

                Image(systemName: "number.square.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.goldPrimary)
            }

            Text("Which sacred numbers\ndost thou seek?")
                .font(.oracleHeading)
                .foregroundStyle(Color.goldLight)
                .multilineTextAlignment(.center)

            Text("Speak thy sacred numbers unto the Oracle.\nThou may alter them at any time.")
                .font(.oracleBody)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
        .background(
            Color.backgroundSecondary
                .clipShape(RoundedRectangle(cornerRadius: 24))
        )
        .opacity(headerVisible ? 1 : 0)
        .offset(y: headerVisible ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                headerVisible = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                gridVisible = true
            }
        }
    }

    // MARK: - Suggested Numbers

    private var suggestedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Suggested", systemImage: "sparkles")
                .font(.headline)
                .foregroundStyle(.primary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                ForEach(Constants.TrackedNumbers.suggestedNumbers, id: \.self) { number in
                    let isSelected = service.trackedNumbers.contains(number)
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            if isSelected {
                                service.removeNumber(number)
                            } else {
                                service.addNumber(number)
                            }
                            tappedNumber = number
                        }
                    } label: {
                        Text(String(number))
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                Group {
                                    if isSelected {
                                        accentGradient
                                    } else {
                                        Color(.secondarySystemFill)
                                    }
                                }
                            )
                            .foregroundStyle(isSelected ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: isSelected ? Color.goldPrimary.opacity(0.3) : .clear, radius: 6, y: 3)
                    }
                    .scaleEffect(tappedNumber == number ? 0.92 : 1.0)
                    .disabled(!isSelected && service.trackedNumbers.count >= Constants.TrackedNumbers.maxTrackedNumbers)
                }
            }
            .opacity(isOnboarding ? (gridVisible ? 1 : 0) : 1)
        }
    }

    // MARK: - Custom Entry

    private var customEntrySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Custom Number", systemImage: "plus.circle")
                .font(.headline)

            HStack(spacing: 10) {
                TextField("Enter a number", text: $customNumberText)
                    .keyboardType(.numberPad)
                    .padding(10)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))

                Button {
                    addCustomNumber()
                } label: {
                    Image(systemName: "plus")
                        .font(.body.bold())
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(accentGradient, in: RoundedRectangle(cornerRadius: 10))
                }
                .disabled(customNumberText.isEmpty)
                .opacity(customNumberText.isEmpty ? 0.5 : 1)
            }

            if showError {
                Text("Enter a valid number (1-99999) that isn't already tracked.")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Current Selections

    private var currentSelectionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Tracking", systemImage: "list.star")
                    .font(.headline)
                Spacer()
                Text("\(service.trackedNumbers.count)/\(Constants.TrackedNumbers.maxTrackedNumbers)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
            }

            let numbers = service.trackedNumbers
            if numbers.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "number")
                            .font(.title)
                            .foregroundStyle(.tertiary)
                        Text("No sacred numbers chosen")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 24)
                    Spacer()
                }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            } else {
                ForEach(Array(numbers.enumerated()), id: \.element) { index, number in
                    HStack(spacing: 12) {
                        Text(String(number))
                            .font(.title3.bold())
                            .foregroundStyle(index == 0 ? Color.goldPrimary : .primary)

                        if index == 0 {
                            Text("Primary")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(accentGradient, in: Capsule())
                        }

                        Spacer()

                        if numbers.count > 1 {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    service.removeNumber(number)
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 0.8).combined(with: .opacity)
                    ))
                }
            }
        }
    }

    // MARK: - Start Button

    private var startButton: some View {
        Button {
            service.hasCompletedOnboarding = true
        } label: {
            Text("Seal the Covenant")
                .font(.title3.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(service.trackedNumbers.isEmpty ? AnyShapeStyle(Color.gray.opacity(0.4)) : AnyShapeStyle(accentGradient))
                )
                .shadow(color: service.trackedNumbers.isEmpty ? .clear : Color.goldPrimary.opacity(0.3), radius: 8, y: 4)
        }
        .disabled(service.trackedNumbers.isEmpty)
    }

    // MARK: - Actions

    private func addCustomNumber() {
        guard let number = Int(customNumberText),
              number >= 1 && number <= 99999,
              !service.trackedNumbers.contains(number),
              service.trackedNumbers.count < Constants.TrackedNumbers.maxTrackedNumbers else {
            showError = true
            return
        }
        showError = false
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            service.addNumber(number)
        }
        customNumberText = ""
    }
}
