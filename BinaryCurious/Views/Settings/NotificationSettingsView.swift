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
                        Text("Enable Notifications")
                            .font(.headline)
                        Text("Allow Binary Curious to send you number-themed alerts and reminders.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Enable Notifications") {
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
                Text("Time Alerts")
            } footer: {
                Text("Get notified at times matching your tracked numbers.")
            }

            Section {
                Toggle("Special dates", isOn: $alertSpecialDates)
                    .onChange(of: alertSpecialDates) { _, value in
                        notificationService.scheduleSpecialDates(numbers: trackedNumbers.trackedNumbers, enabled: value)
                    }
            } header: {
                Text("Special Dates")
            } footer: {
                Text("Annual reminders on dates matching your tracked numbers.")
            }

            Section {
                Toggle("Daily streak reminder", isOn: $dailyReminder)
                    .onChange(of: dailyReminder) { _, value in
                        notificationService.scheduleDailyReminder(enabled: value)
                    }

                Toggle("Monthly digest (1st of month)", isOn: $monthlyDigest)
                    .onChange(of: monthlyDigest) { _, value in
                        notificationService.scheduleMonthlyDigest(enabled: value)
                    }
            } header: {
                Text("Reminders")
            } footer: {
                Text("Stay on track with your number spotting habit.")
            }

            Section {
                Button("Reset All Notifications", role: .destructive) {
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
        .navigationTitle("Notifications")
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
