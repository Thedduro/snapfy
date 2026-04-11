import SwiftUI

enum AppTab: Hashable {
    case library
    case calendar
    case settings
}

struct ContentView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var workspaceStore: WorkspaceStore
    @State private var selectedTab: AppTab = .calendar
    @State private var activeWorkspaceModal: WorkspaceModal?

    var body: some View {
        Group {
            if sessionStore.currentUser == nil {
                NavigationStack {
                    SignUpView()
                }
            } else {
                ZStack {
                    TabView(selection: $selectedTab) {
                        NavigationStack {
                            LibraryPageView()
                        }
                        .tabItem {
                            Label("갤러리", systemImage: "photo.stack")
                        }
                        .tag(AppTab.library)

                        NavigationStack {
                            WorkspaceListView(activeModal: $activeWorkspaceModal)
                        }
                        .tabItem {
                            Label("캘린더", systemImage: "calendar")
                        }
                        .tag(AppTab.calendar)

                        NavigationStack {
                            SettingsPageView()
                        }
                        .tabItem {
                            Label("설정", systemImage: "gearshape")
                        }
                        .tag(AppTab.settings)
                    }

                    if let activeWorkspaceModal {
                        WorkspaceCenteredPopup(onClose: closeWorkspaceModal) {
                            workspacePopupContent(for: activeWorkspaceModal)
                        }
                        .zIndex(10)
                    }
                }
            }
        }
        .task(id: sessionStore.currentUser?.id) {
            await workspaceStore.syncSession(user: sessionStore.currentUser)
        }
    }

    @ViewBuilder
    private func workspacePopupContent(for modal: WorkspaceModal) -> some View {
        switch modal {
        case .create:
            WorkspaceSetupView(
                presentation: .popup,
                onDismiss: closeWorkspaceModal
            )
        case .join:
            JoinWorkspaceView(
                presentation: .popup,
                onDismiss: closeWorkspaceModal
            )
        }
    }

    private func closeWorkspaceModal() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
            activeWorkspaceModal = nil
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SessionStore())
        .environmentObject(WorkspaceStore())
}
