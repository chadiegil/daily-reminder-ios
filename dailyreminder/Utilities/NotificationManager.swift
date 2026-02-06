import Foundation
import UserNotifications
import SwiftData

final class NotificationManager {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()

    private init() {}

    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func scheduleNotification(for reminder: Reminder) {
        guard reminder.status == .pending, reminder.dueDate > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = buildBody(for: reminder)
        content.sound = .default
        content.categoryIdentifier = reminder.displayCategoryName

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
