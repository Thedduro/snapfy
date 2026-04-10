import Foundation

struct RemoteUserProfile: Equatable, Codable {
    let id: String
    let email: String
    let displayName: String?
    let profileImageURL: String?
    let createdAt: Date
}

struct RemoteWorkspaceRecord: Equatable, Codable {
    let id: String
    let name: String
    let ownerUserID: String
    let inviteToken: String?
    let createdAt: Date
}

struct RemoteMediaMetadata: Equatable, Codable {
    let id: String
    let workspaceID: String
    let ownerUserID: String
    let date: Date
    let mediaType: String
    let originalURL: String
    let thumbnailURL: String
    let createdAt: Date
}
