import Foundation
import SwiftData

@Model
final class WorkspaceRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var ownerUserID: UUID
    var inviteToken: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        ownerUserID: UUID,
        inviteToken: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.ownerUserID = ownerUserID
        self.inviteToken = inviteToken
        self.createdAt = createdAt
    }
}

struct WorkspaceSummary: Hashable {
    let id: UUID
    let name: String
    let ownerUserID: UUID
    let inviteToken: String?
}

@Model
final class WorkspaceMemberRecord {
    @Attribute(.unique) var id: UUID
    var workspaceID: UUID
    var userID: UUID
    var role: String
    var joinedAt: Date

    init(
        id: UUID = UUID(),
        workspaceID: UUID,
        userID: UUID,
        role: String,
        joinedAt: Date = .now
    ) {
        self.id = id
        self.workspaceID = workspaceID
        self.userID = userID
        self.role = role
        self.joinedAt = joinedAt
    }
}
