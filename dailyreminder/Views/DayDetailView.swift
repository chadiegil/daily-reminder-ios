import SwiftUI
import SwiftData

struct DayDetailView: View {
    let date: Date
    let viewModel: ReminderListViewModel

    private var reminders: [Reminder] {
        viewModel.reminders(for: date).sorted { $0.dueDate < $1.dueDate }
    }

    private var groupedReminders: [(ReminderCategory, [Reminder])] {
        let grouped = Dictionary(grouping: reminders) { $0.category }
        return ReminderCategory.allCases.compactMap { category in
            guard let items = grouped[category], !items.isEmpty else { return nil }
            return (category, items)
        }
    }

    var body: some View {
        Group {
            if reminders.isEmpty {
                ContentUnavailableView {
                    Label("No Reminders", systemImage: "calendar.badge.checkmark")
                } description: {
                    Text("Nothing scheduled for this day.")
                }
            } else {
                List {
                    ForEach(groupedReminders, id: \.0) { category, items in
                        Section {
                            ForEach(items) { reminder in
                                NavigationLink(value: reminder.persistentModelID) {
                                    DayReminderRow(reminder: reminder)
                                }
                                .swipeActions(edge: .trailing) {
                                    if reminder.status == .pending {
                                        Button {
                                            viewModel.markAsDone(reminder)
                                        } label: {
                                            Label("Done", systemImage: "checkmark.circle.fill")
                                        }
                                        .tint(.green)
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    if reminder.status == .pending {
                                        Button {
                                            viewModel.markAsSkipped(reminder)
                                        } label: {
                                            Label("Skip", systemImage: "forward.fill")
                                        }
                                        .tint(.orange)
                                    }
                                }
                            }
                        } header: {
                            HStack(spacing: 6) {
                                Image(systemName: category.icon)
                                    .foregroundStyle(category.color)
                                Text(category.rawValue)
                            }
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle(date.formatted(date: .long, time: .omitted))
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Day Reminder Row

private struct DayReminderRow: View {
    let reminder: Reminder

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: reminder.category.icon)
                .font(.system(size: 18))
                .foregroundStyle(reminder.category.color)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(reminder.category.color.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(reminder.title)
                    .font(.system(size: 15, weight: .medium))
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(reminder.dueDate.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)

                    if reminder.repeatOption != .never {
                        Text(reminder.repeatOption.rawValue)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(.blue.opacity(0.12))
                            )
                            .foregroundStyle(.blue)
                    }
                }
            }

            Spacer()

            Text(reminder.status.displayName)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule().fill(reminder.status.color.opacity(0.15))
                )
                .foregroundStyle(reminder.status.color)
        }
        .padding(.vertical, 4)
    }
}
