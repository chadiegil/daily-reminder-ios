import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ReminderHistory.actionDate, order: .reverse) private var records: [ReminderHistory]

    var body: some View {
        Group {
            if records.isEmpty {
                ContentUnavailableView {
                    Label("No History", systemImage: "clock.arrow.circlepath")
                } description: {
                    Text("Actions you perform on reminders will appear here.")
                }
            } else {
                List {
                    ForEach(groupedByDay, id: \.key) { day, dayRecords in
                        Section(day) {
                            ForEach(dayRecords) { record in
                                HistoryRowView(record: record)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("History")
        .toolbar {
            if !records.isEmpty {
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        clearHistory()
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
    }

    // MARK: - Grouped Data

    private var groupedByDay: [(key: String, value: [ReminderHistory])] {
        let grouped = Dictionary(grouping: records) { record in
            record.actionDate.formatted_dateOnly
        }
        return grouped.sorted { $0.value[0].actionDate > $1.value[0].actionDate }
    }

    private func clearHistory() {
        for record in records {
            modelContext.delete(record)
        }
        try? modelContext.save()
    }
}

// MARK: - Row View

private struct HistoryRowView: View {
    let record: ReminderHistory

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.reminderTitle)
                    .font(.headline)

                HStack(spacing: 6) {
                    Text(record.action)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(actionColor)

                    if !record.periodLabel.isEmpty {
                        Text("· \(record.periodLabel)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Text(record.actionDate.formatted(date: .omitted, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private var actionColor: Color {
        switch record.action {
        case "Completed": .green
        case "Skipped": .orange
        case "Deleted": .red
        case "Created", "Recurring: Next created": .blue
        case "Reset to Pending": .gray
        default: .primary
        }
    }
}

#Preview {
    NavigationStack {
        HistoryView()
    }
    .modelContainer(for: [ReminderHistory.self], inMemory: true)
}
