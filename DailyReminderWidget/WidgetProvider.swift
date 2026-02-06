import WidgetKit
import SwiftData
import Foundation

struct ReminderEntry: TimelineEntry {
    let date: Date
    let todayCount: Int
    let overdueCount: Int
    let reminders: [WidgetReminder]
}

struct WidgetReminder: Identifiable {
    let id: UUID = UUID()
    let title: String
    let categoryIcon: String
    let dueDate: Date
}

struct WidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> ReminderEntry {
        ReminderEntry(date: .now, todayCount: 3, overdueCount: 1, reminders: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (ReminderEntry) -> Void) {
        let entry = fetchEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ReminderEntry>) -> Void) {
        let entry = fetchEntry()

        // Refresh at midnight
        let midnight = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: .now)!)
        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }

    private func fetchEntry() -> ReminderEntry {
        let context = ModelContext(SharedModelContainer.container)
        let descriptor = FetchDescriptor<Reminder>(
            sortBy: [SortDescriptor(\.dueDate, order: .forward)]
        )

        guard let reminders = try? context.fetch(descriptor) else {
            return ReminderEntry(date: .now, todayCount: 0, overdueCount: 0, reminders: [])
        }

        let pending = reminders.filter { ReminderStatus(rawValue: $0.statusRaw) == .pending }

        let startOfToday = Calendar.current.startOfDay(for: .now)
        let endOfToday = startOfToday.addingTimeInterval(86400)

        let todayReminders = pending.filter { $0.dueDate >= startOfToday && $0.dueDate < endOfToday }
        let overdueReminders = pending.filter { $0.dueDate < startOfToday }

        let widgetReminders = todayReminders.prefix(3).map { reminder in
            let category = ReminderCategory(rawValue: reminder.categoryRaw) ?? .personal
            return WidgetReminder(
                title: reminder.title,
                categoryIcon: category.icon,
                dueDate: reminder.dueDate
            )
        }

        return ReminderEntry(
            date: .now,
            todayCount: todayReminders.count,
            overdueCount: overdueReminders.count,
            reminders: Array(widgetReminders)
        )
    }
}
