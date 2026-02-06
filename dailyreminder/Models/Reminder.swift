import Foundation
import SwiftData
import SwiftUI

// MARK: - Enums

enum ReminderCategory: String, CaseIterable, Codable {
    case bills = "Bills"
    case personal = "Personal"
    case work = "Work"
    case health = "Health"
    case custom = "Custom"

    var icon: String {
        switch self {
        case .bills: "dollarsign.circle.fill"
        case .personal: "person.fill"
        case .work: "briefcase.fill"
        case .health: "heart.fill"
        case .custom: "tag.fill"
        }
    }

    var color: Color {
        switch self {
        case .bills: .green
        case .personal: .blue
        case .work: .orange
        case .health: .red
        case .custom: .purple
        }
    }
}

enum RepeatOption: String, CaseIterable, Codable {
    case never = "Never"
    case daily = "Daily"
    case weekly = "Weekly"
    case biweekly = "Every 15 Days"
    case monthly = "Monthly"
    case yearly = "Yearly"
}

enum ReminderStatus: String, CaseIterable, Codable {
    case pending = "Pending"
    case done = "Done"
    case skipped = "Skipped"
    case overdue = "Overdue"

    var color: Color {
        switch self {
        case .pending: .gray
        case .done: .green
        case .skipped: .orange
        case .overdue: .red
        }
    }

    var displayName: String {
        switch self {
        case .pending: "Scheduled"
        case .done: "Done"
        case .skipped: "Skipped"
        case .overdue: "Overdue"
        }
    }
}

// MARK: - Model

@Model
final class Reminder {
    var title: String
    var categoryRaw: String
    var dueDate: Date
    var repeatOptionRaw: String
    var statusRaw: String
    var notes: String
    var customCategoryName: String?
    var createdAt: Date
    var completedAt: Date?

    init(
        title: String,
        category: ReminderCategory = .personal,
        dueDate: Date = .now,
        repeatOption: RepeatOption = .never,
        status: ReminderStatus = .pending,
        notes: String = "",
        customCategoryName: String? = nil
    ) {
        self.title = title
        self.categoryRaw = category.rawValue
        self.dueDate = dueDate
        self.repeatOptionRaw = repeatOption.rawValue
        self.statusRaw = status.rawValue
        self.notes = notes
        self.customCategoryName = customCategoryName
        self.createdAt = .now
        self.completedAt = nil
    }

    // MARK: - Computed Wrappers

    @Transient
    var category: ReminderCategory {
        get { ReminderCategory(rawValue: categoryRaw) ?? .personal }
        set { categoryRaw = newValue.rawValue }
    }

    @Transient
    var repeatOption: RepeatOption {
        get { RepeatOption(rawValue: repeatOptionRaw) ?? .never }
        set { repeatOptionRaw = newValue.rawValue }
    }

    @Transient
    var status: ReminderStatus {
        get { ReminderStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }

    @Transient
    var displayCategoryName: String {
        if category == .custom {
            return customCategoryName ?? "Custom"
        }
        return category.rawValue
    }
}
