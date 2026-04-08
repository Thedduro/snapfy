import Combine
import Foundation
import SwiftData

protocol AuthManaging {
    @MainActor var currentUser: AuthenticatedUser? { get }
    @MainActor func restoreSession() throws
    @MainActor func signUp(_ payload: SignUpPayload) throws
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

        let context = ModelContext(container)
        var descriptor = FetchDescriptor<UserAccount>(
            predicate: #Predicate { $0.id == userID }
        )
        descriptor.fetchLimit = 1

        guard let user = try context.fetch(descriptor).first else {
            UserDefaults.standard.removeObject(forKey: currentUserDefaultsKey)
            currentUser = nil
            throw AuthError.userNotFound
        }

        currentUser = AuthenticatedUser(
            id: user.id,
            displayName: user.displayName
        )
    }

    func signUp(_ payload: SignUpPayload) throws {
        let trimmedDisplayName = payload.displayName
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedDisplayName.count >= 2 else {
            throw AuthError.invalidDisplayName
        }

        let context = ModelContext(container)
        let user = UserAccount(displayName: trimmedDisplayName)

        context.insert(user)

        do {
            try context.save()
        } catch {
            throw AuthError.unknown
        }

        UserDefaults.standard.set(user.id.uuidString, forKey: currentUserDefaultsKey)
        currentUser = AuthenticatedUser(
            id: user.id,
            displayName: user.displayName
        )
    }

    func signOut() {
        UserDefaults.standard.removeObject(forKey: currentUserDefaultsKey)
        currentUser = nil
    }
}
