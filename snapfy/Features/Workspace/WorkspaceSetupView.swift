import SwiftUI

struct WorkspaceSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var workspaceStore: WorkspaceStore

    let presentation: WorkspaceOnboardingPresentation
    let onDismiss: (() -> Void)?

    @State private var workspaceName = ""
    @State private var errorMessage: String?
    @State private var isSubmitting = false
    @FocusState private var isNameFocused: Bool

    init(
        presentation: WorkspaceOnboardingPresentation = .fullScreen,
        onDismiss: (() -> Void)? = nil
    ) {
        self.presentation = presentation
        self.onDismiss = onDismiss
    }

    var body: some View {
        Group {
            switch presentation {
            case .fullScreen:
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        contentCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
                .scrollIndicators(.hidden)
                .background(WorkspaceOnboardingBackground())
                .toolbar(.hidden, for: .navigationBar)

            case .popup:
                contentCard
                    .padding(8)
            }
        }
        .onTapGesture {
            isNameFocused = false
        }
    }

    private var contentCard: some View {
        WorkspaceSurfaceCard {
            WorkspaceFieldShell(
                title: "캘린더 이름",
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
                title: "캘린더 시작",
                isLoading: isSubmitting,
                isDisabled: isSubmitting
            ) {
                createWorkspace()
            }
        }
    }

    private func closeView() {
        if let onDismiss {
            onDismiss()
        } else {
            dismiss()
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
                closeView()
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
