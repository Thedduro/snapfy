import SwiftUI

struct LibraryPageView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("최근 미디어")
                .font(.largeTitle.bold())

            Text("최근 업로드한 사진과 비디오를 빠르게 확인하는 페이지입니다.")
                .foregroundStyle(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
        .navigationTitle("최근 미디어")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        LibraryPageView()
    }
}
