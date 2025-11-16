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
                        // Safe area spacer
                        Spacer().frame(height: 0)

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
                .ignoresSafeArea(edges: [])
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
        .background(Color(UIColor.tertiarySystemBackground))
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

        let filtered = if selectedCategories.isEmpty {
            locations
        } else {
            locations.filter { selectedCategories.contains($0.category) }
        }

        // Sort: Completed first, then in-progress, then locked. Within each group, sort by name
        return filtered.sorted { loc1, loc2 in
            let status1 = getLocationCompletionStatus(loc1)
            let status2 = getLocationCompletionStatus(loc2)

            if status1 != status2 {
                // Completed (2) > In Progress (1) > Locked (0)
                return status1 > status2
            }
            return loc1.name < loc2.name
        }
    }

    private func getLocationCompletionStatus(_ location: LocationData) -> Int {
        let isVisited = progress.locationsVisited.contains(location.id)
        if !isVisited { return 0 } // Locked

        let quizzes = gameManager.getQuizzesForLocation(location.id)
        let completed = quizzes.filter { progress.quizzesCompleted.contains($0.id) }.count
        let isCompleted = quizzes.count > 0 && completed == quizzes.count

        return isCompleted ? 2 : 1 // Completed : In Progress
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

    @State private var showLocationDetail = false

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
                        HStack(spacing: 6) {
                            Text("\(quizProgress.completed)/\(quizProgress.total) questions")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            // Mini progress bar
                            if quizProgress.total > 0 {
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(height: 4)

                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(isCompleted ? Color.green : Color(red: 0.4, green: 0.49, blue: 0.92))
                                            .frame(width: geometry.size.width * CGFloat(quizProgress.completed) / CGFloat(quizProgress.total), height: 4)
                                    }
                                }
                                .frame(width: 50, height: 4)
                            }
                        }
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
        .background(isVisited ? Color(UIColor.secondarySystemBackground) : Color(UIColor.tertiarySystemBackground))
        .cornerRadius(12)
        .onTapGesture {
            // Show detail popup for visited locations (especially completed ones)
            if isVisited {
                showLocationDetail = true
            }
        }
        .sheet(isPresented: $showLocationDetail) {
            LocationStatsDetailSheet(location: location, progress: progress)
                .environmentObject(gameManager)
        }
    }

    private func openDirections() {
        let clLocation = CLLocation(
            latitude: location.coordinates.lat,
            longitude: location.coordinates.lng
        )
        let mapItem = MKMapItem(location: clLocation, address: nil)
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
        case .perfectQuizStreak(_):
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

    private var rarityText: String {
        switch achievement.rarity {
        case .common: return "Common"
        case .uncommon: return "Uncommon"
        case .rare: return "Rare"
        case .epic: return "Epic"
        case .legendary: return "Legendary"
        }
    }

    var body: some View {
        VStack(spacing: 8) {
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

                // Rarity badge
                Text(rarityText)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(rarityColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(rarityColor.opacity(0.15))
                    .cornerRadius(6)

                // XP reward (always visible)
                Text("+\(achievement.xpReward) XP")
                    .font(.caption2)
                    .foregroundColor(.orange)
                    .fontWeight(.semibold)

                // Progress bar (only for locked)
                if !isUnlocked {
                    VStack(spacing: 4) {
                        ProgressView(value: progress)
                            .tint(rarityColor)
                            .scaleEffect(x: 1, y: 1.2)

                        Text("\(Int(progress * 100))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 2)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 180)
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
            ("daily_answer_5", "Answer 5 questions correctly today", 5, 50),
            ("daily_visit_3", "Visit 3 different locations today", 3, 30),
            ("daily_earn_100xp", "Earn 100 XP today", 100, 100)
        ]

        let selectedIndices = [
            challengeIndex % allChallenges.count,
            (challengeIndex + 1) % allChallenges.count,
            (challengeIndex + 2) % allChallenges.count
        ]

        return selectedIndices.map { index in
            let (id, title, target, xp) = allChallenges[index]
            // Use stored daily progress instead of cumulative stats
            let currentProgress = progress.getDailyChallengeProgress(challengeId: id)

            return DailyChallenge(
                id: id,
                title: title,
                target: target,
                currentProgress: min(currentProgress, target),
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

// MARK: - Achievement Detail Sheet
struct AchievementDetailSheet: View {
    let achievement: Achievement
    let isUnlocked: Bool
    let progress: Double
    @Environment(\.dismiss) var dismiss

    private var rarityColor: Color {
        switch achievement.rarity {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return Color(red: 0.95, green: 0.75, blue: 0.0)
        }
    }

    private var rarityText: String {
        switch achievement.rarity {
        case .common: return "Common"
        case .uncommon: return "Uncommon"
        case .rare: return "Rare"
        case .epic: return "Epic"
        case .legendary: return "Legendary"
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Icon
                    Text(isUnlocked ? achievement.icon : "🔒")
                        .font(.system(size: 80))
                        .opacity(isUnlocked ? 1.0 : 0.4)
                        .padding(.top, 20)

                    // Title
                    Text(achievement.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    // Rarity Badge
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                        Text(rarityText.uppercased())
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(rarityColor)
                    .cornerRadius(12)

                    // Description
                    VStack(spacing: 15) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            Text(achievement.description)
                                .font(.body)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)

                        // Rewards
                        HStack(spacing: 20) {
                            VStack {
                                Image(systemName: "star.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(Color(red: 0.95, green: 0.75, blue: 0.0))
                                Text("+\(achievement.xpReward) XP")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)

                            VStack {
                                Image(systemName: "chart.bar.fill")
                                    .font(.title2)
                                    .foregroundColor(rarityColor)
                                Text(rarityText)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                        }

                        // Progress
                        if !isUnlocked {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Progress")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(Int(progress * 100))%")
                                        .font(.headline)
                                        .foregroundColor(Color(red: 0.4, green: 0.49, blue: 0.92))
                                }

                                ProgressView(value: progress)
                                    .tint(Color(red: 0.4, green: 0.49, blue: 0.92))
                                    .scaleEffect(x: 1, y: 2, anchor: .center)
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                        } else {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Unlocked!")
                                    .font(.headline)
                                    .foregroundColor(.green)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("Achievement Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Location Stats Detail Sheet
struct LocationStatsDetailSheet: View {
    @EnvironmentObject var gameManager: GameManager
    let location: LocationData
    let progress: UserProgress
    @Environment(\.dismiss) var dismiss

    private var quizProgress: (completed: Int, total: Int, correct: Int) {
        let quizzes = gameManager.getQuizzesForLocation(location.id)
        let completed = quizzes.filter { progress.quizzesCompleted.contains($0.id) }
        // Note: We don't track which answers were correct per quiz in current model
        return (completed.count, quizzes.count, completed.count)
    }

    private var isCompleted: Bool {
        quizProgress.completed == quizProgress.total && quizProgress.total > 0
    }

    private var progressPercentage: Double {
        guard quizProgress.total > 0 else { return 0 }
        return Double(quizProgress.completed) / Double(quizProgress.total)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    VStack(spacing: 15) {
                        Text(location.emoji)
                            .font(.system(size: 80))

                        Text(location.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        if let district = location.district {
                            HStack(spacing: 4) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.caption)
                                Text(district)
                                    .font(.subheadline)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 20)

                    // Completion Status
                    HStack {
                        Image(systemName: isCompleted ? "checkmark.seal.fill" : "hourglass")
                            .font(.title2)
                            .foregroundColor(isCompleted ? .green : Color(red: 0.4, green: 0.49, blue: 0.92))
                        Text(isCompleted ? "Completed!" : "In Progress")
                            .font(.headline)
                            .foregroundColor(isCompleted ? .green : .primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isCompleted ? Color.green.opacity(0.1) : Color(red: 0.4, green: 0.49, blue: 0.92).opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Stats
                    VStack(spacing: 15) {
                        // Quiz Progress
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Quiz Progress")
                                    .font(.headline)
                                Spacer()
                                Text("\(quizProgress.completed)/\(quizProgress.total)")
                                    .font(.headline)
                                    .foregroundColor(Color(red: 0.4, green: 0.49, blue: 0.92))
                            }

                            ProgressView(value: progressPercentage)
                                .tint(isCompleted ? .green : Color(red: 0.4, green: 0.49, blue: 0.92))
                                .scaleEffect(x: 1, y: 2, anchor: .center)

                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("\(quizProgress.completed) questions answered")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            if quizProgress.completed < quizProgress.total {
                                HStack {
                                    Image(systemName: "circle.dotted")
                                        .foregroundColor(.orange)
                                    Text("\(quizProgress.total - quizProgress.completed) questions remaining")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)

                        // Location Info
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Location Details")
                                .font(.headline)

                            HStack(spacing: 8) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.orange)
                                Text("Difficulty: \(location.difficulty.capitalized)")
                                    .font(.subheadline)
                            }

                            HStack(spacing: 8) {
                                Image(systemName: "tag.fill")
                                    .foregroundColor(.blue)
                                Text("Category: \(location.category.capitalized)")
                                    .font(.subheadline)
                            }

                            if quizProgress.total > 0 {
                                HStack(spacing: 8) {
                                    Image(systemName: "questionmark.circle.fill")
                                        .foregroundColor(.purple)
                                    Text("\(quizProgress.total) total questions")
                                        .font(.subheadline)
                                }
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)

                        // Complete Location Guide (only show when completed)
                        if isCompleted {
                            VStack(alignment: .leading, spacing: 20) {
                                // Header
                                HStack {
                                    Image(systemName: "book.fill")
                                        .font(.title3)
                                        .foregroundColor(.green)
                                    Text("Complete Location Guide")
                                        .font(.headline)
                                }

                                // Description
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "text.alignleft")
                                            .foregroundColor(.blue)
                                        Text("About")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                    }
                                    Text(location.description)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }

                                Divider()

                                // Transportation
                                if let transportation = location.transportation {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "tram.fill")
                                                .foregroundColor(.orange)
                                            Text("How to Get Here")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                        }

                                        if let transit = transportation.transit, !transit.isEmpty {
                                            VStack(alignment: .leading, spacing: 4) {
                                                ForEach(transit, id: \.self) { line in
                                                    HStack(alignment: .top, spacing: 6) {
                                                        Text("🚇")
                                                        Text(line)
                                                            .font(.subheadline)
                                                            .foregroundColor(.secondary)
                                                    }
                                                }
                                            }
                                        }

                                        if let walking = transportation.walking {
                                            HStack(alignment: .top, spacing: 6) {
                                                Text("🚶")
                                                Text(walking)
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }

                                    Divider()
                                }

                                // Venues
                                if let venues = location.venues, !venues.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "mappin.and.ellipse")
                                                .foregroundColor(.red)
                                            Text("What to Do & See")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                        }

                                        ForEach(venues) { venue in
                                            VStack(alignment: .leading, spacing: 4) {
                                                HStack(spacing: 8) {
                                                    Text(venue.icon)
                                                        .font(.title3)
                                                    Text(venue.name)
                                                        .font(.subheadline)
                                                        .fontWeight(.semibold)
                                                }
                                                Text(venue.description)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                if let address = venue.address {
                                                    HStack(spacing: 4) {
                                                        Image(systemName: "mappin.circle")
                                                            .font(.caption2)
                                                        Text(address)
                                                            .font(.caption)
                                                    }
                                                    .foregroundColor(.secondary.opacity(0.8))
                                                }
                                            }
                                            .padding(.leading, 8)

                                            if venue.id != venues.last?.id {
                                                Divider()
                                                    .padding(.vertical, 4)
                                            }
                                        }
                                    }

                                    Divider()
                                }

                                // Visit Info
                                if let visitInfo = location.visitInfo {
                                    VStack(alignment: .leading, spacing: 12) {
                                        // Best Time
                                        if let bestTime = visitInfo.bestTime {
                                            VStack(alignment: .leading, spacing: 6) {
                                                HStack(spacing: 6) {
                                                    Image(systemName: "clock.fill")
                                                        .foregroundColor(.purple)
                                                    Text("Best Time to Visit")
                                                        .font(.subheadline)
                                                        .fontWeight(.semibold)
                                                }
                                                Text(bestTime)
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                        }

                                        // Events
                                        if let events = visitInfo.events, !events.isEmpty {
                                            VStack(alignment: .leading, spacing: 6) {
                                                HStack(spacing: 6) {
                                                    Image(systemName: "calendar.badge.exclamationmark")
                                                        .foregroundColor(.green)
                                                    Text("Events & Festivals")
                                                        .font(.subheadline)
                                                        .fontWeight(.semibold)
                                                }
                                                ForEach(events, id: \.self) { event in
                                                    HStack(alignment: .top, spacing: 6) {
                                                        Text("•")
                                                            .foregroundColor(.green)
                                                        Text(event)
                                                            .font(.subheadline)
                                                            .foregroundColor(.secondary)
                                                    }
                                                }
                                            }
                                        }

                                        // Tips
                                        if let tips = visitInfo.tips, !tips.isEmpty {
                                            VStack(alignment: .leading, spacing: 6) {
                                                HStack(spacing: 6) {
                                                    Image(systemName: "lightbulb.fill")
                                                        .foregroundColor(.yellow)
                                                    Text("Insider Tips")
                                                        .font(.subheadline)
                                                        .fontWeight(.semibold)
                                                }
                                                ForEach(tips, id: \.self) { tip in
                                                    HStack(alignment: .top, spacing: 6) {
                                                        Text("💡")
                                                        Text(tip)
                                                            .font(.subheadline)
                                                            .foregroundColor(.secondary)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color.green.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 2)
                            )
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("Location Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
