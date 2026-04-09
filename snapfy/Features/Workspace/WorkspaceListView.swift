import SwiftUI

struct WorkspaceListView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var workspaceStore: WorkspaceStore

    @State private var selectedWorkspace: WorkspaceSummary?
    @State private var isPresentingWorkspaceSetup = false
    @State private var isPresentingJoinWorkspace = false

    var body: some View {
        List {
            Section {
                if workspaceStore.workspaces.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("아직 만든 워크스페이스가 없습니다.")
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
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(workspace.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text("캘린더 열기")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } header: {
                Text("워크스페이스")
            }
        }
        .navigationTitle("캘린더")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if workspaceStore.canCreateWorkspace {
                        Button("새 공간 만들기", systemImage: "plus.square.on.square") {
                            isPresentingWorkspaceSetup = true
                        }
                    }

                    Button("공간 참여하기", systemImage: "person.badge.plus") {
                        isPresentingJoinWorkspace = true
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
        .sheet(isPresented: $isPresentingWorkspaceSetup) {
            WorkspaceSetupView()
                .environmentObject(sessionStore)
                .environmentObject(workspaceStore)
        }
        .sheet(isPresented: $isPresentingJoinWorkspace) {
            JoinWorkspaceView()
                .environmentObject(sessionStore)
                .environmentObject(workspaceStore)
        }
        .task(id: sessionStore.currentUser?.id) {
            workspaceStore.syncSession(user: sessionStore.currentUser)
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
