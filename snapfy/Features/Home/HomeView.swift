import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Snapfy")
                .font(.largeTitle.bold())

            Text("공유 앨범 홈 화면의 메인 진입점입니다.")
                .font(.body)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
        .navigationTitle("홈")
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
