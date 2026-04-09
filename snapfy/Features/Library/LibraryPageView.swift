import SwiftUI

struct LibraryPageView: View {
    @EnvironmentObject private var workspaceStore: WorkspaceStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("최근 미디어")
                .font(.largeTitle.bold())

            Text(workspaceDescription)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
        .navigationTitle("최근 미디어")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var workspaceDescription: String {
        if let workspaceName = workspaceStore.currentWorkspace?.name {
            return "\(workspaceName) 워크스페이스의 최근 업로드를 보여주는 페이지입니다."
        }

        return "현재 선택된 워크스페이스가 없습니다."
    }
}

#Preview {
    NavigationStack {
        LibraryPageView()
            .environmentObject(WorkspaceStore())
    }
}
