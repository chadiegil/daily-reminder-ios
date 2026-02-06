import Foundation
import UserNotifications
import SwiftData

enum SnoozeDuration: String {
    case oneMinute = "1 min"
    case thirtyMinutes = "30 min"
    case oneHour = "1 hour"
    case tomorrow = "Tomorrow"

    var timeInterval: TimeInterval {
        switch self {
        case .oneMinute: return 60
        case .thirtyMinutes: return 30 * 60
        case .oneHour: return 60 * 60
        case .tomorrow: return 24 * 60 * 60
        }
    }
}

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()

    private override init() {
        super.init()
        center.delegate = self
        registerCategories()
    }

    // MARK: - Setup

    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    private func registerCategories() {
        let snooze1 = UNNotificationAction(
            identifier: "SNOOZE_1",
            title: "Snooze 1 min",
            options: []
        )
        let snooze30 = UNNotificationAction(
            identifier: "SNOOZE_30",
            title: "Snooze 30 min",
            options: []
        )
        let snooze60 = UNNotificationAction(
            identifier: "SNOOZE_60",
            title: "Snooze 1 hour",
            options: []
        )
        let snoozeTomorrow = UNNotificationAction(
            identifier: "SNOOZE_TOMORROW",
            title: "Tomorrow",
            options: []
        )

        let reminderCategory = UNNotificationCategory(
            identifier: "REMINDER",
            actions: [snooze1, snooze30, snooze60, snoozeTomorrow],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([reminderCategory])
    }

    // MARK: - Scheduling

    func scheduleNotification(for reminder: Reminder) {
        guard reminder.status == .pending, reminder.dueDate > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = buildBody(for: reminder)
        content.sound = UNNotificationSound(named: UNNotificationSoundName("snooze_alert.caf"))
        content.categoryIdentifier = "REMINDER"

        let calendar = Calendar.current
        let trigger: UNNotificationTrigger

        switch reminder.repeatOption {
        case .never:
            let components = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: reminder.dueDate
            )
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        case .daily:
            let components = calendar.dateComponents(
                [.hour, .minute],
                from: reminder.dueDate
            )
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        case .weekly:
            let components = calendar.dateComponents(
                [.weekday, .hour, .minute],
                from: reminder.dueDate
            )
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        case .biweekly:
            let interval = reminder.dueDate.timeIntervalSinceNow
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(interval, 1), repeats: false)
        case .monthly:
            let components = calendar.dateComponents(
                [.day, .hour, .minute],
                from: reminder.dueDate
            )
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        case .yearly:
            let components = calendar.dateComponents(
                [.month, .day, .hour, .minute],
                from: reminder.dueDate
            )
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        }

        let identifier = notificationIdentifier(for: reminder)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        center.add(request)
    }

    func cancelNotification(for reminder: Reminder) {
        let identifier = notificationIdentifier(for: reminder)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func rescheduleNotification(for reminder: Reminder) {
        cancelNotification(for: reminder)
        scheduleNotification(for: reminder)
    }

    // MARK: - Snooze Scheduling

    func snoozeNotification(for reminder: Reminder, duration: SnoozeDuration) {
        cancelNotification(for: reminder)

        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = buildBody(for: reminder)
        content.sound = UNNotificationSound(named: UNNotificationSoundName("snooze_alert.caf"))
        content.categoryIdentifier = "REMINDER"

        scheduleSnooze(content: content, interval: duration.timeInterval, identifier: notificationIdentifier(for: reminder))
    }

    private func scheduleSnooze(content: UNMutableNotificationContent, interval: TimeInterval, identifier: String) {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let content = response.notification.request.content

        let interval: TimeInterval? = switch response.actionIdentifier {
        case "SNOOZE_1": SnoozeDuration.oneMinute.timeInterval
        case "SNOOZE_30": SnoozeDuration.thirtyMinutes.timeInterval
        case "SNOOZE_60": SnoozeDuration.oneHour.timeInterval
        case "SNOOZE_TOMORROW": SnoozeDuration.tomorrow.timeInterval
        default: nil
        }

        if let interval {
            let newContent = content.mutableCopy() as! UNMutableNotificationContent
            let identifier = response.notification.request.identifier
            scheduleSnooze(content: newContent, interval: interval, identifier: identifier)
        }

        completionHandler()
    }

    // MARK: - Helpers

    private func notificationIdentifier(for reminder: Reminder) -> String {
        "\(reminder.persistentModelID.hashValue)"
    }

    private func buildBody(for reminder: Reminder) -> String {
        var parts: [String] = [reminder.displayCategoryName]
        let trimmedNotes = reminder.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedNotes.isEmpty {
            let preview = trimmedNotes.prefix(50)
            parts.append(String(preview))
        }
        return parts.joined(separator: " — ")
    }
}
