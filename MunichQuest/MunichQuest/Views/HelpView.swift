import SwiftUI

struct HelpView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    // Header
                    VStack(spacing: 10) {
                        Text("🏰")
                            .font(.system(size: 60))
                        
                        Text("How to Play")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                    
                    // Instructions
                    VStack(alignment: .leading, spacing: 20) {
                        HelpSection(
                            icon: "map.fill",
                            title: "Explore Munich",
                            description: "Browse the map to discover 49 amazing locations around Munich. Each location has interesting facts and challenges waiting for you!"
                        )
                        
                        HelpSection(
                            icon: "location.fill",
                            title: "Visit Locations",
                            description: "Get close to a location (within 100m) to unlock its quiz. The location marker will show you when you're nearby."
                        )
                        
                        HelpSection(
                            icon: "questionmark.circle.fill",
                            title: "Take Quizzes",
                            description: "Answer questions about the location's history, architecture, and culture. Each correct answer earns you points!"
                        )
                        
                        HelpSection(
                            icon: "star.fill",
                            title: "Earn Points & Level Up",
                            description: "Collect points to level up! Each level unlocks new achievements and brings you closer to becoming a Munich Master."
                        )
                        
                        HelpSection(
                            icon: "trophy.fill",
                            title: "Collect Badges",
                            description: "Earn special badges for completing challenges: First Steps (1 location), Explorer (10 locations), History Buff (25 locations), Munich Master (all locations)!"
                        )
                        
                        HelpSection(
                            icon: "person.3.fill",
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
                            TipRow(text: "Start with locations in the city center - they're closer together!")
                            TipRow(text: "Read the fun facts before taking the quiz for helpful hints")
                            TipRow(text: "Some quizzes have explanations that teach you even more")
                            TipRow(text: "Complete all quizzes at a location to mark it as finished")
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
                        
                        Text("Discover Munich's rich history and culture through interactive exploration")
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
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color(red: 0.4, green: 0.49, blue: 0.92))
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
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
