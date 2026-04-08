import SwiftUI

struct CalendarPageView: View {
    @State private var displayedMonth = CalendarDateUtils.startOfMonth(for: .now)
    @State private var selectedDate = Date()

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                monthHeader

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(CalendarDateUtils.weekdaySymbols(), id: \.self) { symbol in
                        Text(symbol)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }

                    ForEach(CalendarDateUtils.monthDays(for: displayedMonth), id: \.self) { day in
                        CalendarDayCell(
                            day: day,
                            isCurrentMonth: CalendarDateUtils.isInMonth(day, month: displayedMonth),
                            isSelected: CalendarDateUtils.isSameDay(day, selectedDate),
                            onTap: {
                                selectedDate = day
                            }
                        )
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle("캘린더")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: displayedMonth) { _, newValue in
            if !CalendarDateUtils.isInMonth(selectedDate, month: newValue) {
                selectedDate = newValue
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                shiftMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 36, height: 36)
            }

            Spacer()

            Text(CalendarDateUtils.monthTitle(for: displayedMonth))
                .font(.title3.bold())

            Spacer()

            Button {
                shiftMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 36, height: 36)
            }
        }
    }

    private func shiftMonth(by value: Int) {
        displayedMonth = CalendarDateUtils.calendar.date(byAdding: .month, value: value, to: displayedMonth) ?? displayedMonth
    }
}

private struct CalendarDayCell: View {
    let day: Date
    let isCurrentMonth: Bool
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.blue.opacity(0.12) : Color(.secondarySystemBackground))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(borderColor, lineWidth: isSelected || CalendarDateUtils.isToday(day) ? 2 : 0)
                    }

                Text(CalendarDateUtils.dayNumber(for: day))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isCurrentMonth ? .primary : .tertiary)
                    .padding(10)
            }
            .frame(maxWidth: .infinity, minHeight: 88, maxHeight: 88, alignment: .topLeading)
        }
        .buttonStyle(.plain)
    }

    private var borderColor: Color {
        if isSelected {
            return .blue
        }

        if CalendarDateUtils.isToday(day) {
            return .accentColor
        }

        return .clear
    }
}

#Preview {
    NavigationStack {
        CalendarPageView()
    }
}
