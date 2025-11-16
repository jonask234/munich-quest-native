import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

class AuthManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        authStateHandle = auth.addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            self?.isAuthenticated = user != nil
        }
    }

    deinit {
        if let handle = authStateHandle {
            auth.removeStateDidChangeListener(handle)
        }
    }

    func signUp(username: String, email: String, password: String) async -> Result<User, Error> {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            let user = result.user

            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = username
            try await changeRequest.commitChanges()

            let userProfile: [String: Any] = [
                "username": username,
                "email": email,
                "avatar": "🎯",
                "level": 1,
                "totalScore": 0,
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ]

            try await db.collection("users").document(user.uid).setData(userProfile)

            isLoading = false
            return .success(user)
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            return .failure(error)
        }
    }

    func login(email: String, password: String) async -> Result<User, Error> {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            isLoading = false
            return .success(result.user)
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            return .failure(error)
        }
    }

    func logout() {
        try? auth.signOut()
        currentUser = nil
        isAuthenticated = false
    }

    func getAllUsers() async -> [UserProgress] {
        do {
            let snapshot = try await db.collection("users").getDocuments()
            let users = snapshot.documents.compactMap { doc -> UserProgress? in
                try? doc.data(as: UserProgress.self)
            }
            return users
        } catch {
            print("Error fetching users: \(error)")
            return []
        }
    }
}
