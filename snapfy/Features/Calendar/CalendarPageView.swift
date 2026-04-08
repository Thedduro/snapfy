import SwiftUI

struct CalendarPageView: View {
    @State private var displayedMonth = CalendarDateUtils.startOfMonth(for: .now)

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
                            isCurrentMonth: CalendarDateUtils.isInMonth(day, month: displayedMonth)
                        )
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle("캘린더")
        .navigationBarTitleDisplayMode(.inline)
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

            VStack(spacing: 4) {
                Text(CalendarDateUtils.monthTitle(for: displayedMonth))
                    .font(.title3.bold())
                Text("사진과 비디오가 쌓일 메인 캘린더")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

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

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(CalendarDateUtils.dayNumber(for: day))
                .font(.caption.weight(.semibold))
                .foregroundStyle(isCurrentMonth ? .primary : .tertiary)

            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
                .frame(height: 72)
                .overlay {
                    VStack(spacing: 6) {
                        Image(systemName: "photo")
                            .font(.headline)
                        Text("비어 있음")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
                .overlay {
                    if CalendarDateUtils.isToday(day) {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.accentColor, lineWidth: 2)
                    }
                }
        }
        .frame(maxWidth: .infinity, minHeight: 102, alignment: .topLeading)
    }
}

#Preview {
    NavigationStack {
        CalendarPageView()
    }
}
