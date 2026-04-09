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

struct WorkspaceSummary: Equatable {
    let id: UUID
    let name: String
    let ownerUserID: UUID
    let inviteToken: String?
}
