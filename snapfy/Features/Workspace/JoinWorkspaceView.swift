import SwiftUI

private enum InviteInputMode: String, CaseIterable, Identifiable {
    case link
    case code

    var id: String { rawValue }

    var title: String {
        switch self {
        case .link: return "Link"
        case .code: return "Code"
        }
    }

    var placeholder: String {
        switch self {
        case .link: return "https://snapfy.app/invite/..."
        case .code: return "ABC123"
        }
    }

    var helper: String {
        switch self {
        case .link: return "공유받은 초대 링크를 그대로 붙여넣으세요."
        case .code: return "초대 코드만 받았다면 코드만 입력하세요."
        }
    }
}

struct JoinWorkspaceView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var workspaceStore: WorkspaceStore

    @State private var inputMode: InviteInputMode = .link
    @State private var inviteInput = ""
    @State private var errorMessage: String?
    @State private var isSubmitting = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    WorkspaceHeroSection(
                        eyebrow: "Join",
                        title: "Join a shared space",
                        subtitle: "Enter an invite link or code to continue.",
                        symbol: "person.2.fill"
                    )

                    WorkspaceSurfaceCard {
                        WorkspaceModePicker(mode: $inputMode)

                        WorkspaceFieldShell(
                            title: inputMode == .link ? "Invite Link" : "Invite Code",
                            hint: inputMode.helper,
                            icon: inputMode == .link ? "link" : "number.square.fill",
                            isFocused: isInputFocused
                        ) {
                            TextField(inputMode.placeholder, text: $inviteInput)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .focused($isInputFocused)
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .padding(.horizontal, 2)
                        }

                        WorkspacePrimaryButton(
                            title: "Join Workspace",
                            isLoading: isSubmitting,
                            isDisabled: isSubmitting
                        ) {
                            joinWorkspace()
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 36)
            }
            .scrollIndicators(.hidden)
            .background(WorkspaceOnboardingBackground())
            .onTapGesture {
                isInputFocused = false
            }
            .navigationTitle("공간 참여하기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("닫기") {
                        dismiss()
                    }
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

private struct WorkspaceModePicker: View {
    @Binding var mode: InviteInputMode

    var body: some View {
        HStack(spacing: 8) {
            ForEach(InviteInputMode.allCases) { candidate in
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                        mode = candidate
                    }
                } label: {
                    Text(candidate.title)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(
                            mode == candidate
                            ? Color.white
                            : WorkspaceOnboardingPalette.primary.opacity(0.95)
                        )
                        .background(
                            Capsule(style: .continuous)
                                .fill(
                                    mode == candidate
                                    ? AnyShapeStyle(
                                        LinearGradient(
                                            colors: [
                                                WorkspaceOnboardingPalette.primary,
                                                WorkspaceOnboardingPalette.secondary
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    : AnyShapeStyle(Color.white.opacity(0.7))
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(
            Capsule(style: .continuous)
                .fill(WorkspaceOnboardingPalette.mintGlow.opacity(0.5))
        )
    }
}

#Preview {
    JoinWorkspaceView()
        .environmentObject(SessionStore())
        .environmentObject(WorkspaceStore())
}
