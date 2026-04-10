import SwiftUI

struct JoinWorkspaceView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var workspaceStore: WorkspaceStore

    @State private var inviteInput = ""
    @State private var errorMessage: String?
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("초대 링크 또는 코드")
                        .font(.headline)

                    TextField("링크 붙여넣기 또는 코드 입력", text: $inviteInput, axis: .vertical)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
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
            .navigationTitle("공간 참여하기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("닫기") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("참여") {
                        joinWorkspace()
                    }
                    .disabled(isSubmitting)
                }
            }
        }
    }

    private func joinWorkspace() {
        guard let userID = sessionStore.currentUser?.id else { return }

        errorMessage = nil
        isSubmitting = true

        Task {
            defer {
                isSubmitting = false
            }

            do {
                try await workspaceStore.joinWorkspace(withInput: inviteInput, userID: userID)
                dismiss()
            } catch let error as WorkspaceError {
                errorMessage = error.errorDescription
            } catch {
                errorMessage = WorkspaceError.unknown.errorDescription
            }
        }
    }
}

#Preview {
    JoinWorkspaceView()
        .environmentObject(SessionStore())
        .environmentObject(WorkspaceStore())
}
