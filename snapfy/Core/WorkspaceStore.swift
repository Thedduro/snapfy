import Combine
import Foundation
import SwiftData

@MainActor
final class WorkspaceStore: ObservableObject {
    @Published private(set) var workspaces: [WorkspaceSummary] = []
    @Published private(set) var currentWorkspace: WorkspaceSummary?

    private let container: ModelContainer
    private let currentWorkspaceDefaultsKey = "workspace.currentWorkspaceID"
    private let inviteScheme = "snapfy"
    private let maxOwnedWorkspaceCount = 5
    private var currentUserID: UUID?

    init(container: ModelContainer? = nil) {
        self.container = container ?? PersistenceController.shared
    }

    func syncSession(user: AuthenticatedUser?) {
        guard let user else {
            currentUserID = nil
            workspaces = []
            currentWorkspace = nil
            UserDefaults.standard.removeObject(forKey: currentWorkspaceDefaultsKey)
            return
        }
        currentUserID = user.id

        do {
            try loadWorkspaces(for: user.id)
        } catch {
            workspaces = []
            currentWorkspace = nil
        }
    }

    func createWorkspace(name: String, ownerUserID: UUID) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedName.count >= 2 else {
            throw WorkspaceError.invalidName
        }

        let context = ModelContext(container)
        let ownedWorkspaceCount = try context.fetchCount(
            FetchDescriptor<WorkspaceRecord>(
                predicate: #Predicate { $0.ownerUserID == ownerUserID }
            )
        )

        guard ownedWorkspaceCount < maxOwnedWorkspaceCount else {
            throw WorkspaceError.workspaceLimitReached
        }

        let workspace = WorkspaceRecord(
            name: trimmedName,
            ownerUserID: ownerUserID
        )

        context.insert(workspace)
        context.insert(
            WorkspaceMemberRecord(
                workspaceID: workspace.id,
                userID: ownerUserID,
                role: "owner"
            )
        )

        do {
            try context.save()
        } catch {
            throw WorkspaceError.unknown
        }

        try loadWorkspaces(for: ownerUserID)
        persistCurrentWorkspace(workspace)
    }

    func loadWorkspaces(for userID: UUID) throws {
        let context = ModelContext(container)
        var membershipDescriptor = FetchDescriptor<WorkspaceMemberRecord>(
            predicate: #Predicate { $0.userID == userID },
            sortBy: [SortDescriptor(\.joinedAt, order: .reverse)]
        )
        let memberships = try context.fetch(membershipDescriptor)

        guard !memberships.isEmpty else {
            workspaces = []
            UserDefaults.standard.removeObject(forKey: currentWorkspaceDefaultsKey)
            currentWorkspace = nil
            return
        }

        let workspaceIDs = Set(memberships.map(\.workspaceID))
        var resolvedWorkspaces: [WorkspaceSummary] = []

        for workspaceID in workspaceIDs {
            var workspaceDescriptor = FetchDescriptor<WorkspaceRecord>(
                predicate: #Predicate { $0.id == workspaceID }
            )
            workspaceDescriptor.fetchLimit = 1

            if let workspace = try context.fetch(workspaceDescriptor).first {
                resolvedWorkspaces.append(
                    WorkspaceSummary(
                        id: workspace.id,
                        name: workspace.name,
                        ownerUserID: workspace.ownerUserID,
                        inviteToken: workspace.inviteToken
                    )
                )
            }
        }

        workspaces = resolvedWorkspaces.sorted { lhs, rhs in
            lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }

        if let storedID = storedWorkspaceID(),
           let storedWorkspace = workspaces.first(where: { $0.id == storedID }) {
            currentWorkspace = storedWorkspace
        } else {
            currentWorkspace = nil
            UserDefaults.standard.removeObject(forKey: currentWorkspaceDefaultsKey)
        }
    }

    func inviteLink() throws -> String {
        guard let currentWorkspace else {
            throw WorkspaceError.workspaceNotFound
        }
        let currentWorkspaceID = currentWorkspace.id

        let context = ModelContext(container)
        var descriptor = FetchDescriptor<WorkspaceRecord>(
            predicate: #Predicate { $0.id == currentWorkspaceID }
        )
        descriptor.fetchLimit = 1

        guard let workspace = try context.fetch(descriptor).first else {
            throw WorkspaceError.workspaceNotFound
        }

        if workspace.inviteToken == nil {
            workspace.inviteToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
            do {
                try context.save()
            } catch {
                throw WorkspaceError.unknown
            }
        }

        persistCurrentWorkspace(workspace)

        return "\(inviteScheme)://invite?token=\(workspace.inviteToken ?? "")"
    }

    func joinWorkspace(withInviteToken token: String, userID: UUID) throws {
        let context = ModelContext(container)
        var workspaceDescriptor = FetchDescriptor<WorkspaceRecord>(
            predicate: #Predicate { $0.inviteToken == token }
        )
        workspaceDescriptor.fetchLimit = 1

        guard let workspace = try context.fetch(workspaceDescriptor).first else {
            throw WorkspaceError.invalidInvite
        }

        if try !isMember(of: workspace.id, userID: userID, context: context) {
            context.insert(
                WorkspaceMemberRecord(
                    workspaceID: workspace.id,
                    userID: userID,
                    role: "member"
                )
            )

            do {
                try context.save()
            } catch {
                throw WorkspaceError.unknown
            }
        }

        try loadWorkspaces(for: userID)
        persistCurrentWorkspace(workspace)
    }

    func handleIncomingURL(_ url: URL, userID: UUID) throws {
        guard url.scheme == inviteScheme,
              url.host == "invite",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let token = components.queryItems?.first(where: { $0.name == "token" })?.value,
              !token.isEmpty else {
            throw WorkspaceError.invalidInvite
        }

        try joinWorkspace(withInviteToken: token, userID: userID)
    }

    func selectWorkspace(_ workspace: WorkspaceSummary) {
        UserDefaults.standard.set(
            workspace.id.uuidString,
            forKey: currentWorkspaceDefaultsKey
        )
        currentWorkspace = workspace
    }

    var canCreateWorkspace: Bool {
        ownedWorkspaceCount < maxOwnedWorkspaceCount
    }

    var ownedWorkspaceCount: Int {
        guard let currentUserID else {
            return 0
        }

        return workspaces.filter { $0.ownerUserID == currentUserID }.count
    }

    private func storedWorkspaceID() -> UUID? {
        guard let rawValue = UserDefaults.standard.string(forKey: currentWorkspaceDefaultsKey) else {
            return nil
        }

        return UUID(uuidString: rawValue)
    }

    private func persistCurrentWorkspace(_ workspace: WorkspaceRecord) {
        UserDefaults.standard.set(
            workspace.id.uuidString,
            forKey: currentWorkspaceDefaultsKey
        )

        let summary = WorkspaceSummary(
            id: workspace.id,
            name: workspace.name,
            ownerUserID: workspace.ownerUserID,
            inviteToken: workspace.inviteToken
        )
        currentWorkspace = summary

        if let index = workspaces.firstIndex(where: { $0.id == summary.id }) {
            workspaces[index] = summary
        } else {
            workspaces.append(summary)
            workspaces.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }
    }

    private func isMember(
        of workspaceID: UUID,
        userID: UUID,
        context: ModelContext
    ) throws -> Bool {
        var descriptor = FetchDescriptor<WorkspaceMemberRecord>(
            predicate: #Predicate {
                $0.workspaceID == workspaceID && $0.userID == userID
            }
        )
        descriptor.fetchLimit = 1

        return try context.fetch(descriptor).first != nil
    }
}

enum WorkspaceError: LocalizedError {
    case invalidName
    case invalidInvite
    case workspaceLimitReached
    case workspaceNotFound
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidName:
            return "워크스페이스 이름은 2자 이상 입력해주세요."
        case .invalidInvite:
            return "유효한 초대 링크가 아닙니다."
        case .workspaceLimitReached:
            return "워크스페이스는 최대 5개까지 만들 수 있습니다."
        case .workspaceNotFound:
            return "현재 워크스페이스를 찾을 수 없습니다."
        case .unknown:
            return "워크스페이스를 생성하지 못했습니다."
        }
    }
}
