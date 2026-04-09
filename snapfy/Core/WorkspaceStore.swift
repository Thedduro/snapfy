import Combine
import FirebaseAuth
import FirebaseFirestore
import Foundation

@MainActor
final class WorkspaceStore: ObservableObject, WorkspaceManaging {
    @Published private(set) var workspaces: [WorkspaceSummary] = []
    @Published private(set) var currentWorkspace: WorkspaceSummary?

    private let firestore: Firestore
    private let currentWorkspaceDefaultsKey = "workspace.currentWorkspaceID"
    private let inviteScheme = "snapfy"
    private let maxOwnedWorkspaceCount = 5
    private var currentUserID: String?

    init(firestore: Firestore? = nil) {
        self.firestore = firestore ?? FirebaseBootstrap.firestore
    }

    func syncSession(user: AuthenticatedUser?) async {
        guard let user else {
            currentUserID = nil
            workspaces = []
            currentWorkspace = nil
            UserDefaults.standard.removeObject(forKey: currentWorkspaceDefaultsKey)
            return
        }

        currentUserID = Auth.auth().currentUser?.uid

        do {
            try await loadWorkspaces(for: user.id)
        } catch {
            workspaces = []
            currentWorkspace = nil
        }
    }

    func createWorkspace(name: String, ownerUserID: UUID) async throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedName.count >= 2 else {
            throw WorkspaceError.invalidName
        }

        let ownerID = try requireFirebaseUserID()

        do {
            let ownedSnapshot = try await firestore
                .collection("workspaces")
                .whereField("ownerUserID", isEqualTo: ownerID)
                .getDocuments()

            guard ownedSnapshot.documents.count < maxOwnedWorkspaceCount else {
                throw WorkspaceError.workspaceLimitReached
            }

            let workspaceID = UUID()
            let inviteToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
            let now = Date()

            let workspacePayload: [String: Any] = [
                "name": trimmedName,
                "ownerUserID": ownerID,
                "inviteToken": inviteToken,
                "createdAt": Timestamp(date: now)
            ]
            let memberPayload: [String: Any] = [
                "userID": ownerID,
                "role": "owner",
                "joinedAt": Timestamp(date: now)
            ]
            let invitePayload: [String: Any] = [
                "workspaceID": workspaceID.uuidString,
                "createdBy": ownerID,
                "createdAt": Timestamp(date: now)
            ]

            try await firestore.collection("workspaces").document(workspaceID.uuidString).setData(workspacePayload)
            try await firestore.collection("workspaces").document(workspaceID.uuidString).collection("members").document(ownerID).setData(memberPayload)
            try await firestore.collection("invites").document(inviteToken).setData(invitePayload)

            try await loadWorkspaces(for: ownerUserID)

            let summary = WorkspaceSummary(
                id: workspaceID,
                name: trimmedName,
                ownerUserID: ownerID,
                inviteToken: inviteToken
            )
            persistCurrentWorkspace(summary)
        } catch {
            throw mapFirestoreError(error)
        }
    }

    func inviteLink() async throws -> String {
        guard var currentWorkspace else {
            throw WorkspaceError.workspaceNotFound
        }

        let workspaceDocument = firestore.collection("workspaces").document(currentWorkspace.id.uuidString)

        if currentWorkspace.inviteToken == nil {
            let token = UUID().uuidString.replacingOccurrences(of: "-", with: "")
            try await workspaceDocument.updateData(["inviteToken": token])
            try await firestore.collection("invites").document(token).setData([
                "workspaceID": currentWorkspace.id.uuidString,
                "createdBy": currentWorkspace.ownerUserID,
                "createdAt": Timestamp(date: .now)
            ])

            currentWorkspace = WorkspaceSummary(
                id: currentWorkspace.id,
                name: currentWorkspace.name,
                ownerUserID: currentWorkspace.ownerUserID,
                inviteToken: token
            )
            updateWorkspace(currentWorkspace)
        }

        guard let inviteToken = currentWorkspace.inviteToken else {
            throw WorkspaceError.invalidInvite
        }

        return "\(inviteScheme)://invite?token=\(inviteToken)"
    }

    func joinWorkspace(withInput input: String, userID: UUID) async throws {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else {
            throw WorkspaceError.invalidInvite
        }

        if let url = URL(string: trimmedInput), trimmedInput.contains("://") {
            try await handleIncomingURL(url, userID: userID)
            return
        }

        try await joinWorkspace(withInviteToken: trimmedInput, userID: userID)
    }

    func handleIncomingURL(_ url: URL, userID: UUID) async throws {
        guard url.scheme == inviteScheme,
              url.host == "invite",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let token = components.queryItems?.first(where: { $0.name == "token" })?.value,
              !token.isEmpty else {
            throw WorkspaceError.invalidInvite
        }

        try await joinWorkspace(withInviteToken: token, userID: userID)
    }

    func selectWorkspace(_ workspace: WorkspaceSummary) {
        persistCurrentWorkspace(workspace)
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

    private func joinWorkspace(withInviteToken token: String, userID: UUID) async throws {
        do {
            let inviteDocument = try await firestore.collection("invites").document(token).getDocument()

            guard let inviteData = inviteDocument.data(),
                  let workspaceIDRaw = inviteData["workspaceID"] as? String,
                  let workspaceID = UUID(uuidString: workspaceIDRaw) else {
                throw WorkspaceError.invalidInvite
            }

            let userIDRaw = try requireFirebaseUserID()
            let memberPayload: [String: Any] = [
                "userID": userIDRaw,
                "role": "member",
                "joinedAt": Timestamp(date: .now)
            ]

            try await firestore.collection("workspaces").document(workspaceIDRaw).collection("members").document(userIDRaw).setData(memberPayload, merge: true)

            try await loadWorkspaces(for: userID)

            if let joinedWorkspace = workspaces.first(where: { $0.id == workspaceID }) {
                persistCurrentWorkspace(joinedWorkspace)
            }
        } catch {
            throw mapFirestoreError(error)
        }
    }

    private func loadWorkspaces(for userID: UUID) async throws {
        let userIDRaw = try requireFirebaseUserID()
        let membershipSnapshot = try await firestore
            .collectionGroup("members")
            .whereField("userID", isEqualTo: userIDRaw)
            .getDocuments()

        let workspaceIDs: [String] = membershipSnapshot.documents.compactMap { document in
            let path = document.reference.path
            guard path.hasPrefix("workspaces/") else { return nil }
            let components = path.split(separator: "/")
            guard components.count >= 2 else { return nil }
            return String(components[1])
        }

        var resolved: [WorkspaceSummary] = []
        for workspaceID in Set(workspaceIDs) {
            let workspaceDoc = try await firestore.collection("workspaces").document(workspaceID).getDocument()
            guard let data = workspaceDoc.data(),
                  let name = data["name"] as? String,
                  let ownerRaw = data["ownerUserID"] as? String,
                  let workspaceUUID = UUID(uuidString: workspaceID) else {
                continue
            }

            resolved.append(
                WorkspaceSummary(
                    id: workspaceUUID,
                    name: name,
                    ownerUserID: ownerRaw,
                    inviteToken: data["inviteToken"] as? String
                )
            )
        }

        workspaces = resolved.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }

        guard !workspaces.isEmpty else {
            currentWorkspace = nil
            UserDefaults.standard.removeObject(forKey: currentWorkspaceDefaultsKey)
            return
        }

        if let storedID = storedWorkspaceID(),
           let storedWorkspace = workspaces.first(where: { $0.id == storedID }) {
            currentWorkspace = storedWorkspace
        } else {
            currentWorkspace = workspaces.first
            UserDefaults.standard.set(currentWorkspace?.id.uuidString, forKey: currentWorkspaceDefaultsKey)
        }
    }

    private func storedWorkspaceID() -> UUID? {
        guard let rawValue = UserDefaults.standard.string(forKey: currentWorkspaceDefaultsKey) else {
            return nil
        }
        return UUID(uuidString: rawValue)
    }

    private func persistCurrentWorkspace(_ workspace: WorkspaceSummary) {
        currentWorkspace = workspace
        UserDefaults.standard.set(workspace.id.uuidString, forKey: currentWorkspaceDefaultsKey)
        updateWorkspace(workspace)
    }

    private func updateWorkspace(_ workspace: WorkspaceSummary) {
        if let index = workspaces.firstIndex(where: { $0.id == workspace.id }) {
            workspaces[index] = workspace
        } else {
            workspaces.append(workspace)
            workspaces.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }
    }

    private func requireFirebaseUserID() throws -> String {
        guard let uid = Auth.auth().currentUser?.uid, !uid.isEmpty else {
            throw WorkspaceError.authenticationRequired
        }
        return uid
    }

    private func mapFirestoreError(_ error: Error) -> WorkspaceError {
        if let workspaceError = error as? WorkspaceError {
            return workspaceError
        }

        let nsError = error as NSError
        if nsError.domain == FirestoreErrorDomain,
           let code = FirestoreErrorCode.Code(rawValue: nsError.code) {
            switch code {
            case .permissionDenied:
                return .permissionDenied
            default:
                break
            }
        }

        return .unknown
    }
}

enum WorkspaceError: LocalizedError {
    case invalidName
    case invalidInvite
    case workspaceLimitReached
    case workspaceNotFound
    case authenticationRequired
    case permissionDenied
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
        case .authenticationRequired:
            return "로그인이 필요합니다. 다시 로그인해주세요."
        case .permissionDenied:
            return "권한이 없어 워크스페이스를 처리할 수 없습니다. 로그인 상태 또는 Firestore 규칙을 확인해주세요."
        case .unknown:
            return "워크스페이스를 처리하지 못했습니다."
        }
    }
}
