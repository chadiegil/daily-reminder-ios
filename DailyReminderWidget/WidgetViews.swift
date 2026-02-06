import SwiftUI
import WidgetKit

struct WidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: ReminderEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    let entry: ReminderEntry

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "bell.fill")
                .font(.title2)
                .foregroundStyle(.blue)

            Text("\(entry.todayCount)")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text("Today")
                .font(.caption)
                .foregroundStyle(.secondary)

            if entry.overdueCount > 0 {
                Text("\(entry.overdueCount) overdue")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.red, in: Capsule())
            }
        }
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: ReminderEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Today's Reminders")
                    .font(.headline)

                Spacer()

                if entry.overdueCount > 0 {
                    Text("\(entry.overdueCount) overdue")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.red, in: Capsule())
                }
            }

            if entry.reminders.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.circle")
                            .font(.title3)
                            .foregroundStyle(.green)
                        Text("All clear for today!")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                Spacer()
            } else {
                ForEach(entry.reminders) { reminder in
                    HStack(spacing: 8) {
                        Image(systemName: reminder.categoryIcon)
                            .font(.caption)
                            .foregroundStyle(.blue)
                            .frame(width: 16)

                        Text(reminder.title)
                            .font(.subheadline)
                            .lineLimit(1)

                        Spacer()

                        Text(reminder.dueDate.formatted(date: .omitted, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                if entry.todayCount > 3 {
                    Text("+\(entry.todayCount - 3) more")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    DailyReminderWidget()
} timeline: {
    ReminderEntry(date: .now, todayCount: 5, overdueCount: 2, reminders: [])
}

#Preview("Medium", as: .systemMedium) {
    DailyReminderWidget()
} timeline: {
    ReminderEntry(
        date: .now,
        todayCount: 3,
        overdueCount: 1,
        reminders: [
            WidgetReminder(title: "Pay electricity bill", categoryIcon: "dollarsign.circle.fill", dueDate: .now),
            WidgetReminder(title: "Team meeting", categoryIcon: "briefcase.fill", dueDate: .now),
            WidgetReminder(title: "Gym session", categoryIcon: "heart.fill", dueDate: .now)
        ]
    )
}
