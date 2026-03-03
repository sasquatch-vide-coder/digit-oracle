import SwiftUI
import LocalAuthentication

struct AppLockView: View {
    var appLockService: AppLockService

    @State private var isAuthenticating = false

    var body: some View {
        ZStack {
            Color.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.goldPrimary)

                Text("The Sanctum is Sealed")
                    .font(.oracleHeading())
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Verify thy identity to enter")
                    .font(.oracleBody())
                    .foregroundColor(.textSecondary)

                Spacer()

                Button {
                    tryAuthenticate()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: biometricIcon)
                        Text("Unseal the Sanctum")
                    }
                }
                .buttonStyle(OraclePrimaryButtonStyle())
                .disabled(isAuthenticating)

                Spacer()
                    .frame(height: 60)
            }
            .padding(.horizontal, 32)
        }
        .onAppear {
            tryAuthenticate()
        }
    }

    private var biometricIcon: String {
        switch AppLockService.biometricType() {
        case .faceID:
            "faceid"
        case .touchID:
            "touchid"
        case .opticID:
            "opticid"
        default:
            "lock.open"
        }
    }

    private func tryAuthenticate() {
        guard !isAuthenticating else { return }
        isAuthenticating = true

        Task {
            _ = await appLockService.authenticate()
            await MainActor.run {
                isAuthenticating = false
            }
        }
    }
}
