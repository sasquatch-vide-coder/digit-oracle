import Foundation
import LocalAuthentication

@Observable
final class AppLockService {
    static let shared = AppLockService()

    var isLocked: Bool = false
    var showPrivacyOverlay: Bool = false

    var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Constants.AppLock.enabledKey) }
    }

    var timeoutSeconds: Int {
        didSet { UserDefaults.standard.set(timeoutSeconds, forKey: Constants.AppLock.timeoutKey) }
    }

    private var lastBackgroundTime: Date?

    private init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: Constants.AppLock.enabledKey)
        let stored = UserDefaults.standard.object(forKey: Constants.AppLock.timeoutKey) as? Int
        self.timeoutSeconds = stored ?? Constants.AppLock.defaultTimeout
    }

    func authenticate() async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return false
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Unseal the Sanctum"
            )
            if success {
                await MainActor.run {
                    isLocked = false
                    showPrivacyOverlay = false
                }
            }
            return success
        } catch {
            return false
        }
    }

    func lock() {
        isLocked = true
    }

    func handleSceneActive() {
        showPrivacyOverlay = false
        guard isEnabled else { return }

        if let lastBackground = lastBackgroundTime {
            let elapsed = Date().timeIntervalSince(lastBackground)
            if elapsed >= Double(timeoutSeconds) {
                isLocked = true
            }
        }
        lastBackgroundTime = nil
    }

    func handleSceneBackground() {
        showPrivacyOverlay = false
        guard isEnabled else { return }
        lastBackgroundTime = Date()
    }

    func handleSceneInactive() {
        guard isEnabled else { return }
        showPrivacyOverlay = true
    }

    static func canUseBiometrics() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    static func biometricType() -> LABiometryType {
        let context = LAContext()
        var error: NSError?
        context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
        return context.biometryType
    }
}
