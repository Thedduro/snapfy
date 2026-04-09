import SwiftUI

struct WorkspaceSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var workspaceStore: WorkspaceStore

    @State private var workspaceName = ""
    @State private var errorMessage: String?
    @State private var isSubmitting = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("워크스페이스 만들기")
                        .font(.largeTitle.bold())

                    Text("친구와 함께 사용할 첫 캘린더 공간 이름을 정해주세요.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("워크스페이스 이름")
                            .font(.subheadline.weight(.semibold))

                        TextField("예: 우리 추억 캘린더", text: $workspaceName)
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

                    Button {
                        createWorkspace()
                    } label: {
                        HStack {
                            Spacer()
                            if isSubmitting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("워크스페이스 시작")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                    .background(Color.black, in: RoundedRectangle(cornerRadius: 14))
                    .disabled(isSubmitting)
                }
                .padding(20)
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func createWorkspace() {
        guard let userID = sessionStore.currentUser?.id else { return }

        errorMessage = nil
        isSubmitting = true

        Task {
            defer {
                isSubmitting = false
            }

            do {
                try await workspaceStore.createWorkspace(
                    name: workspaceName,
                    ownerUserID: userID
                )
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
    WorkspaceSetupView()
        .environmentObject(SessionStore())
        .environmentObject(WorkspaceStore())
}
