import SwiftUI
import SwiftData

// MARK: - Calendar Day Slot

private struct CalendarDay: Identifiable {
    let id: Int
    let date: Date?
}

// MARK: - Monthly Calendar View

struct MonthlyCalendarView: View {
    let viewModel: ReminderListViewModel
    @State private var displayedMonth: Date = Date()

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdaySymbols = Calendar.current.veryShortWeekdaySymbols

    var body: some View {
        VStack(spacing: 12) {
            monthHeader
            weekdayHeader
            calendarGrid
            Spacer()
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    changeMonth(by: -1)
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(.ultraThinMaterial))
            }

            Spacer()

            VStack(spacing: 2) {
                Text(displayedMonth.formatted(.dateTime.month(.wide)))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Text(displayedMonth.formatted(.dateTime.year()))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    displayedMonth = Date()
                }
            } label: {
                Text("Today")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        Capsule().fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.15, green: 0.65, blue: 0.60),
                                    Color(red: 0.20, green: 0.55, blue: 0.70)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    )
            }

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    changeMonth(by: 1)
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(.ultraThinMaterial))
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Weekday Header

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        let days = daysForMonth()

        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(days) { day in
                if let date = day.date {
                    let reminders = viewModel.reminders(for: date)
                    NavigationLink(value: date) {
                        DayCellView(
                            date: date,
                            isToday: calendar.isDateInToday(date),
                            reminders: reminders
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear
                        .frame(height: 54)
                }
            }
        }
    }

    // MARK: - Helpers

    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }

    private func daysForMonth() -> [CalendarDay] {
        let components = calendar.dateComponents([.year, .month], from: displayedMonth)
        guard let firstDay = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstDay) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: firstDay)
        var days: [CalendarDay] = []
        var index = 0

        // Padding for days before the 1st
        for _ in 0..<(firstWeekday - 1) {
            days.append(CalendarDay(id: index, date: nil))
            index += 1
        }

        // Actual days of the month
        for dayOffset in 0..<range.count {
            let date = calendar.date(byAdding: .day, value: dayOffset, to: firstDay)
            days.append(CalendarDay(id: index, date: date))
            index += 1
        }

        // Padding to fill the last row
        while days.count % 7 != 0 {
            days.append(CalendarDay(id: index, date: nil))
            index += 1
        }

        return days
    }
}

// MARK: - Day Cell

private struct DayCellView: View {
    let date: Date
    let isToday: Bool
    let reminders: [Reminder]

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 4) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 15, weight: isToday ? .bold : .medium, design: .rounded))
                .foregroundStyle(isToday ? .white : .primary)

            if !reminders.isEmpty {
                HStack(spacing: 3) {
                    let categories = uniqueCategories()
                    ForEach(categories.prefix(3), id: \.self) { category in
                        Circle()
                            .fill(category.color)
                            .frame(width: 5, height: 5)
                    }
                    if categories.count > 3 {
                        Circle()
                            .fill(.gray.opacity(0.5))
                            .frame(width: 5, height: 5)
                    }
                }
            } else {
                HStack(spacing: 3) {
                    Circle()
                        .fill(.clear)
                        .frame(width: 5, height: 5)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .background {
            if isToday {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.15, green: 0.65, blue: 0.60),
                                Color(red: 0.20, green: 0.55, blue: 0.70)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .teal.opacity(0.3), radius: 6, y: 2)
            } else if !reminders.isEmpty {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.1), lineWidth: 0.5)
                    )
            }
        }
    }

    private func uniqueCategories() -> [ReminderCategory] {
        var seen = Set<String>()
        return reminders.compactMap { reminder in
            let raw = reminder.categoryRaw
            if seen.contains(raw) { return nil }
            seen.insert(raw)
            return reminder.category
        }
    }
}
