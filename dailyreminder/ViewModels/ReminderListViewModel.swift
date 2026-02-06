import Foundation
import SwiftData
import Observation
import WidgetKit

enum ReminderTab: String, CaseIterable {
    case today = "Today"
    case upcoming = "Upcoming"
    case overdue = "Overdue"
}

@Observable
final class ReminderListViewModel {
    var selectedTab: ReminderTab = .today
    var searchText: String = ""
    private(set) var refreshTrigger = 0

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Data Access

    private var allReminders: [Reminder] {
        // Access refreshTrigger so @Observable tracks it;
        // when it changes after a save(), SwiftUI re-evaluates this property.
        _ = refreshTrigger
        let descriptor = FetchDescriptor<Reminder>(
            sortBy: [SortDescriptor(\.dueDate, order: .forward)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
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
        }

        if searchText.isEmpty {
            return reminders
        }
        return reminders.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    func reminder(for id: PersistentIdentifier) -> Reminder? {
        allReminders.first(where: { $0.persistentModelID == id })
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
        save()
        NotificationManager.shared.scheduleNotification(for: reminder)
        logHistory(reminderTitle: title, action: "Created", periodLabel: dueDate.formatted_dateOnly)
    }

    func deleteReminder(_ reminder: Reminder) {
        logHistory(reminderTitle: reminder.title, action: "Deleted")
        NotificationManager.shared.cancelNotification(for: reminder)
        modelContext.delete(reminder)
        save()
    }

    func markAsDone(_ reminder: Reminder) {
        reminder.status = .done
        reminder.completedAt = .now
        save()
        NotificationManager.shared.cancelNotification(for: reminder)
        logHistory(reminderTitle: reminder.title, action: "Completed")
        createNextOccurrence(from: reminder)
    }

    func markAsSkipped(_ reminder: Reminder) {
        reminder.status = .skipped
        reminder.completedAt = .now
        save()
        NotificationManager.shared.cancelNotification(for: reminder)
        logHistory(reminderTitle: reminder.title, action: "Skipped")
        createNextOccurrence(from: reminder)
    }

    func resetToPending(_ reminder: Reminder) {
        reminder.status = .pending
        reminder.completedAt = nil
        save()
        NotificationManager.shared.scheduleNotification(for: reminder)
        logHistory(reminderTitle: reminder.title, action: "Reset to Pending")
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
        save()
        NotificationManager.shared.scheduleNotification(for: next)
        logHistory(reminderTitle: reminder.title, action: "Recurring: Next created", periodLabel: nextDate.formatted_dateOnly)
    }

    // MARK: - History

    private func logHistory(reminderTitle: String, action: String, periodLabel: String = "") {
        let record = ReminderHistory(reminderTitle: reminderTitle, action: action, periodLabel: periodLabel)
        modelContext.insert(record)
        save()
    }

    // MARK: - Persistence

    private func save() {
        try? modelContext.save()
        refreshTrigger += 1
        WidgetCenter.shared.reloadAllTimelines()
    }
}
