import SwiftUI

struct ReminderRowView: View {
    let reminder: Reminder
    let onDone: () -> Void
    let onSkip: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: reminder.category.icon)
                .font(.title3)
                .foregroundStyle(reminder.category.color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.headline)

                HStack(spacing: 8) {
                    Text(reminder.dueDate.relativeDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if reminder.repeatOption != .never {
                        Text(reminder.repeatOption.rawValue)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            Text(reminder.status.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(reminder.status.color.opacity(0.15))
                .foregroundStyle(reminder.status.color)
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing) {
            Button {
                onDone()
            } label: {
                Label("Done", systemImage: "checkmark.circle.fill")
            }
            .tint(.green)
        }
        .swipeActions(edge: .leading) {
            Button {
                onSkip()
            } label: {
                Label("Skip", systemImage: "forward.fill")
            }
            .tint(.orange)
        }
    }
}
