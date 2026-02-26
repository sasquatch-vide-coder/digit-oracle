import SwiftUI

struct OnboardingScanOfferView: View {
    @State private var service = TrackedNumberService.shared
    @State private var showingScanner = false
    @State private var hasScanned = false

    private let accentGradient = LinearGradient(
        colors: [.blue, .cyan, .teal],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: "photo.stack")
                    .font(.system(size: 48))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .padding(.horizontal, 20)
            .background(
                accentGradient
                    .clipShape(RoundedRectangle(cornerRadius: 24))
            )
            .padding(.horizontal)

            Text("Find Numbers in Your Photos")
                .font(.system(size: 24, weight: .bold, design: .rounded))

            Text("Already have photos with your tracked numbers? Scan your library to import them automatically.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                showingScanner = true
            } label: {
                Label("Scan Library", systemImage: "magnifyingglass")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(accentGradient)
                    )
                    .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
            }
            .padding(.horizontal, 40)

            Button {
                service.hasOfferedLibraryScan = true
            } label: {
                Text(hasScanned ? "Continue" : "Skip")
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
            }

            Spacer()
        }
        .sheet(isPresented: $showingScanner, onDismiss: {
            hasScanned = true
        }) {
            LibraryScannerView()
        }
    }
}
