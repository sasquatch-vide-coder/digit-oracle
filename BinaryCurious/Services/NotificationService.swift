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

    // MARK: - Time Alerts (PM / AM)

    /// Schedule PM alerts for each tracked number with a valid time decomposition.
    func scheduleTimeAlerts(numbers: [Int], pmEnabled: Bool, amEnabled: Bool) {
        let pmPrefix = "alert_time_pm"
        let amPrefix = "alert_time_am"

        // Remove all old time alerts
        let pmIDs = numbers.map { "\(pmPrefix)_\($0)" }
        let amIDs = numbers.map { "\(amPrefix)_\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: pmIDs + amIDs)
        // Also clean up any stale legacy IDs
        center.removePendingNotificationRequests(withIdentifiers: ["alert_447pm", "alert_447am"])

        let trackedNumbers = numbers

        for number in trackedNumbers {
            guard let (hour, minute) = decomposeToTime(number), minute < 60 else { continue }

            if pmEnabled {
                let pmHour = hour < 12 ? hour + 12 : hour
                var comps = DateComponents()
                comps.hour = pmHour
                comps.minute = minute

                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
                let content = UNMutableNotificationContent()
                content.title = "It's \(formattedTime(pmHour, minute))!"
                content.body = "The perfect time to spot a \(number). Look around!"
                content.sound = .default

                let request = UNNotificationRequest(identifier: "\(pmPrefix)_\(number)", content: content, trigger: trigger)
                center.add(request)
            }

            if amEnabled {
                var comps = DateComponents()
                comps.hour = hour % 12
                comps.minute = minute

                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
                let content = UNMutableNotificationContent()
                content.title = "It's \(formattedTime(hour % 12, minute))!"
                content.body = "Early bird catches the \(number)!"
                content.sound = .default

                let request = UNNotificationRequest(identifier: "\(amPrefix)_\(number)", content: content, trigger: trigger)
                center.add(request)
            }
        }
    }

    // MARK: - Hourly Alerts (primary number only)

    /// Schedule :NN past each hour for the primary number. Only if number < 60.
    func scheduleHourlyAlerts(numbers: [Int], enabled: Bool) {
        let prefix = "alert_hourly"
        // Remove all hourly alerts
        let ids = (0..<24).map { "\(prefix)_\($0)" }
        // Also remove legacy ids
        let legacyIds = (0..<24).map { "alert_hourly47_\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: ids + legacyIds)

        guard enabled, let primary = numbers.first, primary < 60, primary > 0 else { return }

        for hour in 0..<24 {
            var comps = DateComponents()
            comps.hour = hour
            comps.minute = primary

            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            let content = UNMutableNotificationContent()
            content.title = "It's \(formattedHour(hour)):\(String(format: "%02d", primary))!"
            content.body = "\(primary) minutes past the hour. Keep your eyes peeled!"
            content.sound = .default

            let request = UNNotificationRequest(identifier: "\(prefix)_\(hour)", content: content, trigger: trigger)
            center.add(request)
        }
    }

    // MARK: - Special Date Alerts

    /// Schedule special date alerts: Nth day of year + month/day decomposition.
    func scheduleSpecialDates(numbers: [Int], enabled: Bool) {
        let prefix = "alert_special"
        // Remove all special date alerts (up to 20)
        let ids = numbers.flatMap { n in
            ["\(prefix)_day_\(n)", "\(prefix)_md_\(n)"]
        }
        // Remove legacy IDs
        center.removePendingNotificationRequests(withIdentifiers: ids + ["alert_april7", "alert_day47"])

        guard enabled else { return }

        for number in numbers {
            // Day N of year (only if 1..366)
            if number >= 1 && number <= 366 {
                let (month, day) = dayOfYearToMonthDay(number)
                var comps = DateComponents()
                comps.month = month
                comps.day = day
                comps.hour = 10
                comps.minute = 0

                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
                let content = UNMutableNotificationContent()
                content.title = "Day \(number) of the Year!"
                content.body = "Today is day \(number). Go find some numbers!"
                content.sound = .default

                let request = UNNotificationRequest(identifier: "\(prefix)_day_\(number)", content: content, trigger: trigger)
                center.add(request)
            }

            // Month/day decomposition
            let (md_month, md_day) = RarityCalculator.decomposeToDate(number)
            if let m = md_month, let d = md_day {
                var comps = DateComponents()
                comps.month = m
                comps.day = d
                comps.hour = 10
                comps.minute = 0

                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
                let content = UNMutableNotificationContent()
                content.title = "Happy \(m)/\(d) Day!"
                content.body = "\(number) day! Make it count!"
                content.sound = .default

                let request = UNNotificationRequest(identifier: "\(prefix)_md_\(number)", content: content, trigger: trigger)
                center.add(request)
            }
        }
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
        content.title = "Daily Check"
        content.body = "Have you spotted your numbers today? Keep your streak alive!"
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
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let content = UNMutableNotificationContent()
        content.title = "Your Monthly Digest"
        content.body = "See how many numbers you spotted last month!"
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

    /// Decompose a number to (hour, minute) for time alerts.
    /// 1 digit: 7 → 12:07. 2 digits: 47 → 4:47. 3 digits: 314 → 3:14. 4 digits: 1337 → 1:37.
    private func decomposeToTime(_ number: Int) -> (Int, Int)? {
        switch number {
        case 1...9:
            return (0, number)
        case 10...99:
            return (number / 10, number)  // 47 → hour 4, minute 47
        case 100...999:
            return (number / 100, number % 100)  // 314 → (3, 14)
        case 1000...9999:
            let h = (number / 100) % 12
            let m = number % 100
            return (h == 0 ? 12 : h, m)  // 1337 → (1, 37)
        default:
            return nil
        }
    }

    private func formattedHour(_ hour: Int) -> String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        let ampm = hour < 12 ? "AM" : "PM"
        return "\(h) \(ampm)"
    }

    private func formattedTime(_ hour: Int, _ minute: Int) -> String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        let ampm = hour < 12 ? "AM" : "PM"
        return "\(h):\(String(format: "%02d", minute)) \(ampm)"
    }

    /// Convert day-of-year (1-366) to (month, day).
    private func dayOfYearToMonthDay(_ dayOfYear: Int) -> (Int, Int) {
        var cal = Calendar.current
        cal.timeZone = .current
        let year = cal.component(.year, from: .now)
        guard let jan1 = cal.date(from: DateComponents(year: year, month: 1, day: 1)),
              let date = cal.date(byAdding: .day, value: dayOfYear - 1, to: jan1) else {
            return (1, 1)
        }
        let comps = cal.dateComponents([.month, .day], from: date)
        return (comps.month ?? 1, comps.day ?? 1)
    }
}
