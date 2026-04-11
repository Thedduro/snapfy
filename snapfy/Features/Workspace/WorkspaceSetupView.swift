import SwiftUI

struct WorkspaceSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var workspaceStore: WorkspaceStore

    @State private var workspaceName = ""
    @State private var errorMessage: String?
    @State private var isSubmitting = false
    @FocusState private var isNameFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                WorkspaceHeroSection(
                    eyebrow: "Create",
                    title: "Create your workspace",
                    subtitle: "Start a new shared memory space with friends and family.",
                    symbol: "sparkles"
                )

                WorkspaceSurfaceCard {
                    WorkspaceFieldShell(
                        title: "Workspace Name",
                        hint: "다른 멤버가 한눈에 알아볼 수 있는 이름이 좋아요.",
                        icon: "person.3.sequence.fill",
                        isFocused: isNameFocused
                    ) {
                        TextField("예: 우리 추억 캘린더", text: $workspaceName)
                            .focused($isNameFocused)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 2)
                    }

                    WorkspacePrimaryButton(
                        title: "Start Workspace",
                        isLoading: isSubmitting,
                        isDisabled: isSubmitting
                    ) {
                        createWorkspace()
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background(WorkspaceOnboardingBackground())
        .onTapGesture {
            isNameFocused = false
        }
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
