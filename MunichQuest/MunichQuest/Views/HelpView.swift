import SwiftUI

struct HelpView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    // Header
                    VStack(spacing: 10) {
                        Text("How to Play")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)

                    // Instructions
                    VStack(alignment: .leading, spacing: 20) {
                        HelpSection(
                            title: "Explore Munich",
                            description: "Browse the map to discover 49 amazing locations around Munich. Each location has interesting facts and challenges waiting for you."
                        )

                        HelpSection(
                            title: "Visit Locations",
                            description: "Get close to a location (within 100m) to unlock it. You can then answer questions to gain access to extensive insights about the location, helping you better explore the city."
                        )

                        HelpSection(
                            title: "Answer Questions",
                            description: "Answer questions about the location's history, architecture, and culture. Each correct answer earns you points and XP."
                        )

                        HelpSection(
                            title: "Points vs. XP",
                            description: "Points are earned for each correct answer and determine your position on the leaderboard. XP (experience points) helps you level up and unlock achievements."
                        )

                        HelpSection(
                            title: "Location Status",
                            description: "A green checkmark indicates all questions for a location have been answered. Note that this doesn't require all answers to be correct, just answered."
                        )

                        HelpSection(
                            title: "Progress Tab",
                            description: "Track your journey in the Progress tab, where you can view your level, daily and weekly challenges, visited locations, and achievements."
                        )

                        HelpSection(
                            title: "Compete with Friends",
                            description: "Check the leaderboard to see how you rank against other explorers. Can you reach the top?"
                        )
                    }
                    .padding(.horizontal)
                    
                    // Tips
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Pro Tips")
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 10) {
                            TipRow(text: "Start with locations in the city center - they're closer together.")
                            TipRow(text: "Read the fun facts before taking the quiz for helpful hints.")
                            TipRow(text: "Some quizzes have explanations that teach you even more.")
                            TipRow(text: "Answer all questions at a location to unlock its full insights.")
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    // About
                    VStack(spacing: 10) {
                        Text("Munich Quest v1.0")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("Discover Munich's rich history and culture through interactive exploration.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .padding(.vertical)
            }
            .navigationTitle("Help")
        }
    }
}

struct HelpSection: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.headline)

            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

struct TipRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("💡")
            Text(text)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}
