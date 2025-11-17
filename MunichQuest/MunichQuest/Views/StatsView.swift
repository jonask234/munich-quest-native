import SwiftUI
import MapKit

struct StatsView: View {
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var authManager: AuthManager

    @State private var selectedCategories: Set<String> = []
    @State private var showCategoryPicker = false

    var body: some View {
        NavigationView {
            if let progress = gameManager.userProgress {
                ScrollView {
                    VStack(spacing: 25) {
                        // Hero Section - Level & XP Progress
                        VStack(spacing: 15) {
                            Text(progress.username)
                                .font(.title3)
                                .fontWeight(.semibold)

                            // Level Display
                            HStack(spacing: 8) {
                                Text("Level")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Text("\(progress.level)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color(red: 0.4, green: 0.49, blue: 0.92))
                            }

                            // XP Progress Bar
                            VStack(spacing: 8) {
                                ProgressView(value: progress.xpProgress)
                                    .tint(Color(red: 0.4, green: 0.49, blue: 0.92))
                                    .scaleEffect(x: 1, y: 2, anchor: .center)

                                let xpInLevel = progress.totalXP - ((progress.level - 1) * 100)
                                Text("\(xpInLevel) / \(progress.xpForNextLevel) XP")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(15)
                        .padding(.horizontal)

                        // Quick Stats Grid - Only Accuracy and Streak
                        HStack(spacing: 15) {
                            QuickStatCard(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Accuracy",
                                value: String(format: "%.0f%%", progress.accuracyPercentage),
                                color: .green
                            )

                            QuickStatCard(
                                icon: "flame.fill",
                                title: "Streak",
                                value: "\(progress.currentStreak) days",
                                color: .orange
                            )
                        }
                        .padding(.horizontal)

                        // Daily Challenges
                        ChallengesSection(
                            title: "Daily Challenges",
                            challenges: DailyChallenge.dailyChallenges(progress: progress, gameManager: gameManager),
                            timeRemaining: timeUntilDailyReset(),
                            progress: progress
                        )

                        // Weekly Challenges
                        ChallengesSection(
                            title: "Weekly Challenges",
                            challenges: DailyChallenge.weeklyChallenges(progress: progress, gameManager: gameManager),
                            timeRemaining: timeUntilWeeklyReset(),
                            progress: progress
                        )

                        // Locations Discovered
                        LocationsDiscoveredSection(
                            selectedCategories: $selectedCategories,
                            showCategoryPicker: $showCategoryPicker,
                            progress: progress
                        )
                        .environmentObject(gameManager)

                        // Achievements
                        AchievementsSection(progress: progress)
                            .environmentObject(gameManager)
                    }
                    .padding(.vertical)
                    .padding(.bottom, 20)  // Extra bottom padding for tab bar safe area
                }
                .navigationBarHidden(true)
                .safeAreaInset(edge: .top) {
                    Color.clear.frame(height: 0)
                }
            } else {
                ProgressView()
                    .navigationBarHidden(true)
            }
        }
    }

    private func timeUntilDailyReset() -> String {
        let calendar = Calendar.current
        let now = Date()
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) else {
            return "24 hours"
        }
        let components = calendar.dateComponents([.hour], from: now, to: tomorrow)
        let hours = components.hour ?? 0
        return "\(hours) Hours Left"
    }

    private func timeUntilWeeklyReset() -> String {
        let calendar = Calendar.current
        let now = Date()
        guard let nextMonday = calendar.nextDate(after: now, matching: DateComponents(weekday: 2), matchingPolicy: .nextTime) else {
            return "7 days"
        }
        let components = calendar.dateComponents([.day], from: now, to: nextMonday)
        let days = components.day ?? 0
        return "\(days) Days Left"
    }
}

// MARK: - Quick Stat Card
struct QuickStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            VStack(spacing: 4) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
    }
}

// MARK: - Challenges Section
struct ChallengesSection: View {
    let title: String
    let challenges: [DailyChallenge]
    let timeRemaining: String
    let progress: UserProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text("Complete challenges to earn bonus rewards!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Time remaining badge
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.caption2)
                    Text(timeRemaining)
                }
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.orange)
                .cornerRadius(12)
            }
            .padding(.horizontal)

            VStack(spacing: 12) {
                ForEach(challenges) { challenge in
                    ChallengeRow(challenge: challenge, progress: progress)
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(15)
            .padding(.horizontal)
        }
    }
}

struct ChallengeRow: View {
    let challenge: DailyChallenge
    let progress: UserProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Challenge name and progress
            HStack {
                Text(challenge.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text("\(challenge.currentProgress)/\(challenge.target)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.4, green: 0.49, blue: 0.92))
            }

            // Progress bar
            ProgressView(value: Double(challenge.currentProgress), total: Double(challenge.target))
                .tint(challenge.isCompleted ? .green : Color(red: 0.4, green: 0.49, blue: 0.92))
                .scaleEffect(x: 1, y: 1.5, anchor: .center)

            // Reward or completion status
            HStack {
                if challenge.isCompleted {
                    Text("Completed!")
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                } else {
                    Text("+\(challenge.xpReward) XP")
                        .font(.caption)
                        .foregroundColor(Color(red: 0.95, green: 0.75, blue: 0.0))
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Locations Discovered Section
struct LocationsDiscoveredSection: View {
    @EnvironmentObject var gameManager: GameManager
    @Binding var selectedCategories: Set<String>
    @Binding var showCategoryPicker: Bool
    let progress: UserProgress

    private var categories: [String] {
        Array(Set(gameManager.locations.map { $0.category })).sorted()
    }

    private var filteredLocations: [LocationData] {
        // Show ALL locations, not just visited ones
        let locations = gameManager.locations

        if selectedCategories.isEmpty {
            return locations.sorted { $0.name < $1.name }
        }
        return locations.filter { selectedCategories.contains($0.category) }.sorted { $0.name < $1.name }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Locations Discovered")
                        .font(.headline)
                    Text("\(progress.locationsVisited.count)/\(gameManager.locations.count) visited")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Dropdown button
                Button(action: { showCategoryPicker = true }) {
                    HStack(spacing: 6) {
                        Text(selectedCategories.isEmpty ? "All Categories" : "\(selectedCategories.count) selected")
                            .font(.subheadline)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(Color(red: 0.4, green: 0.49, blue: 0.92))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.4, green: 0.49, blue: 0.92).opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)

            VStack(spacing: 12) {
                ForEach(filteredLocations) { location in
                    LocationProgressRow(location: location, progress: progress)
                        .environmentObject(gameManager)
                }
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: $showCategoryPicker) {
            CategoryPickerSheet(categories: categories, selectedCategories: $selectedCategories)
        }
    }
}

struct CategoryPickerSheet: View {
    let categories: [String]
    @Binding var selectedCategories: Set<String>
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(categories, id: \.self) { category in
                    Button(action: {
                        if selectedCategories.contains(category) {
                            selectedCategories.remove(category)
                        } else {
                            selectedCategories.insert(category)
                        }
                    }) {
                        HStack {
                            Text(category.capitalized)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedCategories.contains(category) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color(red: 0.4, green: 0.49, blue: 0.92))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        selectedCategories.removeAll()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct LocationProgressRow: View {
    @EnvironmentObject var gameManager: GameManager
    let location: LocationData
    let progress: UserProgress

    private var isVisited: Bool {
        progress.locationsVisited.contains(location.id)
    }

    private var quizProgress: (completed: Int, total: Int) {
        let quizzes = gameManager.getQuizzesForLocation(location.id)
        let completed = quizzes.filter { progress.quizzesCompleted.contains($0.id) }.count
        return (completed, quizzes.count)
    }

    private var isCompleted: Bool {
        quizProgress.completed == quizProgress.total && quizProgress.total > 0
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Text(location.emoji)
                    .font(.title2)
                    .opacity(isVisited ? 1.0 : 0.4)

                VStack(alignment: .leading, spacing: 4) {
                    Text(location.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isVisited ? .primary : .secondary)

                    if isVisited {
                        Text("\(quizProgress.completed)/\(quizProgress.total) questions answered")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Not yet visited")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if !isVisited {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.gray)
                        .font(.title3)
                } else if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                } else {
                    Image(systemName: "circle.dotted")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
            }

            // Action buttons - available for all locations
            HStack(spacing: 10) {
                Button(action: openDirections) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                            .font(.caption)
                        Text("Directions")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.4, green: 0.49, blue: 0.92))
                    .cornerRadius(8)
                }

                Button(action: jumpToLocation) {
                    HStack(spacing: 6) {
                        Image(systemName: "map.fill")
                            .font(.caption)
                        Text("Jump to Location")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(Color(red: 0.4, green: 0.49, blue: 0.92))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.4, green: 0.49, blue: 0.92).opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func openDirections() {
        let coordinate = CLLocationCoordinate2D(
            latitude: location.coordinates.lat,
            longitude: location.coordinates.lng
        )
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = location.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
        ])
    }

    private func jumpToLocation() {
        // Post notification to switch to map tab and center on location
        NotificationCenter.default.post(
            name: NSNotification.Name("JumpToLocation"),
            object: nil,
            userInfo: ["locationId": location.id]
        )
    }
}

// MARK: - Achievements Section
struct AchievementsSection: View {
    @EnvironmentObject var gameManager: GameManager
    let progress: UserProgress

    private var achievements: [Achievement] {
        Achievement.allAchievements
    }

    private var unlockedCount: Int {
        achievements.filter { isUnlocked($0) }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Achievements")
                    .font(.headline)

                Spacer()

                Text("\(unlockedCount)/\(achievements.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                ForEach(achievements) { achievement in
                    AchievementCard(
                        achievement: achievement,
                        isUnlocked: isUnlocked(achievement),
                        progress: achievementProgress(achievement)
                    )
                }
            }
            .padding(.horizontal)
        }
    }

    private func isUnlocked(_ achievement: Achievement) -> Bool {
        progress.achievements.contains(achievement.id)
    }

    private func achievementProgress(_ achievement: Achievement) -> Double {
        switch achievement.condition {
        case .visitLocations(let count):
            return min(Double(progress.locationsVisited.count) / Double(count), 1.0)
        case .completeQuizzes(let count):
            return min(Double(progress.quizzesCompleted.count) / Double(count), 1.0)
        case .reachLevel(let level):
            return min(Double(progress.level) / Double(level), 1.0)
        case .visitCategory(let category, let count):
            let visited = gameManager.locations.filter {
                $0.category == category && progress.locationsVisited.contains($0.id)
            }.count
            return min(Double(visited) / Double(count), 1.0)
        case .perfectQuizStreak(let count):
            return 0.0 // Would need streak tracking
        }
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    let isUnlocked: Bool
    let progress: Double

    private var rarityColor: Color {
        switch achievement.rarity {
        case .common:
            return .gray
        case .uncommon:
            return .green
        case .rare:
            return .blue
        case .epic:
            return .purple
        case .legendary:
            return Color(red: 0.95, green: 0.75, blue: 0.0)
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            Text(isUnlocked ? achievement.icon : "🔒")
                .font(.system(size: 36))
                .opacity(isUnlocked ? 1.0 : 0.3)

            VStack(spacing: 4) {
                Text(achievement.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .foregroundColor(isUnlocked ? .primary : .secondary)

                Text(achievement.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                if !isUnlocked {
                    VStack(spacing: 4) {
                        ProgressView(value: progress)
                            .tint(Color(red: 0.4, green: 0.49, blue: 0.92))
                            .scaleEffect(x: 1, y: 1.2)

                        Text("\(Int(progress * 100))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                } else {
                    Text("+\(achievement.xpReward) XP")
                        .font(.caption2)
                        .foregroundColor(rarityColor)
                        .fontWeight(.bold)
                        .padding(.top, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 160, maxHeight: 160)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(isUnlocked ?
                    rarityColor.opacity(0.1) :
                    Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(rarityColor, lineWidth: 2.5)
        )
    }
}

// MARK: - Daily Challenge Model
struct DailyChallenge: Identifiable {
    let id: String
    let title: String
    let target: Int
    let currentProgress: Int
    let xpReward: Int

    var isCompleted: Bool {
        currentProgress >= target
    }

    static func dailyChallenges(progress: UserProgress, gameManager: GameManager) -> [DailyChallenge] {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let challengeIndex = dayOfYear % 3

        let allChallenges = [
            ("daily_answer_5", "Answer 5 questions correctly", 5, 50),
            ("daily_visit_3", "Visit 3 different locations", 3, 30),
            ("daily_earn_100xp", "Earn 100 XP today", 100, 100)
        ]

        let selectedIndices = [
            challengeIndex % allChallenges.count,
            (challengeIndex + 1) % allChallenges.count,
            (challengeIndex + 2) % allChallenges.count
        ]

        return selectedIndices.map { index in
            let (id, title, target, xp) = allChallenges[index]
            let currentProgress = calculateDailyProgress(id: id, progress: progress, gameManager: gameManager, target: target)

            return DailyChallenge(
                id: id,
                title: title,
                target: target,
                currentProgress: currentProgress,
                xpReward: xp
            )
        }
    }

    static func weeklyChallenges(progress: UserProgress, gameManager: GameManager) -> [DailyChallenge] {
        return [
            DailyChallenge(
                id: "weekly_complete_location",
                title: "Complete all quizzes at 2 locations",
                target: 2,
                currentProgress: calculateWeeklyProgress(id: "weekly_complete_location", progress: progress, gameManager: gameManager, target: 2),
                xpReward: 200
            ),
            DailyChallenge(
                id: "weekly_maintain_streak",
                title: "Maintain a 7-day streak",
                target: 7,
                currentProgress: min(progress.currentStreak, 7),
                xpReward: 300
            ),
            DailyChallenge(
                id: "weekly_earn_500xp",
                title: "Earn 500 total XP",
                target: 500,
                currentProgress: min(progress.totalXP, 500),
                xpReward: 250
            )
        ]
    }

    private static func calculateDailyProgress(id: String, progress: UserProgress, gameManager: GameManager, target: Int) -> Int {
        switch id {
        case "daily_answer_5":
            return min(progress.totalCorrectAnswers, target)
        case "daily_visit_3":
            return min(progress.locationsVisited.count, target)
        case "daily_earn_100xp":
            return min(progress.totalXP, target)
        default:
            return 0
        }
    }

    private static func calculateWeeklyProgress(id: String, progress: UserProgress, gameManager: GameManager, target: Int) -> Int {
        switch id {
        case "weekly_complete_location":
            let completedLocations = gameManager.locations.filter { location in
                let quizzes = gameManager.getQuizzesForLocation(location.id)
                let completed = quizzes.filter { progress.quizzesCompleted.contains($0.id) }
                return !quizzes.isEmpty && completed.count == quizzes.count
            }
            return min(completedLocations.count, target)
        case "weekly_maintain_streak":
            return min(progress.currentStreak, target)
        case "weekly_earn_500xp":
            return min(progress.totalXP, target)
        default:
            return 0
        }
    }
}

// MARK: - Achievement Extension
extension Achievement {
    static let allAchievements: [Achievement] = [
        Achievement(
            id: "first_steps",
            title: "First Steps",
            description: "Complete your first quiz",
            icon: "🎯",
            xpReward: 50,
            rarity: .common,
            condition: .completeQuizzes(count: 1)
        ),
        Achievement(
            id: "explorer",
            title: "Explorer",
            description: "Visit 5 different locations",
            icon: "🗺️",
            xpReward: 100,
            rarity: .common,
            condition: .visitLocations(count: 5)
        ),
        Achievement(
            id: "munich_expert",
            title: "Munich Expert",
            description: "Visit 10 different locations",
            icon: "🏆",
            xpReward: 200,
            rarity: .rare,
            condition: .visitLocations(count: 10)
        ),
        Achievement(
            id: "completionist",
            title: "Completionist",
            description: "Complete all quizzes at 3 locations",
            icon: "⭐",
            xpReward: 250,
            rarity: .rare,
            condition: .visitLocations(count: 3)
        ),
        Achievement(
            id: "quiz_master",
            title: "Quiz Master",
            description: "Answer 50 questions",
            icon: "🧠",
            xpReward: 150,
            rarity: .uncommon,
            condition: .completeQuizzes(count: 50)
        ),
        Achievement(
            id: "perfectionist",
            title: "Perfectionist",
            description: "Get 10 questions correct in a row",
            icon: "💎",
            xpReward: 300,
            rarity: .epic,
            condition: .perfectQuizStreak(count: 10)
        ),
        Achievement(
            id: "level_up",
            title: "Level Up",
            description: "Reach level 5",
            icon: "📈",
            xpReward: 100,
            rarity: .uncommon,
            condition: .reachLevel(level: 5)
        ),
        Achievement(
            id: "elite_player",
            title: "Elite Player",
            description: "Reach level 10",
            icon: "👑",
            xpReward: 500,
            rarity: .epic,
            condition: .reachLevel(level: 10)
        ),
        Achievement(
            id: "point_collector",
            title: "Point Collector",
            description: "Earn 1000 total points",
            icon: "💰",
            xpReward: 200,
            rarity: .rare,
            condition: .completeQuizzes(count: 100) // Using quiz count as proxy
        ),
        Achievement(
            id: "history_buff",
            title: "History Buff",
            description: "Complete 10 history quizzes",
            icon: "📜",
            xpReward: 150,
            rarity: .uncommon,
            condition: .visitCategory(category: "historic", count: 10)
        ),
        Achievement(
            id: "foodie",
            title: "Foodie",
            description: "Complete 10 food & drink quizzes",
            icon: "🍺",
            xpReward: 150,
            rarity: .uncommon,
            condition: .visitCategory(category: "food", count: 10)
        ),
        Achievement(
            id: "city_legend",
            title: "City Legend",
            description: "Complete ALL locations (100%)",
            icon: "🌟",
            xpReward: 1000,
            rarity: .legendary,
            condition: .visitLocations(count: 48)
        ),
        Achievement(
            id: "streak_master",
            title: "Streak Master",
            description: "Maintain a 7-day playing streak",
            icon: "🔥",
            xpReward: 300,
            rarity: .epic,
            condition: .perfectQuizStreak(count: 7) // Using streak tracking
        ),
        Achievement(
            id: "secret_spy",
            title: "Secret Spy",
            description: "Discover a secret achievement",
            icon: "🕵️",
            xpReward: 200,
            rarity: .rare,
            condition: .completeQuizzes(count: 1)
        ),
        Achievement(
            id: "globe_trotter",
            title: "Globe Trotter",
            description: "Visit all districts in Munich",
            icon: "🌍",
            xpReward: 400,
            rarity: .epic,
            condition: .visitLocations(count: 20)
        ),
        Achievement(
            id: "tourist_trap",
            title: "Tourist Trap",
            description: "Visit only tourist locations first",
            icon: "📸",
            xpReward: 150,
            rarity: .uncommon,
            condition: .visitLocations(count: 3)
        ),
        Achievement(
            id: "local_hero",
            title: "Local Hero",
            description: "Complete 5 'hidden gem' locations",
            icon: "🦸",
            xpReward: 250,
            rarity: .rare,
            condition: .visitLocations(count: 5)
        )
    ]
}
