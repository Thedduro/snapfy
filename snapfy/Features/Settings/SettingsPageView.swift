import SwiftUI

struct SettingsPageView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @State private var isPresentingProfileEdit = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let currentUser = sessionStore.currentUser {
                HStack(spacing: 16) {
                    ProfileAvatarView(
                        imageData: currentUser.profileImageData,
                        size: 72
                    )

                    VStack(alignment: .leading, spacing: 10) {
                        Text(currentUser.resolvedDisplayName)
                            .font(.title3.bold())
                        Text(currentUser.email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))

                Button("프로필 변경") {
                    isPresentingProfileEdit = true
                }
                .buttonStyle(.borderedProminent)

                Button("로그아웃") {
                    sessionStore.signOut()
                }
                .buttonStyle(.bordered)
            } else {
                Text("로그인된 사용자가 없습니다.")
            }

            Text("다음 단계에서 클라우드 인증과 원격 저장 구조를 연결할 예정입니다.")
                .foregroundStyle(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
        .navigationTitle("프로필")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isPresentingProfileEdit) {
            if let currentUser = sessionStore.currentUser {
                ProfileEditView(currentUser: currentUser)
                    .environmentObject(sessionStore)
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsPageView()
            .environmentObject(SessionStore())
    }
}
