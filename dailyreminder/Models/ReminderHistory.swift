import Foundation
import SwiftData

@Model
final class ReminderHistory {
    var reminderTitle: String
    var action: String
    var actionDate: Date
    var periodLabel: String
    var createdAt: Date

    init(
        reminderTitle: String,
        action: String,
        actionDate: Date = .now,
        periodLabel: String = "",
        createdAt: Date = .now
    ) {
        self.reminderTitle = reminderTitle
        self.action = action
        self.actionDate = actionDate
        self.periodLabel = periodLabel
        self.createdAt = createdAt
    }
}
