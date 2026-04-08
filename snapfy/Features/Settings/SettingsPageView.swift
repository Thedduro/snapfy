import SwiftUI

struct SettingsPageView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("공간 설정")
                .font(.largeTitle.bold())

            Text("앨범 설정과 멤버 관련 항목이 들어갈 내부 페이지입니다.")
                .foregroundStyle(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
        .navigationTitle("공간 설정")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsPageView()
    }
}
