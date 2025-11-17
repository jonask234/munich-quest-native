import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

class AuthManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var auth: Auth?
    private var db: Firestore?
    private var cancellables = Set<AnyCancellable>()
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        // Only initialize Firebase services if Firebase is configured
        if FirebaseApp.app() != nil {
            auth = Auth.auth()
            db = Firestore.firestore()

            authStateHandle = auth?.addStateDidChangeListener { [weak self] _, user in
                self?.currentUser = user
                self?.isAuthenticated = user != nil
            }
        } else {
            print("⚠️ AuthManager: Firebase not configured, running in offline mode")
        }
    }

    deinit {
        if let handle = authStateHandle, let auth = auth {
            auth.removeStateDidChangeListener(handle)
        }
    }

    func signUp(username: String, email: String, password: String) async -> Result<User, Error> {
        guard let auth = auth, let db = db else {
            errorMessage = "Firebase not configured"
            return .failure(NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Firebase not configured"]))
        }

        isLoading = true
        errorMessage = nil

        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            let user = result.user

            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = username
            try await changeRequest.commitChanges()

            // Send email verification
            try await user.sendEmailVerification()

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
        } catch let error as NSError {
            isLoading = false
            errorMessage = getAuthErrorMessage(error)
            return .failure(error)
        }
    }

    func resendVerificationEmail() async -> Bool {
        guard let user = currentUser else { return false }

        do {
            try await user.sendEmailVerification()
            return true
        } catch {
            errorMessage = "Failed to send verification email. Please try again."
            return false
        }
    }

    func checkEmailVerified() async {
        guard let user = currentUser, let auth = auth else { return }
        try? await user.reload()
        // Update the current user to refresh verification status
        currentUser = auth.currentUser
    }

    func login(email: String, password: String) async -> Result<User, Error> {
        guard let auth = auth else {
            errorMessage = "Firebase not configured"
            return .failure(NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Firebase not configured"]))
        }

        isLoading = true
        errorMessage = nil

        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            isLoading = false
            return .success(result.user)
        } catch let error as NSError {
            isLoading = false
            errorMessage = getAuthErrorMessage(error)
            return .failure(error)
        }
    }

    private func getAuthErrorMessage(_ error: NSError) -> String {
        guard let errorCode = AuthErrorCode(rawValue: error.code) else {
            return "An error occurred. Please try again."
        }

        switch errorCode {
        case .wrongPassword:
            return "Incorrect password. Please try again."
        case .userNotFound:
            return "No account found with this email address."
        case .invalidEmail:
            return "Invalid email address format."
        case .networkError:
            return "Network error. Please check your connection."
        case .userDisabled:
            return "This account has been disabled."
        case .tooManyRequests:
            return "Too many failed attempts. Please try again later."
        case .emailAlreadyInUse:
            return "An account with this email already exists."
        case .weakPassword:
            return "Password is too weak. Please use a stronger password."
        default:
            return "Authentication failed. Please try again."
        }
    }

    func logout() {
        try? auth?.signOut()
        currentUser = nil
        isAuthenticated = false
    }

    func getAllUsers() async -> [UserProgress] {
        guard let db = db else {
            print("⚠️ Firebase not configured, cannot fetch users")
            return []
        }

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
