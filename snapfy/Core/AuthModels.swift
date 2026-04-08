import Foundation
import SwiftData

@Model
final class UserAccount {
    @Attribute(.unique) var id: UUID
    var displayName: String
    var authProvider: String
    var externalAuthID: String?
    var profileImageData: Data?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        displayName: String,
        authProvider: String = "local_device",
        externalAuthID: String? = nil,
        profileImageData: Data? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.displayName = displayName
        self.authProvider = authProvider
        self.externalAuthID = externalAuthID
        self.profileImageData = profileImageData
        self.createdAt = createdAt
    }
}

struct AuthenticatedUser: Equatable {
    let id: UUID
    let displayName: String
}

struct SignUpPayload {
    let displayName: String
}

enum AuthError: LocalizedError {
    case invalidDisplayName
    case userNotFound
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidDisplayName:
            return "닉네임은 2자 이상 입력해주세요."
        case .userNotFound:
            return "사용자 정보를 찾을 수 없습니다."
        case .unknown:
            return "처리 중 오류가 발생했습니다."
        }
    }
}
