import SwiftUI
import Photos

struct OnboardingView: View {
    @State private var currentScreen = 0
    @State private var sacredNumberText = ""
    @State private var service = TrackedNumberService.shared
    @State private var showError = false
    @State private var showingScanner = false
    @State private var hasScanned = false

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()

            switch currentScreen {
            case 0:
                awakeningScreen
                    .transition(.opacity.animation(.easeInOut(duration: 0.8)))
            case 1:
                explanationScreen
                    .transition(.opacity.animation(.easeInOut(duration: 0.8)))
            case 2:
                choosingScreen
                    .transition(.opacity.animation(.easeInOut(duration: 0.8)))
            case 3:
                confirmationScreen
                    .transition(.opacity.animation(.easeInOut(duration: 0.8)))
            case 4:
                seekingScreen
                    .transition(.opacity.animation(.easeInOut(duration: 0.8)))
            default:
                EmptyView()
            }
        }
    }

    // MARK: - Screen 1: The Awakening

    private var awakeningScreen: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("The Oracle awakens.")
                .font(.oracleHeading(size: 32))
                .foregroundColor(.goldPrimary)
                .multilineTextAlignment(.center)

            Text("It senses a seeker of hidden truths.")
                .font(.oracleBody(size: 18))
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            Button("Approach the Oracle") {
                withAnimation(.easeInOut(duration: 0.8)) {
                    currentScreen = 1
                }
            }
            .buttonStyle(OraclePrimaryButtonStyle())
            .padding(.bottom, 60)
        }
        .padding()
    }

    // MARK: - Screen 2: The Explanation

    private var explanationScreen: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("The Oracle possesses the sight to peer into thy captured visions and reveal the numbers hidden within.")
                .font(.oracleProphecy(size: 20))
                .foregroundColor(.goldPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Text("Grant the Oracle access to thy visions, and it shall seek the sacred digits thou dost revere.")
                .font(.oracleBody(size: 16))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            Button("Grant Access") {
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { _ in
                    DispatchQueue.main.async {
                        withAnimation(.easeInOut(duration: 0.8)) {
                            currentScreen = 2
                        }
                    }
                }
            }
            .buttonStyle(OraclePrimaryButtonStyle())
            .padding(.bottom, 60)
        }
        .padding()
    }

    // MARK: - Screen 3: The Choosing

    private var choosingScreen: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Speak unto the Oracle thy sacred number.")
                .font(.oracleProphecy(size: 20))
                .foregroundColor(.goldPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Text("The digits that follow thee. The number that calls to thee from the ether.")
                .font(.oracleBody(size: 16))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // Sacred number input field
            TextField("", text: $sacredNumberText)
                .font(.sacredNumber(size: 56))
                .foregroundColor(.goldPrimary)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .frame(maxWidth: 200)
                .padding(.vertical, 16)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.goldPrimary, lineWidth: 2)
                )

            Text("Choose wisely. This shall be thy first covenant with the Oracle.")
                .font(.oracleCaption)
                .foregroundColor(.textDimmed)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if showError {
                Text("Enter a valid number (1\u{2013}99999).")
                    .font(.oracleCaption)
                    .foregroundColor(.errorRuby)
            }

            Spacer()

            Button("Seal the Covenant") {
                guard let number = Int(sacredNumberText), number >= 1, number <= 99999 else {
                    showError = true
                    return
                }
                showError = false
                service.addNumber(number)
                withAnimation(.easeInOut(duration: 0.8)) {
                    currentScreen = 3
                }
            }
            .buttonStyle(OraclePrimaryButtonStyle())
            .disabled(sacredNumberText.isEmpty)
            .opacity(sacredNumberText.isEmpty ? 0.5 : 1.0)
            .padding(.bottom, 60)
        }
        .padding()
    }

    // MARK: - Screen 4: Confirmation

    private var confirmationScreen: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("It is done.")
                .font(.oracleHeading(size: 36))
                .foregroundColor(.goldPrimary)
                .shadow(color: .goldPrimary.opacity(0.5), radius: 12)

            if let number = service.trackedNumbers.first {
                Text("\(number)")
                    .font(.sacredNumber(size: 72))
                    .foregroundColor(.goldLight)
                    .shadow(color: .goldPrimary.opacity(0.6), radius: 16)
            }

            Text("The Oracle shall seek thy sacred number across all thy visions. When the sacred digits reveal themselves, thou shalt be the first to know.")
                .font(.oracleBody(size: 16))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            Button("Continue") {
                withAnimation(.easeInOut(duration: 0.8)) {
                    currentScreen = 4
                }
            }
            .buttonStyle(OraclePrimaryButtonStyle())
            .padding(.bottom, 60)
        }
        .padding()
    }

    // MARK: - Screen 5: The Seeking

    private var seekingScreen: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Dost thou already possess visions of thy sacred number?")
                .font(.oracleProphecy(size: 20))
                .foregroundColor(.goldPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Text("The Oracle can peer into thy archive and seek them out.")
                .font(.oracleBody(size: 16))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            Button("Peer into the Archive") {
                showingScanner = true
            }
            .buttonStyle(OraclePrimaryButtonStyle())

            Button {
                service.hasOfferedLibraryScan = true
                service.hasCompletedOnboarding = true
            } label: {
                Text(hasScanned ? "Continue" : "Skip")
                    .font(.oracleUI())
                    .foregroundColor(.goldPrimary)
            }
            .padding(.bottom, 60)
        }
        .padding()
        .sheet(isPresented: $showingScanner, onDismiss: {
            hasScanned = true
            service.hasOfferedLibraryScan = true
            service.hasCompletedOnboarding = true
        }) {
            LibraryScannerView(autoStart: true)
        }
    }
}
