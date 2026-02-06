import SwiftUI

struct AddReminderView: View {
    @Environment(\.dismiss) private var dismiss

    let viewModel: ReminderListViewModel
    var editingReminder: Reminder?

    @State private var title: String = ""
    @State private var category: ReminderCategory = .personal
    @State private var dueDate: Date = .now
    @State private var repeatOption: RepeatOption = .never
    @State private var notes: String = ""
    @State private var customCategoryName: String = ""

    private var isEditing: Bool { editingReminder != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)

                    Picker("Category", selection: $category) {
                        ForEach(ReminderCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }

                    if category == .custom {
                        TextField("Custom Category Name", text: $customCategoryName)
                    }
                }

                Section("Schedule") {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.graphical)

                    Picker("Repeat", selection: $repeatOption) {
                        ForEach(RepeatOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle(isEditing ? "Edit Reminder" : "New Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveReminder()
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let reminder = editingReminder {
                    title = reminder.title
                    category = reminder.category
                    dueDate = reminder.dueDate
                    repeatOption = reminder.repeatOption
                    notes = reminder.notes
                    customCategoryName = reminder.customCategoryName ?? ""
                }
            }
        }
    }

    private func saveReminder() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let customName = category == .custom && !customCategoryName.trimmingCharacters(in: .whitespaces).isEmpty
            ? customCategoryName.trimmingCharacters(in: .whitespaces)
            : nil

        if let reminder = editingReminder {
            reminder.title = trimmedTitle
            reminder.category = category
            reminder.dueDate = dueDate
            reminder.repeatOption = repeatOption
            reminder.notes = notes
            reminder.customCategoryName = customName
            NotificationManager.shared.rescheduleNotification(for: reminder)
        } else {
            viewModel.addReminder(
                title: trimmedTitle,
                category: category,
                dueDate: dueDate,
                repeatOption: repeatOption,
                notes: notes,
                customCategoryName: customName
            )
        }
    }
}
