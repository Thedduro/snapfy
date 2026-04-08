import SwiftUI

struct CalendarPageView: View {
    @State private var displayedMonth = CalendarDateUtils.startOfMonth(for: .now)
    @State private var selectedDate = Date()

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                monthHeader
                selectedDateSummary

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

    private var selectedDateSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("선택한 날짜")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(selectedDate.formatted(.dateTime.year().month(.wide).day()))
                .font(.headline)

            Text("이 날짜에 업로드된 사진과 비디오를 여기에 연결할 예정입니다.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
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
            VStack(alignment: .leading, spacing: 6) {
                Text(CalendarDateUtils.dayNumber(for: day))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isCurrentMonth ? .primary : .tertiary)

                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.blue.opacity(0.14) : Color(.secondarySystemBackground))
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
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(borderColor, lineWidth: isSelected || CalendarDateUtils.isToday(day) ? 2 : 0)
                    }
            }
            .frame(maxWidth: .infinity, minHeight: 102, alignment: .topLeading)
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
