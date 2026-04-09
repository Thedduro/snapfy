import SwiftUI
import UIKit

struct SettingsPageView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var workspaceStore: WorkspaceStore
    @State private var isPresentingProfileEdit = false
    @State private var copiedInviteMessage: String?

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

                if let currentWorkspace = workspaceStore.currentWorkspace {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("현재 워크스페이스")
                            .font(.subheadline.weight(.semibold))
                        Text(currentWorkspace.name)
                            .font(.title3.bold())

                        Button("초대 링크 복사") {
                            copyInviteLink()
                        }
                        .buttonStyle(.bordered)

                        if let copiedInviteMessage {
                            Text(copiedInviteMessage)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
                }

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

    private func copyInviteLink() {
        do {
            let inviteLink = try workspaceStore.inviteLink()
            UIPasteboard.general.string = inviteLink
            copiedInviteMessage = "초대 링크를 복사했습니다."
        } catch let error as WorkspaceError {
            copiedInviteMessage = error.errorDescription
        } catch {
            copiedInviteMessage = WorkspaceError.unknown.errorDescription
        }
    }
}

#Preview {
    NavigationStack {
        SettingsPageView()
            .environmentObject(SessionStore())
    }
}
