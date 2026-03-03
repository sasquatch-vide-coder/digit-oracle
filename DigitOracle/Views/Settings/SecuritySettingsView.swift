import SwiftUI
import LocalAuthentication

struct SecuritySettingsView: View {
    var appLockService = AppLockService.shared

    @State private var showingNoBiometricsAlert = false

    private let timeoutOptions: [(label: String, seconds: Int)] = [
        ("Immediately", 0),
        ("After 1 minute", 60),
        ("After 5 minutes", 300),
        ("After 15 minutes", 900)
    ]

    var body: some View {
        Form {
            Section {
                Toggle("Seal the Sanctum", isOn: Binding(
                    get: { appLockService.isEnabled },
                    set: { newValue in
                        if newValue {
                            enableLock()
                        } else {
                            appLockService.isEnabled = false
                        }
                    }
                ))
            } footer: {
                Text("When sealed, the Oracle shall demand proof of identity before revealing thy visions.")
            }

            if appLockService.isEnabled {
                Section {
                    Picker("Seal After", selection: Binding(
                        get: { appLockService.timeoutSeconds },
                        set: { appLockService.timeoutSeconds = $0 }
                    )) {
                        ForEach(timeoutOptions, id: \.seconds) { option in
                            Text(option.label).tag(option.seconds)
                        }
                    }
                } footer: {
                    Text("How long the Sanctum remains unsealed after leaving the Oracle.")
                }
            }
        }
        .navigationTitle("Secret Combination")
        .navigationBarTitleDisplayMode(.inline)
        .alert("No Passcode Set", isPresented: $showingNoBiometricsAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Set a device passcode in iOS Settings to seal the Sanctum.")
        }
    }

    private func enableLock() {
        guard AppLockService.canUseBiometrics() else {
            showingNoBiometricsAlert = true
            return
        }

        Task {
            let authenticated = await appLockService.authenticate()
            await MainActor.run {
                if authenticated {
                    appLockService.isEnabled = true
                }
            }
        }
    }
}
