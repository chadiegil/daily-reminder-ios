import Foundation

extension Calendar {
    func isDateToday(_ date: Date) -> Bool {
        isDateInToday(date)
    }

    func isDateBeforeToday(_ date: Date) -> Bool {
        let startOfToday = startOfDay(for: Date.now)
        return date < startOfToday
    }

    func isDateAfterToday(_ date: Date) -> Bool {
        let endOfToday = startOfDay(for: Date.now).addingTimeInterval(86400)
        return date >= endOfToday
    }
}

extension Date {
    var isToday: Bool {
        Calendar.current.isDateToday(self)
    }

    var isBeforeToday: Bool {
        Calendar.current.isDateBeforeToday(self)
    }

    var isAfterToday: Bool {
        Calendar.current.isDateAfterToday(self)
    }

    var formatted_shortDate: String {
        formatted(date: .abbreviated, time: .shortened)
    }

    var formatted_dateOnly: String {
        formatted(date: .abbreviated, time: .omitted)
    }

    func nextOccurrence(for repeatOption: RepeatOption) -> Date? {
        switch repeatOption {
        case .never: return nil
        case .daily:   return Calendar.current.date(byAdding: .day, value: 1, to: self)
        case .weekly:   return Calendar.current.date(byAdding: .weekOfYear, value: 1, to: self)
        case .biweekly: return Calendar.current.date(byAdding: .day, value: 15, to: self)
        case .monthly:  return Calendar.current.date(byAdding: .month, value: 1, to: self)
        case .yearly:  return Calendar.current.date(byAdding: .year, value: 1, to: self)
        }
    }

    var relativeDescription: String {
        let calendar = Calendar.current
        let now = Date.now
        let startOfToday = calendar.startOfDay(for: now)
        let startOfDate = calendar.startOfDay(for: self)

        let days = calendar.dateComponents([.day], from: startOfToday, to: startOfDate).day ?? 0

        switch days {
        case 0: return "Today"
        case 1: return "Tomorrow"
        case -1: return "Yesterday"
        case 2...7: return "In \(days) days"
        case let n where n < -1: return "\(abs(n)) days ago"
        default: return formatted_dateOnly
        }
    }
}
