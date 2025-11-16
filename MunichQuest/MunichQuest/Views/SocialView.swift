import SwiftUI
import FirebaseAuth

struct SocialView: View {
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var authManager: AuthManager

    @State private var allUsers: [UserProgress] = []
    @State private var isLoading = true
    @State private var showLoginSheet = false
    @State private var showSignupSheet = false

    var body: some View {
        NavigationView {
            if authManager.isAuthenticated {
                leaderboardContent
                    .navigationTitle("Leaderboard")
                    .onAppear {
                        loadLeaderboard()
                    }
                    .refreshable {
                        loadLeaderboard()
                    }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Sign Out") {
                                authManager.logout()
                            }
                        }
                    }
            } else {
                loginPromptView
                    .navigationTitle("Social")
            }
        }
        .sheet(isPresented: $showLoginSheet) {
            LoginView()
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showSignupSheet) {
            SignupView()
                .environmentObject(authManager)
        }
    }

    @ViewBuilder
    private var leaderboardContent: some View {
        if isLoading {
            ProgressView()
        } else if allUsers.isEmpty {
            emptyStateView
        } else {
            leaderboardView
        }
    }

    private var loginPromptView: some View {
        VStack(spacing: 30) {
            Spacer()

            Text("👥")
                .font(.system(size: 80))

            Text("Compare with Friends")
                .font(.title)
                .fontWeight(.bold)

            Text("Create an account to see the leaderboard and compare your progress with other players!")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            VStack(spacing: 15) {
                Button(action: { showSignupSheet = true }) {
                    Text("Create Account")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 0.4, green: 0.49, blue: 0.92))
                        .cornerRadius(10)
                }

                Button(action: { showLoginSheet = true }) {
                    Text("Already Have Account? Sign In")
                        .font(.subheadline)
                        .foregroundColor(Color(red: 0.4, green: 0.49, blue: 0.92))
                }
            }
            .padding(.horizontal, 40)

            Spacer()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Text("📊")
                .font(.system(size: 60))
            Text("No players yet")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Be the first to complete a quest!")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var leaderboardView: some View {
        ScrollView {
                        VStack(spacing: 20) {
                            // Podium for top 3
                            if allUsers.count >= 3 {
                                PodiumView(users: Array(allUsers.prefix(3)))
                                    .padding()
                            }
                            
                            // Leaderboard
                            VStack(spacing: 0) {
                                ForEach(Array(allUsers.enumerated()), id: \.element.userId) { index, user in
                                    LeaderboardRow(
                                        rank: index + 1,
                                        user: user,
                                        isCurrentUser: user.userId == authManager.currentUser?.uid
                                    )
                                    
                                    if index < allUsers.count - 1 {
                                        Divider()
                                    }
                                }
                            }
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(15)
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
        }
    }
    
    private func loadLeaderboard() {
        Task {
            isLoading = true
            let users = await authManager.getAllUsers()
            // Sort by totalPoints for leaderboard comparison
            allUsers = users.sorted { $0.totalPoints > $1.totalPoints }
            isLoading = false
        }
    }
}

struct PodiumView: View {
    let users: [UserProgress]
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            // Second place
            if users.count > 1 {
                PodiumCard(user: users[1], place: 2, height: 100, color: .gray)
            }
            
            // First place
            PodiumCard(user: users[0], place: 1, height: 140, color: Color(red: 1.0, green: 0.84, blue: 0.0))
            
            // Third place
            if users.count > 2 {
                PodiumCard(user: users[2], place: 3, height: 80, color: Color(red: 0.8, green: 0.5, blue: 0.2))
            }
        }
    }
}

struct PodiumCard: View {
    let user: UserProgress
    let place: Int
    let height: CGFloat
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text("🎯")
                .font(.system(size: 40))
            
            Text(user.username)
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(1)

            Text("\(user.totalPoints)")
                .font(.headline)
                .foregroundColor(color)
            
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.3))
                    .frame(height: height)
                
                Text("\(place)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
        }
    }
}

struct LeaderboardRow: View {
    let rank: Int
    let user: UserProgress
    let isCurrentUser: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            Text("\(rank)")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(width: 30)
            
            Text("🎯")
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(user.username)
                    .font(.headline)
                    .foregroundColor(isCurrentUser ? Color(red: 0.4, green: 0.49, blue: 0.92) : .primary)
                
                HStack(spacing: 15) {
                    Label("\(user.totalPoints) pts", systemImage: "trophy.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Label("Lv \(user.level)", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if isCurrentUser {
                Image(systemName: "person.fill")
                    .foregroundColor(Color(red: 0.4, green: 0.49, blue: 0.92))
            }
        }
        .padding()
        .background(isCurrentUser ? Color(red: 0.4, green: 0.49, blue: 0.92).opacity(0.1) : Color.clear)
    }
}
