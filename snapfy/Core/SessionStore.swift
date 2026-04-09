import Combine
import FirebaseAuth
import Foundation
import SwiftData

protocol AuthManaging {
    @MainActor var currentUser: AuthenticatedUser? { get }
    @MainActor func restoreSession() async
    @MainActor func signIn(email: String, password: String) async throws
    @MainActor func signUp(email: String, password: String, displayName: String) async throws
    @MainActor func updateProfile(displayName: String, profileImageData: Data?) throws
    @MainActor func signOut()
}

@MainActor
final class SessionStore: ObservableObject, AuthManaging {
    @Published private(set) var currentUser: AuthenticatedUser?

    private let container: ModelContainer
    private let currentUserDefaultsKey = "auth.currentUserID"

    init(container: ModelContainer? = nil) {
        self.container = container ?? PersistenceController.shared

        Task { @MainActor in
            await restoreSession()
        }
    }

    func restoreSession() async {
        guard let firebaseUser = Auth.auth().currentUser,
              let email = firebaseUser.email else {
            currentUser = nil
            return
        }

        do {
            let user = try upsertLocalUser(
                email: email,
                displayName: firebaseUser.displayName,
                externalAuthID: firebaseUser.uid
            )
            UserDefaults.standard.set(user.id.uuidString, forKey: currentUserDefaultsKey)
            currentUser = authenticatedUser(from: user)
            return
        } catch {
            currentUser = nil
        }
    }

    func signIn(email: String, password: String) async throws {
        let normalizedEmail = try normalizedEmail(from: email)
        let normalizedPassword = try normalizedPassword(from: password)

        do {
            let result = try await firebaseSignIn(
                email: normalizedEmail,
                password: normalizedPassword
            )
            let firebaseUser = result.user
            let user = try upsertLocalUser(
                email: normalizedEmail,
                displayName: firebaseUser.displayName,
                externalAuthID: firebaseUser.uid
            )
            UserDefaults.standard.set(user.id.uuidString, forKey: currentUserDefaultsKey)
            currentUser = authenticatedUser(from: user)
        } catch {
            throw mapFirebaseError(error)
        }
    }

    func signUp(email: String, password: String, displayName: String) async throws {
        let normalizedEmail = try normalizedEmail(from: email)
        let normalizedPassword = try normalizedPassword(from: password)
        let normalizedDisplayName = try normalizedDisplayName(from: displayName)

        do {
            let result = try await firebaseSignUp(
                email: normalizedEmail,
                password: normalizedPassword
            )

            if let normalizedDisplayName {
                try await updateFirebaseDisplayName(
                    user: result.user,
                    displayName: normalizedDisplayName
                )
            }

            let refreshedDisplayName = normalizedDisplayName ?? result.user.displayName
            let user = try upsertLocalUser(
                email: normalizedEmail,
                displayName: refreshedDisplayName,
                externalAuthID: result.user.uid
            )

            UserDefaults.standard.set(user.id.uuidString, forKey: currentUserDefaultsKey)
            currentUser = authenticatedUser(from: user)
        } catch {
            throw mapFirebaseError(error)
        }
    }

    func updateProfile(displayName: String, profileImageData: Data?) throws {
        guard let currentUser else {
            throw AuthError.userNotFound
        }
        let currentUserID = currentUser.id

        let normalizedDisplayName = try normalizedDisplayName(from: displayName)

        guard let user = try fetchUser(id: currentUserID) else {
            throw AuthError.userNotFound
        }

        user.displayName = normalizedDisplayName
        user.profileImageData = profileImageData

        guard let modelContext = user.modelContext else {
            throw AuthError.unknown
        }

        do {
            try modelContext.save()
        } catch {
            throw AuthError.unknown
        }

        self.currentUser = authenticatedUser(from: user)
    }

    func signOut() {
        try? Auth.auth().signOut()
        UserDefaults.standard.removeObject(forKey: currentUserDefaultsKey)
        currentUser = nil
    }

    private func authenticatedUser(from user: UserAccount) -> AuthenticatedUser {
        AuthenticatedUser(
            id: user.id,
            email: user.email,
            displayName: user.displayName,
            profileImageData: user.profileImageData
        )
    }

    private func fetchUser(id: UUID) throws -> UserAccount? {
        let context = ModelContext(container)
        var descriptor = FetchDescriptor<UserAccount>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func fetchUser(email: String) throws -> UserAccount? {
        let context = ModelContext(container)
        var descriptor = FetchDescriptor<UserAccount>(
            predicate: #Predicate { $0.email == email }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func upsertLocalUser(
        email: String,
        displayName: String?,
        externalAuthID: String
    ) throws -> UserAccount {
        if let existing = try fetchUser(email: email) {
            existing.externalAuthID = externalAuthID
            existing.authProvider = "firebase_email_password"
            if let displayName, !displayName.isEmpty {
                existing.displayName = displayName
            }

            guard let modelContext = existing.modelContext else {
                throw AuthError.unknown
            }
            try modelContext.save()
            return existing
        }

        let context = ModelContext(container)
        let user = UserAccount(
            email: email,
            displayName: displayName,
            authProvider: "firebase_email_password",
            externalAuthID: externalAuthID
        )
        context.insert(user)
        try context.save()
        return user
    }

    private func normalizedEmail(from rawValue: String) throws -> String {
        let trimmed = rawValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard let atIndex = trimmed.firstIndex(of: "@") else {
            throw AuthError.invalidEmail
        }

        let localPart = trimmed[..<atIndex]
        let domainPart = trimmed[trimmed.index(after: atIndex)...]

        guard !localPart.isEmpty,
              !domainPart.isEmpty,
              domainPart.contains(".") else {
            throw AuthError.invalidEmail
        }

        return trimmed
    }

    private func normalizedPassword(from rawValue: String) throws -> String {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 6 else {
            throw AuthError.invalidPassword
        }
        return trimmed
    }

    private func normalizedDisplayName(from rawValue: String) throws -> String? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return nil
        }

        guard trimmed.count >= 2 else {
            throw AuthError.invalidDisplayName
        }

        return trimmed
    }

    private func firebaseSignIn(email: String, password: String) async throws -> AuthDataResult {
        try await withCheckedThrowingContinuation { continuation in
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let result {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(throwing: AuthError.unknown)
                }
            }
        }
    }

    private func firebaseSignUp(email: String, password: String) async throws -> AuthDataResult {
        try await withCheckedThrowingContinuation { continuation in
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let result {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(throwing: AuthError.unknown)
                }
            }
        }
    }

    private func updateFirebaseDisplayName(user: User, displayName: String) async throws {
        let request = user.createProfileChangeRequest()
        request.displayName = displayName

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            request.commitChanges { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private func mapFirebaseError(_ error: Error) -> AuthError {
        let nsError = error as NSError
        let code = AuthErrorCode(rawValue: nsError.code)
        print("FirebaseAuth error:", nsError.domain, nsError.code, nsError.localizedDescription)
        print("FirebaseAuth userInfo:", nsError.userInfo)

        switch code {
        case .some(.invalidEmail):
            return .invalidEmail
        case .some(.emailAlreadyInUse):
            return .emailAlreadyInUse
        case .some(.weakPassword):
            return .invalidPassword
        case .some(.operationNotAllowed):
            return .emailPasswordAuthDisabled
        case .some(.tooManyRequests):
            return .tooManyRequests
        case .some(.networkError):
            return .networkError
        case .some(.appNotAuthorized), .some(.invalidAPIKey), .some(.internalError):
            return .appConfigurationError
        case .some(.wrongPassword), .some(.invalidCredential), .some(.userNotFound):
            return .invalidCredentials
        default:
            return .unknown
        }
    }
}
