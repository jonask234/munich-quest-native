import SwiftUI
import FirebaseCore

@main
struct MunichQuestApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var gameManager: GameManager
    @StateObject private var locationManager = LocationManager()

    init() {
        // Configure Firebase only if GoogleService-Info.plist exists
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        } else {
            print("⚠️ GoogleService-Info.plist not found - running without Firebase")
        }

        // Initialize managers
        let auth = AuthManager()
        let game = GameManager()
        game.authManager = auth

        _authManager = StateObject(wrappedValue: auth)
        _gameManager = StateObject(wrappedValue: game)
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(gameManager)
                .environmentObject(authManager)
                .environmentObject(locationManager)
                .onAppear {
                    // Initialize local user progress if needed
                    if gameManager.userProgress == nil {
                        gameManager.initializeLocalProgress()
                    }
                }
        }
    }
}
