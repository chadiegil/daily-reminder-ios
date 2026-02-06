import Foundation
import SwiftData
import Observation
import WidgetKit

enum ReminderTab: String, CaseIterable {
    case today = "Today"
    case upcoming = "Upcoming"
    case overdue = "Overdue"
    case month = "Month"
}

@Observable
final class ReminderListViewModel {
    var selectedTab: ReminderTab = .today
    var searchText: String = ""

    private let modelContext: ModelContext
    private(set) var allReminders: [Reminder] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchReminders()
    }

    // MARK: - Data Access

    private func fetchReminders() {
        let descriptor = FetchDescriptor<Reminder>(
            sortBy: [SortDescriptor(\.dueDate, order: .forward)]
        )
        allReminders = (try? modelContext.fetch(descriptor)) ?? []
    }

    var filteredReminders: [Reminder] {
        let reminders: [Reminder]

        switch selectedTab {
        case .today:
            reminders = allReminders.filter { $0.status == .pending && $0.dueDate.isToday }
        case .upcoming:
            reminders = allReminders.filter { $0.status == .pending && $0.dueDate.isAfterToday }
        case .overdue:
            reminders = allReminders.filter { $0.status == .pending && $0.dueDate.isBeforeToday }
        case .month:
            reminders = []
        }

        if searchText.isEmpty {
            return reminders
        }
        return reminders.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    func reminder(for id: PersistentIdentifier) -> Reminder? {
        allReminders.first(where: { $0.persistentModelID == id })
    }

    func reminders(for date: Date) -> [Reminder] {
        let cal = Calendar.current

        // 1. Real reminders that exist on this exact date
        var result = allReminders.filter { cal.isDate($0.dueDate, inSameDayAs: date) }
        let existingIDs = Set(result.map { $0.persistentModelID })

        // 2. Project pending recurring reminders into the future
        let recurring = allReminders.filter {
            $0.repeatOption != .never && $0.status == .pending
        }

        for reminder in recurring {
            if existingIDs.contains(reminder.persistentModelID) { continue }
            guard cal.startOfDay(for: date) > cal.startOfDay(for: reminder.dueDate) else { continue }
            if matchesRecurrence(reminder: reminder, on: date) {
                result.append(reminder)
            }
        }

        return result
    }

    // O(1) mathematical check — no iteration needed
    private func matchesRecurrence(reminder: Reminder, on targetDate: Date) -> Bool {
        let cal = Calendar.current
        let dueDate = reminder.dueDate

        switch reminder.repeatOption {
        case .never:
            return false

        case .daily:
            return true

        case .weekly:
            return cal.component(.weekday, from: dueDate) == cal.component(.weekday, from: targetDate)

        case .biweekly:
            let days = cal.dateComponents(
                [.day],
                from: cal.startOfDay(for: dueDate),
                to: cal.startOfDay(for: targetDate)
            ).day ?? 0
            return days > 0 && days % 15 == 0

        case .monthly:
            let dueDay = cal.component(.day, from: dueDate)
            let targetDay = cal.component(.day, from: targetDate)
            let daysInMonth = cal.range(of: .day, in: .month, for: targetDate)?.count ?? 28
            if dueDay > daysInMonth { return targetDay == daysInMonth }
            return dueDay == targetDay

        case .yearly:
            let dc = cal.dateComponents([.month, .day], from: dueDate)
            let tc = cal.dateComponents([.month, .day], from: targetDate)
            let daysInMonth = cal.range(of: .day, in: .month, for: targetDate)?.count ?? 28
            if (dc.day ?? 1) > daysInMonth {
                return dc.month == tc.month && tc.day == daysInMonth
            }
            return dc.month == tc.month && dc.day == tc.day
        }
    }

    // MARK: - Badge Counts

    var todayCount: Int {
        allReminders.filter { $0.status == .pending && $0.dueDate.isToday }.count
    }

    var upcomingCount: Int {
        allReminders.filter { $0.status == .pending && $0.dueDate.isAfterToday }.count
    }

    var overdueCount: Int {
        allReminders.filter { $0.status == .pending && $0.dueDate.isBeforeToday }.count
    }

    var monthCount: Int {
        let cal = Calendar.current
        let components = cal.dateComponents([.year, .month], from: Date())
        guard let firstDay = cal.date(from: components),
              let nextMonth = cal.date(byAdding: .month, value: 1, to: firstDay) else { return 0 }
        return allReminders.filter {
            $0.status == .pending && $0.dueDate >= firstDay && $0.dueDate < nextMonth
        }.count
    }

    // MARK: - CRUD

    func addReminder(
        title: String,
        category: ReminderCategory,
        dueDate: Date,
        repeatOption: RepeatOption,
        notes: String,
        customCategoryName: String?
    ) {
        let reminder = Reminder(
            title: title,
            category: category,
            dueDate: dueDate,
            repeatOption: repeatOption,
            notes: notes,
            customCategoryName: customCategoryName
        )
        modelContext.insert(reminder)
        NotificationManager.shared.scheduleNotification(for: reminder)
        logHistory(reminderTitle: title, action: "Created", periodLabel: dueDate.formatted_dateOnly)
        save()
    }

    func deleteReminder(_ reminder: Reminder) {
        NotificationManager.shared.cancelNotification(for: reminder)
        logHistory(reminderTitle: reminder.title, action: "Deleted")
        modelContext.delete(reminder)
        save()
    }

    func markAsDone(_ reminder: Reminder) {
        reminder.status = .done
        reminder.completedAt = .now
        reminder.snoozeUntil = nil
        NotificationManager.shared.cancelNotification(for: reminder)
        logHistory(reminderTitle: reminder.title, action: "Completed")
        createNextOccurrence(from: reminder)
        save()
    }

    func markAsSkipped(_ reminder: Reminder) {
        reminder.status = .skipped
        reminder.completedAt = .now
        reminder.snoozeUntil = nil
        NotificationManager.shared.cancelNotification(for: reminder)
        logHistory(reminderTitle: reminder.title, action: "Skipped")
        createNextOccurrence(from: reminder)
        save()
    }

    func resetToPending(_ reminder: Reminder) {
        reminder.status = .pending
        reminder.completedAt = nil
        reminder.snoozeUntil = nil
        NotificationManager.shared.scheduleNotification(for: reminder)
        logHistory(reminderTitle: reminder.title, action: "Reset to Pending")
        save()
    }

    // MARK: - Snooze

    func snoozeReminder(_ reminder: Reminder, duration: SnoozeDuration) {
        let snoozeDate = Date.now.addingTimeInterval(duration.timeInterval)
        reminder.dueDate = snoozeDate
        reminder.snoozeUntil = snoozeDate
        NotificationManager.shared.snoozeNotification(for: reminder, duration: duration)
        logHistory(reminderTitle: reminder.title, action: "Snoozed (\(duration.rawValue))")
        save()
    }

    // MARK: - Recurring

    private func createNextOccurrence(from reminder: Reminder) {
        guard reminder.repeatOption != .never,
              let nextDate = reminder.dueDate.nextOccurrence(for: reminder.repeatOption) else { return }

        let next = Reminder(
            title: reminder.title,
            category: reminder.category,
            dueDate: nextDate,
            repeatOption: reminder.repeatOption,
            notes: reminder.notes,
            customCategoryName: reminder.customCategoryName
        )
        modelContext.insert(next)
        NotificationManager.shared.scheduleNotification(for: next)
        logHistory(reminderTitle: reminder.title, action: "Recurring: Next created", periodLabel: nextDate.formatted_dateOnly)
    }

    // MARK: - History

    private func logHistory(reminderTitle: String, action: String, periodLabel: String = "") {
        let record = ReminderHistory(reminderTitle: reminderTitle, action: action, periodLabel: periodLabel)
        modelContext.insert(record)
    }

    // MARK: - Persistence

    private func save() {
        try? modelContext.save()
        fetchReminders()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
