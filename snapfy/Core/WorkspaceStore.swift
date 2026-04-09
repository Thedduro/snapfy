import Combine
import Foundation
import SwiftData

@MainActor
final class WorkspaceStore: ObservableObject {
    @Published private(set) var currentWorkspace: WorkspaceSummary?

    private let container: ModelContainer
    private let currentWorkspaceDefaultsKey = "workspace.currentWorkspaceID"
    private let inviteScheme = "snapfy"

    init(container: ModelContainer? = nil) {
        self.container = container ?? PersistenceController.shared
    }

    func syncSession(user: AuthenticatedUser?) {
        guard let user else {
            currentWorkspace = nil
            UserDefaults.standard.removeObject(forKey: currentWorkspaceDefaultsKey)
            return
        }

        do {
            try restoreWorkspace(for: user.id)
        } catch {
            currentWorkspace = nil
        }
    }

    func createWorkspace(name: String, ownerUserID: UUID) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedName.count >= 2 else {
            throw WorkspaceError.invalidName
        }

        let context = ModelContext(container)
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

        persistCurrentWorkspace(workspace)
    }

    func restoreWorkspace(for ownerUserID: UUID) throws {
        let context = ModelContext(container)

        if let storedID = storedWorkspaceID() {
            var selectedDescriptor = FetchDescriptor<WorkspaceRecord>(
                predicate: #Predicate { $0.id == storedID }
            )
            selectedDescriptor.fetchLimit = 1

            if let workspace = try context.fetch(selectedDescriptor).first,
               try isMember(of: workspace.id, userID: ownerUserID, context: context) {
                persistCurrentWorkspace(workspace)
                return
            }
        }

        var membershipDescriptor = FetchDescriptor<WorkspaceMemberRecord>(
            predicate: #Predicate { $0.userID == ownerUserID },
            sortBy: [SortDescriptor(\.joinedAt, order: .reverse)]
        )
        membershipDescriptor.fetchLimit = 1

        guard let membership = try context.fetch(membershipDescriptor).first else {
            UserDefaults.standard.removeObject(forKey: currentWorkspaceDefaultsKey)
            currentWorkspace = nil
            return
        }
        let workspaceID = membership.workspaceID

        var workspaceDescriptor = FetchDescriptor<WorkspaceRecord>(
            predicate: #Predicate { $0.id == workspaceID }
        )
        workspaceDescriptor.fetchLimit = 1

        guard let workspace = try context.fetch(workspaceDescriptor).first else {
            UserDefaults.standard.removeObject(forKey: currentWorkspaceDefaultsKey)
            currentWorkspace = nil
            return
        }

        persistCurrentWorkspace(workspace)
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

        currentWorkspace = WorkspaceSummary(
            id: workspace.id,
            name: workspace.name,
            ownerUserID: workspace.ownerUserID,
            inviteToken: workspace.inviteToken
        )
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
    case workspaceNotFound
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidName:
            return "워크스페이스 이름은 2자 이상 입력해주세요."
        case .invalidInvite:
            return "유효한 초대 링크가 아닙니다."
        case .workspaceNotFound:
            return "현재 워크스페이스를 찾을 수 없습니다."
        case .unknown:
            return "워크스페이스를 생성하지 못했습니다."
        }
    }
}
