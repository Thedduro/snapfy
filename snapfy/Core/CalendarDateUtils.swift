import Foundation

enum CalendarDateUtils {
    static let calendar = Calendar.current

    static func startOfMonth(for date: Date) -> Date {
        calendar.dateInterval(of: .month, for: date)?.start ?? date
    }

    static func monthTitle(for date: Date) -> String {
        date.formatted(.dateTime.year().month(.wide))
    }

    static func weekdaySymbols() -> [String] {
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let firstWeekdayIndex = calendar.firstWeekday - 1
        return Array(symbols[firstWeekdayIndex...]) + Array(symbols[..<firstWeekdayIndex])
    }

    static func monthDays(for month: Date) -> [Date] {
        let monthStart = startOfMonth(for: month)
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let leadingDays = (firstWeekday - calendar.firstWeekday + 7) % 7
        let gridStart = calendar.date(byAdding: .day, value: -leadingDays, to: monthStart) ?? monthStart

        return (0..<42).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: gridStart)
        }
    }

    static func dayNumber(for date: Date) -> String {
        String(calendar.component(.day, from: date))
    }

    static func isInMonth(_ date: Date, month: Date) -> Bool {
        calendar.isDate(date, equalTo: month, toGranularity: .month)
    }

    static func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }
}
