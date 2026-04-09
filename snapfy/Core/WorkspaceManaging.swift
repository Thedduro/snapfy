import Foundation

@MainActor
protocol WorkspaceManaging: AnyObject {
    var workspaces: [WorkspaceSummary] { get }
    var currentWorkspace: WorkspaceSummary? { get }
    var canCreateWorkspace: Bool { get }
    var ownedWorkspaceCount: Int { get }

    func syncSession(user: AuthenticatedUser?)
    func createWorkspace(name: String, ownerUserID: UUID) throws
    func inviteLink() throws -> String
    func joinWorkspace(withInput input: String, userID: UUID) throws
    func handleIncomingURL(_ url: URL, userID: UUID) throws
    func selectWorkspace(_ workspace: WorkspaceSummary)
}
