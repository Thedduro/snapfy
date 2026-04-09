import Foundation

@MainActor
protocol WorkspaceManaging: AnyObject {
    var workspaces: [WorkspaceSummary] { get }
    var currentWorkspace: WorkspaceSummary? { get }
    var canCreateWorkspace: Bool { get }
    var ownedWorkspaceCount: Int { get }

    func syncSession(user: AuthenticatedUser?) async
    func createWorkspace(name: String, ownerUserID: UUID) async throws
    func inviteLink() async throws -> String
    func joinWorkspace(withInput input: String, userID: UUID) async throws
    func handleIncomingURL(_ url: URL, userID: UUID) async throws
    func selectWorkspace(_ workspace: WorkspaceSummary)
}
