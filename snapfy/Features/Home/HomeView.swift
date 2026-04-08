import SwiftUI

struct HomeView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Snapfy")
                        .font(.largeTitle.bold())

                    Text("공유 앨범의 홈 화면에서 원하는 페이지로 바로 이동합니다.")
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 16) {
                    HomeNavigationCard(
                        title: "캘린더",
                        subtitle: "날짜별 사진과 비디오를 모아보는 메인 화면",
                        systemImage: "calendar"
                    ) {
                        CalendarPageView()
                    }

                    HomeNavigationCard(
                        title: "최근 미디어",
                        subtitle: "최근 업로드한 사진과 비디오를 빠르게 확인",
                        systemImage: "photo.stack"
                    ) {
                        LibraryPageView()
                    }

                    HomeNavigationCard(
                        title: "공간 설정",
                        subtitle: "공간 정보와 설정 항목을 정리할 페이지",
                        systemImage: "gearshape"
                    ) {
                        SettingsPageView()
                    }
                }
            }
            .padding(24)
        }
        .navigationTitle("홈")
    }
}

private struct HomeNavigationCard<Destination: View>: View {
    let title: String
    let subtitle: String
    let systemImage: String
    @ViewBuilder let destination: Destination

    init(
        title: String,
        subtitle: String,
        systemImage: String,
        @ViewBuilder destination: () -> Destination
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.destination = destination()
    }

    var body: some View {
        NavigationLink {
            destination
        } label: {
            HStack(spacing: 16) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding(18)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
