import Combine
import Foundation
import SwiftData

protocol AuthManaging {
    @MainActor var currentUser: AuthenticatedUser? { get }
    @MainActor func restoreSession() throws
    @MainActor func lookupUser(email: String) throws -> AuthLookupResult
    @MainActor func signInOrCreate(_ payload: SignUpPayload) throws
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

        do {
            try restoreSession()
        } catch {
            currentUser = nil
        }
    }

    func restoreSession() throws {
        guard let storedID = UserDefaults.standard.string(forKey: currentUserDefaultsKey),
              let userID = UUID(uuidString: storedID) else {
            currentUser = nil
            return
        }

        guard let user = try fetchUser(id: userID) else {
            UserDefaults.standard.removeObject(forKey: currentUserDefaultsKey)
            currentUser = nil
            throw AuthError.userNotFound
        }

        currentUser = authenticatedUser(from: user)
    }

    func lookupUser(email: String) throws -> AuthLookupResult {
        let normalizedEmail = try normalizedEmail(from: email)
        let existingUser = try fetchUser(email: normalizedEmail)
        return existingUser == nil ? .newUser : .existingUser
    }

    func signInOrCreate(_ payload: SignUpPayload) throws {
        let normalizedEmail = try normalizedEmail(from: payload.email)

        if let user = try fetchUser(email: normalizedEmail) {
            UserDefaults.standard.set(user.id.uuidString, forKey: currentUserDefaultsKey)
            currentUser = authenticatedUser(from: user)
            return
        }

        let normalizedDisplayName = try normalizedDisplayName(from: payload.displayName)

        let context = ModelContext(container)
        let user = UserAccount(
            email: normalizedEmail,
            displayName: normalizedDisplayName
        )

        context.insert(user)

        do {
            try context.save()
        } catch {
            throw AuthError.unknown
        }

        UserDefaults.standard.set(user.id.uuidString, forKey: currentUserDefaultsKey)
        currentUser = authenticatedUser(from: user)
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
}
