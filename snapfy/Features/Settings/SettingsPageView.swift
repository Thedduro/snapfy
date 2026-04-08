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
                        Text(currentUser.displayName)
                            .font(.title3.bold())
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

            Text("Firebase 연동 시 이메일, 프로필 이미지, 멤버 관리를 확장합니다.")
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
