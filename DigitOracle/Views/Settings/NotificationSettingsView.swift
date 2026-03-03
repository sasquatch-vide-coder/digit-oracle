import SwiftUI

struct NotificationSettingsView: View {
    @State private var notificationService = NotificationService.shared
    @State private var trackedNumbers = TrackedNumberService.shared

    @AppStorage("notif_time_pm") private var alertTimePM = false
    @AppStorage("notif_time_am") private var alertTimeAM = false
    @AppStorage("notif_hourly") private var alertHourly = false
    @AppStorage("notif_special_dates") private var alertSpecialDates = false
    @AppStorage("notif_daily_reminder") private var dailyReminder = false
    @AppStorage("notif_monthly_digest") private var monthlyDigest = false

    private var timeAlertLabel: String {
        let numbers = trackedNumbers.trackedNumbers
        let labels = numbers.compactMap { number -> String? in
            guard let (h, m) = decomposeToTime(number), m < 60 else { return nil }
            let h12 = h % 12 == 0 ? 12 : h % 12
            return "\(h12):\(String(format: "%02d", m))"
        }
        if labels.isEmpty { return "No valid times" }
        return labels.joined(separator: ", ")
    }

    private var hourlyLabel: String {
        guard let primary = trackedNumbers.trackedNumbers.first, primary > 0, primary < 60 else {
            return "Not available (number must be < 60)"
        }
        return "Every hour at :\(String(format: "%02d", primary))"
    }

    var body: some View {
        Form {
            if !notificationService.isAuthorized {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "bell.badge")
                            .font(.largeTitle)
                            .foregroundColor(.accentColor)
                        Text("Awaken the Herald")
                            .font(.headline)
                        Text("Grant the Herald leave to whisper signs and summons unto thee.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Awaken the Herald") {
                            Task {
                                await notificationService.requestPermission()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
            }

            Section {
                Toggle("PM alerts (\(timeAlertLabel) PM)", isOn: $alertTimePM)
                    .onChange(of: alertTimePM) { _, _ in rescheduleTimeAlerts() }

                Toggle("AM alerts (\(timeAlertLabel) AM)", isOn: $alertTimeAM)
                    .onChange(of: alertTimeAM) { _, _ in rescheduleTimeAlerts() }

                Toggle(hourlyLabel, isOn: $alertHourly)
                    .onChange(of: alertHourly) { _, value in
                        notificationService.scheduleHourlyAlerts(numbers: trackedNumbers.trackedNumbers, enabled: value)
                    }
            } header: {
                Text("Clock Omens")
            } footer: {
                Text("Receive signs when the clock aligns with thy sacred numbers.")
            }

            Section {
                Toggle("Sacred dates", isOn: $alertSpecialDates)
                    .onChange(of: alertSpecialDates) { _, value in
                        notificationService.scheduleSpecialDates(numbers: trackedNumbers.trackedNumbers, enabled: value)
                    }
            } header: {
                Text("Sacred Dates")
            } footer: {
                Text("Annual signs on dates aligned with thy sacred numbers.")
            }

            Section {
                Toggle("Daily devotion whisper", isOn: $dailyReminder)
                    .onChange(of: dailyReminder) { _, value in
                        notificationService.scheduleDailyReminder(enabled: value)
                    }

                Toggle("Codex dispatch (1st of month)", isOn: $monthlyDigest)
                    .onChange(of: monthlyDigest) { _, value in
                        notificationService.scheduleMonthlyDigest(enabled: value)
                    }
            } header: {
                Text("Whispers")
            } footer: {
                Text("The Oracle reminds thee of thy sacred quest.")
            }

            Section {
                Button("Silence the Herald", role: .destructive) {
                    alertTimePM = false
                    alertTimeAM = false
                    alertHourly = false
                    alertSpecialDates = false
                    dailyReminder = false
                    monthlyDigest = false
                    notificationService.removeAllNotifications()
                }
            }
        }
        .navigationTitle("Omens & Whispers")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await notificationService.checkAuthorizationStatus()
        }
    }

    private func rescheduleTimeAlerts() {
        notificationService.scheduleTimeAlerts(
            numbers: trackedNumbers.trackedNumbers,
            pmEnabled: alertTimePM,
            amEnabled: alertTimeAM
        )
    }

    /// Mirror of the service's decomposition for UI display.
    private func decomposeToTime(_ number: Int) -> (Int, Int)? {
        switch number {
        case 1...9: return (0, number)
        case 10...99: return (number / 10, number)
        case 100...999: return (number / 100, number % 100)
        case 1000...9999:
            let h = (number / 100) % 12
            return (h == 0 ? 12 : h, number % 100)
        default: return nil
        }
    }
}
