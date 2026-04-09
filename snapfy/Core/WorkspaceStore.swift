import Combine
import Foundation
import SwiftData

@MainActor
final class WorkspaceStore: ObservableObject {
    @Published private(set) var currentWorkspace: WorkspaceSummary?

    private let container: ModelContainer
    private let currentWorkspaceDefaultsKey = "workspace.currentWorkspaceID"

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

            if let workspace = try context.fetch(selectedDescriptor).first {
                persistCurrentWorkspace(workspace)
                return
            }
        }

        var fallbackDescriptor = FetchDescriptor<WorkspaceRecord>(
            predicate: #Predicate { $0.ownerUserID == ownerUserID },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        fallbackDescriptor.fetchLimit = 1

        guard let workspace = try context.fetch(fallbackDescriptor).first else {
            UserDefaults.standard.removeObject(forKey: currentWorkspaceDefaultsKey)
            currentWorkspace = nil
            return
        }

        persistCurrentWorkspace(workspace)
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
}

enum WorkspaceError: LocalizedError {
    case invalidName
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidName:
            return "워크스페이스 이름은 2자 이상 입력해주세요."
        case .unknown:
            return "워크스페이스를 생성하지 못했습니다."
        }
    }
}
