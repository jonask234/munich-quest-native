import Foundation

struct UserProgress: Codable {
    var userId: String
    var username: String
    var email: String
    var totalXP: Int = 0
    var totalPoints: Int = 0  // For leaderboard comparison
    var level: Int = 1
    var locationsVisited: Set<String> = []
    var quizzesCompleted: Set<String> = []
    var achievements: Set<String> = []
    var createdAt: Date = Date()
    var lastActive: Date = Date()

    // Streak and accuracy tracking
    var currentStreak: Int = 0
    var lastPlayedDate: Date? = nil
    var totalQuestionsAnswered: Int = 0
    var totalCorrectAnswers: Int = 0

    // Daily challenge tracking
    var dailyChallengeProgress: [String: Int] = [:]  // challengeId: progress
    var lastDailyChallengeDate: Date? = nil

    // Computed properties
    var xpForNextLevel: Int {
        level * 100
    }

    var currentLevelProgress: Double {
        let xpForCurrentLevel = (level - 1) * 100
        let xpInCurrentLevel = totalXP - xpForCurrentLevel
        return Double(xpInCurrentLevel) / Double(xpForNextLevel) * 100
    }

    var locationsVisitedCount: Int {
        locationsVisited.count
    }

    var quizzesCompletedCount: Int {
        quizzesCompleted.count
    }

    var accuracyPercentage: Double {
        guard totalQuestionsAnswered > 0 else { return 0 }
        return (Double(totalCorrectAnswers) / Double(totalQuestionsAnswered)) * 100
    }

    var xpProgress: Double {
        let xpForCurrentLevel = (level - 1) * 100
        let xpInCurrentLevel = totalXP - xpForCurrentLevel
        return Double(xpInCurrentLevel) / Double(xpForNextLevel)
    }

    // Level up logic
    mutating func addXP(_ xp: Int) {
        totalXP += xp
        checkLevelUp()
    }

    private mutating func checkLevelUp() {
        while totalXP >= xpForNextLevel {
            level += 1
        }
    }

    mutating func visitLocation(_ locationId: String) {
        locationsVisited.insert(locationId)
        lastActive = Date()
    }

    mutating func completeQuiz(_ quizId: String, xp: Int, points: Int = 0, isCorrect: Bool = true) {
        // Always track accuracy for all attempts
        totalQuestionsAnswered += 1
        if isCorrect {
            totalCorrectAnswers += 1
            // Add to completed set (Set will handle duplicates automatically)
            quizzesCompleted.insert(quizId)
        }

        // Add XP and points (caller determines if they should be awarded)
        if xp > 0 {
            addXP(xp)
        }
        if points > 0 {
            totalPoints += points
        }

        // Update streak
        updateStreak()
        lastActive = Date()
    }

    private mutating func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastPlayed = lastPlayedDate {
            let lastPlayedDay = calendar.startOfDay(for: lastPlayed)
            let daysDifference = calendar.dateComponents([.day], from: lastPlayedDay, to: today).day ?? 0

            if daysDifference == 0 {
                // Same day, streak continues
                return
            } else if daysDifference == 1 {
                // Consecutive day, increment streak
                currentStreak += 1
            } else {
                // Streak broken
                currentStreak = 1
            }
        } else {
            // First time playing
            currentStreak = 1
        }

        lastPlayedDate = today
    }

    mutating func unlockAchievement(_ achievementId: String) {
        achievements.insert(achievementId)
    }

    // Daily challenge methods
    mutating func updateDailyChallengeProgress(challengeId: String, progress: Int) {
        checkAndResetDailyChallenges()
        dailyChallengeProgress[challengeId] = progress
    }

    func getDailyChallengeProgress(challengeId: String) -> Int {
        // Non-mutating version - just read the current progress
        // Reset is handled by updateDailyChallengeProgress
        return dailyChallengeProgress[challengeId] ?? 0
    }

    private mutating func checkAndResetDailyChallenges() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastDate = lastDailyChallengeDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            if lastDay < today {
                // New day, reset daily challenge progress
                dailyChallengeProgress.removeAll()
                lastDailyChallengeDate = today
            }
        } else {
            lastDailyChallengeDate = today
        }
    }
}

// MARK: - Location Visit Record
struct LocationVisit: Codable, Identifiable {
    let id: String
    let userId: String
    let locationId: String
    let visitedAt: Date
    let coordinates: Coordinates
}

// MARK: - Quiz Result
struct QuizResult: Codable, Identifiable {
    let id: String
    let userId: String
    let quizId: String
    let locationId: String
    let isCorrect: Bool
    let selectedAnswer: Int
    let xpEarned: Int
    let completedAt: Date
}

// MARK: - Achievement
struct Achievement: Identifiable {
    enum Rarity {
        case common, uncommon, rare, epic, legendary
    }

    let id: String
    let title: String
    let description: String
    let icon: String
    let xpReward: Int
    let rarity: Rarity
    let condition: AchievementCondition
}

enum AchievementCondition {
    case visitLocations(count: Int)
    case completeQuizzes(count: Int)
    case reachLevel(level: Int)
    case visitCategory(category: String, count: Int)
    case perfectQuizStreak(count: Int)
}
