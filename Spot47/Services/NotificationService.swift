import Foundation
import UserNotifications

@Observable
class NotificationService {
    static let shared = NotificationService()

    var isAuthorized = false

    private let center = UNUserNotificationCenter.current()

    // MARK: - Permission

    func requestPermission() async {
        do {
            isAuthorized = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            // Permission request failed
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - 4:47 Alerts

    func schedule447PM(enabled: Bool) {
        let id = "alert_447pm"
        if !enabled {
            center.removePendingNotificationRequests(withIdentifiers: [id])
            return
        }

        var dateComponents = DateComponents()
        dateComponents.hour = 16
        dateComponents.minute = 47

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let content = UNMutableNotificationContent()
        content.title = "It's 4:47 PM!"
        content.body = "The perfect time to spot a 47. Look around you! 👀"
        content.sound = .default

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }

    func schedule447AM(enabled: Bool) {
        let id = "alert_447am"
        if !enabled {
            center.removePendingNotificationRequests(withIdentifiers: [id])
            return
        }

        var dateComponents = DateComponents()
        dateComponents.hour = 4
        dateComponents.minute = 47

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let content = UNMutableNotificationContent()
        content.title = "It's 4:47 AM!"
        content.body = "Early bird catches the 47! Night owl bonus if you're still up."
        content.sound = .default

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - :47 Hourly Alert

    func scheduleHourly47(enabled: Bool) {
        let prefix = "alert_hourly47"
        // Remove all hourly alerts
        let ids = (0..<24).map { "\(prefix)_\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: ids)

        guard enabled else { return }

        // Schedule for :47 of every hour
        for hour in 0..<24 {
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = 47

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

            let content = UNMutableNotificationContent()
            content.title = "It's \(formattedHour(hour)):47!"
            content.body = "47 minutes past the hour. Keep your eyes peeled!"
            content.sound = .default

            let request = UNNotificationRequest(identifier: "\(prefix)_\(hour)", content: content, trigger: trigger)
            center.add(request)
        }
    }

    // MARK: - Special Date Alerts

    func scheduleApril7(enabled: Bool) {
        let id = "alert_april7"
        if !enabled {
            center.removePendingNotificationRequests(withIdentifiers: [id])
            return
        }

        var dateComponents = DateComponents()
        dateComponents.month = 4
        dateComponents.day = 7
        dateComponents.hour = 10
        dateComponents.minute = 47

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let content = UNMutableNotificationContent()
        content.title = "Happy 4/7 Day!"
        content.body = "April 7th — the ultimate 47 day. Make it count!"
        content.sound = .default

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }

    func scheduleDay47(enabled: Bool) {
        let id = "alert_day47"
        if !enabled {
            center.removePendingNotificationRequests(withIdentifiers: [id])
            return
        }

        // Day 47 = February 16
        var dateComponents = DateComponents()
        dateComponents.month = 2
        dateComponents.day = 16
        dateComponents.hour = 10
        dateComponents.minute = 47

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let content = UNMutableNotificationContent()
        content.title = "Day 47 of the Year!"
        content.body = "February 16th is the 47th day of the year. Go find some 47s!"
        content.sound = .default

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - Daily Reminder

    func scheduleDailyReminder(enabled: Bool, hour: Int = 19, minute: Int = 47) {
        let id = "alert_daily_reminder"
        if !enabled {
            center.removePendingNotificationRequests(withIdentifiers: [id])
            return
        }

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let content = UNMutableNotificationContent()
        content.title = "Daily 47 Check"
        content.body = "Have you spotted a 47 today? Keep your streak alive!"
        content.sound = .default

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - Monthly Digest

    func scheduleMonthlyDigest(enabled: Bool) {
        let id = "alert_monthly_digest"
        if !enabled {
            center.removePendingNotificationRequests(withIdentifiers: [id])
            return
        }

        var dateComponents = DateComponents()
        dateComponents.day = 1
        dateComponents.hour = 9
        dateComponents.minute = 47

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let content = UNMutableNotificationContent()
        content.title = "Your Monthly 47 Digest"
        content.body = "See how many 47s you spotted last month!"
        content.sound = .default

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - On This Day Memory

    func scheduleMemoryNotification(message: String) {
        let id = "memory_\(UUID().uuidString)"

        var dateComponents = DateComponents()
        dateComponents.hour = 10
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let content = UNMutableNotificationContent()
        content.title = "On This Day"
        content.body = message
        content.sound = .default

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - Clear All

    func removeAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Helpers

    private func formattedHour(_ hour: Int) -> String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        let ampm = hour < 12 ? "AM" : "PM"
        return "\(h) \(ampm)"
    }
}
