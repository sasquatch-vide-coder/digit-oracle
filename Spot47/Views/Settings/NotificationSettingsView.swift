import SwiftUI

struct NotificationSettingsView: View {
    @State private var notificationService = NotificationService.shared

    @AppStorage("notif_447pm") private var alert447PM = false
    @AppStorage("notif_447am") private var alert447AM = false
    @AppStorage("notif_hourly47") private var alertHourly47 = false
    @AppStorage("notif_april7") private var alertApril7 = false
    @AppStorage("notif_day47") private var alertDay47 = false
    @AppStorage("notif_daily_reminder") private var dailyReminder = false
    @AppStorage("notif_monthly_digest") private var monthlyDigest = false

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
                        Text("Allow Spot47 to send you 47-themed alerts and reminders.")
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
                Toggle("4:47 PM", isOn: $alert447PM)
                    .onChange(of: alert447PM) { _, value in
                        notificationService.schedule447PM(enabled: value)
                    }

                Toggle("4:47 AM", isOn: $alert447AM)
                    .onChange(of: alert447AM) { _, value in
                        notificationService.schedule447AM(enabled: value)
                    }

                Toggle("Every hour at :47", isOn: $alertHourly47)
                    .onChange(of: alertHourly47) { _, value in
                        notificationService.scheduleHourly47(enabled: value)
                    }
            } header: {
                Text("Time Alerts")
            } footer: {
                Text("Get notified at special 47 times throughout the day.")
            }

            Section {
                Toggle("April 7 (4/7)", isOn: $alertApril7)
                    .onChange(of: alertApril7) { _, value in
                        notificationService.scheduleApril7(enabled: value)
                    }

                Toggle("Day 47 (Feb 16)", isOn: $alertDay47)
                    .onChange(of: alertDay47) { _, value in
                        notificationService.scheduleDay47(enabled: value)
                    }
            } header: {
                Text("Special Dates")
            } footer: {
                Text("Annual reminders on the most 47-relevant dates.")
            }

            Section {
                Toggle("Daily streak reminder (7:47 PM)", isOn: $dailyReminder)
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
                Text("Stay on track with your 47 spotting habit.")
            }

            Section {
                Button("Reset All Notifications", role: .destructive) {
                    alert447PM = false
                    alert447AM = false
                    alertHourly47 = false
                    alertApril7 = false
                    alertDay47 = false
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
}
