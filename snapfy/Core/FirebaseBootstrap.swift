import FirebaseCore
import FirebaseFirestore

enum FirebaseBootstrap {
    static func configureIfNeeded() {
        guard FirebaseApp.app() == nil else {
            return
        }

        FirebaseApp.configure()

        let firestore = Firestore.firestore()
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        firestore.settings = settings
    }

    static var firestore: Firestore {
        Firestore.firestore()
    }
}
