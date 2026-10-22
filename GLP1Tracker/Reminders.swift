import Foundation
import UserNotifications

enum Reminders {
    private static let identifier = "weekly-dose"

    /// Schedules (or cancels) the weekly reminder. The text is deliberately
    /// generic so nothing about the medication shows on the lock screen.
    static func update(enabled: Bool, weekday: Int, hour: Int, minute: Int) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        guard enabled else { return }

        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        guard granted else { return }

        let content = UNMutableNotificationContent()
        content.title = "Injection day"
        content.body = "Time for your weekly dose. Open the app to log it."
        content.sound = .default

        var parts = DateComponents()
        parts.weekday = weekday
        parts.hour = hour
        parts.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: true)

        try? await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }
}
