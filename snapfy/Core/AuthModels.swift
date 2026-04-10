import Foundation
import SwiftData

@Model
final class UserAccount {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var email: String
    var displayName: String?
    var authProvider: String
    var externalAuthID: String?
    var profileImageData: Data?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        email: String,
        displayName: String? = nil,
        authProvider: String = "local_email",
        externalAuthID: String? = nil,
        profileImageData: Data? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.authProvider = authProvider
        self.externalAuthID = externalAuthID
        self.profileImageData = profileImageData
        self.createdAt = createdAt
    }
}

struct AuthenticatedUser: Equatable {
    let id: UUID
    let email: String
    let displayName: String?
    let profileImageData: Data?

    var resolvedDisplayName: String {
        let trimmedDisplayName = displayName?.trimmingCharacters(in: .whitespacesAndNewlines)

        if let trimmedDisplayName, !trimmedDisplayName.isEmpty {
            return trimmedDisplayName
        }

        let emailPrefix = email.split(separator: "@").first.map(String.init)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let emailPrefix, !emailPrefix.isEmpty {
            return emailPrefix
        }

        return email
    }
}

enum AuthError: LocalizedError {
    case invalidEmail
    case invalidPassword
    case invalidDisplayName
    case emailAlreadyInUse
    case invalidCredentials
    case emailPasswordAuthDisabled
    case tooManyRequests
    case networkError
    case appConfigurationError
    case userNotFound
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "올바른 이메일을 입력해주세요."
        case .invalidPassword:
            return "비밀번호는 6자 이상 입력해주세요."
        case .invalidDisplayName:
            return "표시 이름은 2자 이상 입력하거나 비워둘 수 있습니다."
        case .emailAlreadyInUse:
            return "이미 가입된 이메일입니다."
        case .invalidCredentials:
            return "이메일 또는 비밀번호가 올바르지 않습니다."
        case .emailPasswordAuthDisabled:
            return "Firebase 콘솔에서 이메일/비밀번호 로그인을 활성화해주세요."
        case .tooManyRequests:
            return "요청이 너무 많습니다. 잠시 후 다시 시도해주세요."
        case .networkError:
            return "네트워크 연결을 확인해주세요."
        case .appConfigurationError:
            return "앱 Firebase 설정이 올바르지 않습니다. 번들 ID와 GoogleService-Info.plist를 확인해주세요."
        case .userNotFound:
            return "사용자 정보를 찾을 수 없습니다."
        case .unknown:
            return "처리 중 오류가 발생했습니다."
        }
    }
}
