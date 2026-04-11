import SwiftUI

struct WorkspaceListView: View {
    private enum WorkspaceModal: Identifiable {
        case create
        case join

        var id: Int {
            switch self {
            case .create: return 0
            case .join: return 1
            }
        }
    }

    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var workspaceStore: WorkspaceStore

    @State private var selectedWorkspace: WorkspaceSummary?
    @State private var activeModal: WorkspaceModal?

    var body: some View {
        ZStack {
            List {
                Section {
                    if workspaceStore.workspaces.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("아직 만든 캘린더가 없습니다.")
                                .font(.headline)
                            Text("새 스페이스를 만든 뒤 캘린더를 선택할 수 있습니다.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)
                    } else {
                        ForEach(workspaceStore.workspaces, id: \.id) { workspace in
                            Button {
                                workspaceStore.selectWorkspace(workspace)
                                selectedWorkspace = workspace
                            } label: {
                                HStack {
                                    Text(workspace.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Image("SnapfyLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 102)
                            .accessibilityLabel("Snapfy")
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 4)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        if workspaceStore.canCreateWorkspace {
                            Button("만들기", systemImage: "plus.square.on.square") {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                                    activeModal = .create
                                }
                            }
                        }

                        Button("참여하기", systemImage: "person.badge.plus") {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                                activeModal = .join
                            }
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationDestination(item: $selectedWorkspace) { workspace in
                CalendarPageView()
                    .navigationTitle(workspace.name)
                    .navigationBarTitleDisplayMode(.inline)
            }
            .task(id: sessionStore.currentUser?.id) {
                await workspaceStore.syncSession(user: sessionStore.currentUser)
            }

            if let activeModal {
                WorkspaceCenteredPopup(onClose: closeModal) {
                    popupContent(for: activeModal)
                }
                .zIndex(1)
            }
        }
    }

    @ViewBuilder
    private func popupContent(for modal: WorkspaceModal) -> some View {
        switch modal {
        case .create:
            WorkspaceSetupView(
                presentation: .popup,
                onDismiss: closeModal
            )
        case .join:
            JoinWorkspaceView(
                presentation: .popup,
                onDismiss: closeModal
            )
        }
    }

    private func closeModal() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
            activeModal = nil
        }
    }
}

#Preview {
    NavigationStack {
        WorkspaceListView()
            .environmentObject(SessionStore())
            .environmentObject(WorkspaceStore())
    }
}
