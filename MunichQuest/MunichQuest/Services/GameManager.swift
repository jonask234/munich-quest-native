import Foundation
import FirebaseFirestore
import CoreLocation
import Combine

class GameManager: ObservableObject {
    @Published var locations: [LocationData] = []
    @Published var quizzes: [String: Quiz] = [:]
    @Published var userProgress: UserProgress?
    @Published var leaderboard: [LeaderboardEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedLocation: LocationData?
    @Published var currentQuiz: Quiz?
    @Published var quizResults: [String: Bool] = [:] // quizId -> isCorrect

    private let db = Firestore.firestore()
    private var locationListener: ListenerRegistration?
    private var progressListener: ListenerRegistration?
    weak var authManager: AuthManager?

    init() {
        loadLocalProgress()
        Task {
            await loadGameData()
        }
    }

    // MARK: - Local Storage
    private func loadLocalProgress() {
        if let data = UserDefaults.standard.data(forKey: "userProgress"),
           let progress = try? JSONDecoder().decode(UserProgress.self, from: data) {
            userProgress = progress
        }
    }

    func initializeLocalProgress() {
        let progress = UserProgress(
            userId: UUID().uuidString,
            username: "Local Player",
            email: ""
        )
        userProgress = progress
        saveLocalProgress()
    }

    private func saveLocalProgress() {
        guard let progress = userProgress else { return }
        if let data = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(data, forKey: "userProgress")
        }
    }

    // MARK: - Load Game Data
    @MainActor
    func loadGameData() async {
        isLoading = true

        guard let url = Bundle.main.url(forResource: "locations", withExtension: "json") else {
            errorMessage = "Failed to find locations.json"
            isLoading = false
            print("❌ ERROR: locations.json not found in bundle")
            return
        }

        print("✅ Found locations.json at: \(url.path)")

        // Load and decode data off the main actor
        let result = await Task.detached(priority: .userInitiated) {
            do {
                guard let data = try? Data(contentsOf: url) else {
                    print("❌ ERROR: Failed to load data from locations.json")
                    return Result<(locations: [LocationData], quizzes: [String: Quiz]), Error>.failure(
                        NSError(domain: "GameManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to load game data"])
                    )
                }

                print("✅ Loaded \(data.count) bytes from locations.json")

                let gameData = try self.decodeGameData(from: data)
                let sortedLocations = Array(gameData.locations.values).sorted { $0.name < $1.name }

                return Result.success((locations: sortedLocations, quizzes: gameData.quizzes))
            } catch {
                print("❌ ERROR: Failed to decode game data: \(error)")
                return Result.failure(error)
            }
        }.value

        // Update UI on main actor
        switch result {
        case .success(let data):
            locations = data.locations
            quizzes = data.quizzes
            isLoading = false
            print("✅ Successfully loaded \(data.locations.count) locations and \(data.quizzes.count) quizzes")
        case .failure(let error):
            errorMessage = "Failed to decode game data: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - User Progress Management
    func loadUserProgress(userId: String) {
        isLoading = true
        progressListener = db.collection("users").document(userId).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            self.isLoading = false

            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }

            guard let data = snapshot?.data() else {
                // Create new user progress
                self.createUserProgress(userId: userId)
                return
            }

            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                self.userProgress = try JSONDecoder().decode(UserProgress.self, from: jsonData)
            } catch {
                self.errorMessage = "Failed to decode user progress: \(error.localizedDescription)"
            }
        }
    }

    private func createUserProgress(userId: String) {
        // User progress is created by AuthManager during signup
        // Just initialize with default values if not found
        let progress = UserProgress(
            userId: userId,
            username: "Player",
            email: ""
        )
        userProgress = progress
        saveUserProgress()
    }

    func saveUserProgress() {
        guard let progress = userProgress else { return }

        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(progress)
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

            db.collection("users").document(progress.userId).setData(dict) { [weak self] error in
                if let error = error {
                    self?.errorMessage = "Failed to save progress: \(error.localizedDescription)"
                }
            }
        } catch {
            errorMessage = "Failed to encode progress: \(error.localizedDescription)"
        }
    }

    // MARK: - Location Checking
    func checkLocationProximity(userLocation: CLLocation) -> LocationData? {
        for location in locations {
            let locationCoord = CLLocation(
                latitude: location.coordinates.lat,
                longitude: location.coordinates.lng
            )
            let distance = userLocation.distance(from: locationCoord)

            if distance <= location.radius {
                return location
            }
        }
        return nil
    }

    func visitLocation(_ location: LocationData, at userLocation: CLLocation) {
        guard var progress = userProgress else { return }

        // Check if already visited
        let alreadyVisited = progress.locationsVisited.contains(location.id)

        // Record visit
        progress.visitLocation(location.id)
        progress.addXP(50) // XP for visiting a new location

        // Update daily challenge progress if this is a new visit today
        if !alreadyVisited {
            let currentVisits = progress.getDailyChallengeProgress(challengeId: "daily_visit_3")
            progress.updateDailyChallengeProgress(challengeId: "daily_visit_3", progress: currentVisits + 1)
        }

        userProgress = progress

        // Save locally
        saveLocalProgress()

        // Save to Firebase only if authenticated
        if authManager?.isAuthenticated == true {
            saveUserProgress()
            if !alreadyVisited {
                saveLocationVisit(location: location, userLocation: userLocation)
            }
        }
    }

    private func saveLocationVisit(location: LocationData, userLocation: CLLocation) {
        guard let userId = userProgress?.userId else { return }

        let visit = LocationVisit(
            id: UUID().uuidString,
            userId: userId,
            locationId: location.id,
            visitedAt: Date(),
            coordinates: Coordinates(lat: userLocation.coordinate.latitude, lng: userLocation.coordinate.longitude)
        )

        do {
            let data = try JSONEncoder().encode(visit)
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            db.collection("visits").document(visit.id).setData(dict)
        } catch {
            errorMessage = "Failed to save visit: \(error.localizedDescription)"
        }
    }

    // MARK: - Quiz Management
    func getQuizzesForLocation(_ locationId: String) -> [Quiz] {
        quizzes.values.filter { $0.locationId == locationId }.sorted { $0.id < $1.id }
    }

    func submitQuizAnswer(quiz: Quiz, selectedAnswer: Int) {
        guard var progress = userProgress else { return }

        let isCorrect = selectedAnswer == quiz.correctAnswer
        let alreadyCompleted = progress.quizzesCompleted.contains(quiz.id)

        // Only award XP/points if correct AND not already completed
        let xpEarned = (isCorrect && !alreadyCompleted) ? quiz.xpReward : 0
        let pointsEarned = (isCorrect && !alreadyCompleted) ? quiz.points : 0

        // Always track accuracy correctly, regardless of completion status
        progress.completeQuiz(quiz.id, xp: xpEarned, points: pointsEarned, isCorrect: isCorrect)

        // Update daily challenge progress
        if isCorrect && !alreadyCompleted {
            // Update "answer 5 correctly" challenge
            let currentCorrect = progress.getDailyChallengeProgress(challengeId: "daily_answer_5")
            progress.updateDailyChallengeProgress(challengeId: "daily_answer_5", progress: currentCorrect + 1)

            // Update "earn 100 XP" challenge
            let currentXP = progress.getDailyChallengeProgress(challengeId: "daily_earn_100xp")
            progress.updateDailyChallengeProgress(challengeId: "daily_earn_100xp", progress: currentXP + xpEarned)
        }

        userProgress = progress

        // Save locally immediately
        saveLocalProgress()

        // Save to Firebase only if authenticated
        if authManager?.isAuthenticated == true {
            saveUserProgress()
        }

        // Save quiz result (track all attempts, not just correct ones)
        quizResults[quiz.id] = isCorrect

        // Save to Firebase only if authenticated
        if authManager?.isAuthenticated == true {
            saveQuizResult(quiz: quiz, selectedAnswer: selectedAnswer, isCorrect: isCorrect, xpEarned: xpEarned)
        }
    }

    private func saveQuizResult(quiz: Quiz, selectedAnswer: Int, isCorrect: Bool, xpEarned: Int) {
        guard let userId = userProgress?.userId else { return }

        let result = QuizResult(
            id: UUID().uuidString,
            userId: userId,
            quizId: quiz.id,
            locationId: quiz.locationId,
            isCorrect: isCorrect,
            selectedAnswer: selectedAnswer,
            xpEarned: xpEarned,
            completedAt: Date()
        )

        do {
            let data = try JSONEncoder().encode(result)
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            db.collection("quizResults").document(result.id).setData(dict)
        } catch {
            errorMessage = "Failed to save quiz result: \(error.localizedDescription)"
        }
    }

    // MARK: - Leaderboard
    func loadLeaderboard() {
        isLoading = true
        db.collection("users")
            .order(by: "totalXP", descending: true)
            .limit(to: 100)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false

                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }

                guard let documents = snapshot?.documents else { return }

                self.leaderboard = documents.enumerated().compactMap { index, doc in
                    let data = doc.data()
                    return LeaderboardEntry(
                        id: doc.documentID,
                        username: data["username"] as? String ?? "Unknown",
                        totalXP: data["totalXP"] as? Int ?? 0,
                        level: data["level"] as? Int ?? 1,
                        locationsVisited: (data["locationsVisited"] as? [String])?.count ?? 0,
                        quizzesPassed: (data["quizzesCompleted"] as? [String])?.count ?? 0,
                        rank: index + 1
                    )
                }
            }
    }

    // MARK: - Filtered Locations
    func getLocationsByCategory(_ category: String) -> [LocationData] {
        locations.filter { $0.category == category }
    }

    func getLocationsByDifficulty(_ difficulty: String) -> [LocationData] {
        locations.filter { $0.difficulty == difficulty }
    }

    func getUnlockedLocations() -> [LocationData] {
        let userLevel = userProgress?.level ?? 1
        return locations.filter { $0.unlockLevel <= userLevel }
    }

    // MARK: - Helper Functions
    nonisolated private func decodeGameData(from data: Data) throws -> GameData {
        return try JSONDecoder().decode(GameData.self, from: data)
    }

    // MARK: - Cleanup
    deinit {
        locationListener?.remove()
        progressListener?.remove()
    }
}
