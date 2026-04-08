import SwiftUI

struct CalendarPageView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("캘린더")
                .font(.largeTitle.bold())

            Text("날짜별 사진과 비디오를 모아보는 메인 캘린더 페이지입니다.")
                .foregroundStyle(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
        .navigationTitle("캘린더")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        CalendarPageView()
    }
}
