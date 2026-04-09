import PhotosUI
import SwiftUI
import UIKit

struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var sessionStore: SessionStore

    let currentUser: AuthenticatedUser
    @State private var displayName: String
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImageData: Data?
    @State private var errorMessage: String?
    @State private var isSaving = false

    init(currentUser: AuthenticatedUser) {
        self.currentUser = currentUser
        _displayName = State(initialValue: currentUser.displayName ?? "")
        _profileImageData = State(initialValue: currentUser.profileImageData)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 16) {
                    ProfileAvatarView(imageData: profileImageData, size: 84)

                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Text("프로필 사진 변경")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color(.secondarySystemBackground), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("이메일")
                        .font(.subheadline.weight(.semibold))

                    Text(currentUser.email)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("표시 이름")
                        .font(.subheadline.weight(.semibold))

                    TextField("표시 이름(선택)", text: $displayName)
                        .padding(14)
                        .background(
                            Color(.secondarySystemBackground),
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Spacer()
            }
            .padding(20)
            .navigationTitle("프로필 변경")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("닫기") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("저장") {
                        saveProfile()
                    }
                    .disabled(isSaving)
                }
            }
        }
        .task(id: selectedPhoto) {
            await loadSelectedPhoto()
        }
    }

    private func saveProfile() {
        errorMessage = nil
        isSaving = true

        defer {
            isSaving = false
        }

        do {
            try sessionStore.updateProfile(
                displayName: displayName,
                profileImageData: profileImageData
            )
            dismiss()
        } catch let error as AuthError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = AuthError.unknown.errorDescription
        }
    }

    private func loadSelectedPhoto() async {
        guard let selectedPhoto else { return }

        do {
            guard let data = try await selectedPhoto.loadTransferable(type: Data.self),
                  let image = UIImage(data: data),
                  let jpegData = image.jpegData(compressionQuality: 0.85) else {
                return
            }

            profileImageData = jpegData
        } catch {
            errorMessage = "프로필 이미지를 불러오지 못했습니다."
        }
    }
}

#Preview {
    ProfileEditView(
        currentUser: AuthenticatedUser(
            id: UUID(),
            email: "hello@example.com",
            displayName: "테스트 유저",
            profileImageData: nil
        )
    )
    .environmentObject(SessionStore())
}
