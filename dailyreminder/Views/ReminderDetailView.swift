import SwiftUI

struct ReminderDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let reminder: Reminder
    let viewModel: ReminderListViewModel

    @State private var showEditSheet = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: reminder.category.icon)
                        .font(.largeTitle)
                        .foregroundStyle(reminder.category.color)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(reminder.title)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(reminder.displayCategoryName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Status") {
                HStack {
                    Text("Current Status")
                    Spacer()
                    Text(reminder.status.displayName)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(reminder.status.color.opacity(0.15))
                        .foregroundStyle(reminder.status.color)
                        .clipShape(Capsule())
                }
            }

            Section("Schedule") {
                LabeledContent("Due Date", value: reminder.dueDate.formatted_shortDate)
                LabeledContent("Repeat", value: reminder.repeatOption.rawValue)
                LabeledContent("Created", value: reminder.createdAt.formatted_shortDate)

                if let completedAt = reminder.completedAt {
                    LabeledContent("Completed", value: completedAt.formatted_shortDate)
                }
            }

            if !reminder.notes.isEmpty {
                Section("Notes") {
                    Text(reminder.notes)
                        .font(.body)
                }
            }

            Section("Actions") {
                if reminder.status == .pending {
                    Button {
                        viewModel.markAsDone(reminder)
                    } label: {
                        Label("Mark as Done", systemImage: "checkmark.circle.fill")
                    }
                    .tint(.green)

                    Button {
                        viewModel.markAsSkipped(reminder)
                    } label: {
                        Label("Skip", systemImage: "forward.fill")
                    }
                    .tint(.orange)
                } else {
                    Button {
                        viewModel.resetToPending(reminder)
                    } label: {
                        Label("Reset to Pending", systemImage: "arrow.uturn.backward.circle.fill")
                    }
                    .tint(.blue)
                }

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete Reminder", systemImage: "trash.fill")
                }
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            AddReminderView(viewModel: viewModel, editingReminder: reminder)
        }
        .alert("Delete Reminder", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                dismiss()
                viewModel.deleteReminder(reminder)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \"\(reminder.title)\"? This action cannot be undone.")
        }
    }
}
