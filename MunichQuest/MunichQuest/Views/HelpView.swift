import SwiftUI

struct HelpView: View {
    @State private var selectedTab: HelpTab = .quickStart

    enum HelpTab: String, CaseIterable {
        case quickStart = "Quick Start"
        case howToPlay = "How to Play"
        case faq = "FAQ"
        case about = "About"
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Modern gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.15),
                        Color(red: 0.1, green: 0.1, blue: 0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Custom tab selector
                    HelpTabSelector(selectedTab: $selectedTab)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    // Content area
                    ScrollView {
                        VStack(spacing: 20) {
                            switch selectedTab {
                            case .quickStart:
                                QuickStartView()
                            case .howToPlay:
                                HowToPlayView()
                            case .faq:
                                FAQView()
                            case .about:
                                AboutView()
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Help & Guide")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Tab Selector
struct HelpTabSelector: View {
    @Binding var selectedTab: HelpView.HelpTab
    @Namespace private var animation

    var body: some View {
        HStack(spacing: 0) {
            ForEach(HelpView.HelpTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 8) {
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: selectedTab == tab ? .bold : .medium))
                            .foregroundColor(selectedTab == tab ? .white : .gray)

                        if selectedTab == tab {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 0.4, green: 0.49, blue: 0.92), Color(red: 0.6, green: 0.3, blue: 0.9)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(height: 3)
                                .matchedGeometryEffect(id: "tab", in: animation)
                        } else {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.clear)
                                .frame(height: 3)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
        .background(Color(white: 0.1, opacity: 0.5))
        .cornerRadius(12)
    }
}

// MARK: - Quick Start View
struct QuickStartView: View {
    var body: some View {
        VStack(spacing: 20) {
            // Hero section
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.4, green: 0.49, blue: 0.92), Color(red: 0.6, green: 0.3, blue: 0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)

                    Text("🏰")
                        .font(.system(size: 50))
                }

                Text("Welcome to Munich Quest")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Your adventure begins here")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.vertical)

            // Quick steps
            VStack(spacing: 16) {
                QuickStepCard(
                    number: "1",
                    icon: "map",
                    title: "Find a Location",
                    description: "Check the map for nearby attractions",
                    gradient: [Color(red: 0.4, green: 0.49, blue: 0.92), Color(red: 0.3, green: 0.6, blue: 0.95)]
                )

                QuickStepCard(
                    number: "2",
                    icon: "figure.walk",
                    title: "Visit the Spot",
                    description: "Get within 100m to unlock the quiz",
                    gradient: [Color(red: 0.6, green: 0.3, blue: 0.9), Color(red: 0.7, green: 0.2, blue: 0.85)]
                )

                QuickStepCard(
                    number: "3",
                    icon: "brain.head.profile",
                    title: "Answer Questions",
                    description: "Test your knowledge and earn points",
                    gradient: [Color(red: 0.9, green: 0.3, blue: 0.6), Color(red: 0.95, green: 0.4, blue: 0.5)]
                )

                QuickStepCard(
                    number: "4",
                    icon: "trophy",
                    title: "Level Up",
                    description: "Collect badges and climb the leaderboard",
                    gradient: [Color(red: 0.9, green: 0.6, blue: 0.2), Color(red: 0.95, green: 0.7, blue: 0.3)]
                )
            }

            // Pro tip
            ProTipCard(
                tip: "Start with Marienplatz! It's Munich's heart and has several locations nearby for easy exploring."
            )
        }
    }
}

// MARK: - How to Play View
struct HowToPlayView: View {
    var body: some View {
        VStack(spacing: 20) {
            // Game mechanics
            SectionHeader(title: "Game Mechanics", icon: "gamecontroller.fill")

            GameMechanicCard(
                icon: "map.fill",
                title: "Explore Munich",
                description: "Discover 113 unique locations across Munich - from historic landmarks to hidden gems. Each pin on the map tells a story!",
                color: Color(red: 0.4, green: 0.49, blue: 0.92)
            )

            GameMechanicCard(
                icon: "location.circle.fill",
                title: "Location Status",
                description: """
                • 🔒 Locked (Gray): Not yet visited
                • 🟢 In Progress (Green): Visited but quizzes incomplete
                • 🟡 Complete (Gold): All quizzes solved!
                """,
                color: Color(red: 0.6, green: 0.3, blue: 0.9)
            )

            GameMechanicCard(
                icon: "star.fill",
                title: "Difficulty Levels",
                description: """
                • 🟢 Easy: 10 points, 15 XP
                • 🟡 Medium: 15 points, 20 XP
                • 🔴 Hard: 20 points, 30 XP

                Higher difficulty = bigger rewards!
                """,
                color: Color(red: 0.9, green: 0.6, blue: 0.2)
            )

            GameMechanicCard(
                icon: "chart.bar.fill",
                title: "Progress Tracking",
                description: "Check the Stats tab to see your achievements, XP level, badges earned, and locations completed. Track your journey to Munich Master!",
                color: Color(red: 0.3, green: 0.7, blue: 0.5)
            )

            GameMechanicCard(
                icon: "trophy.fill",
                title: "Badges & Achievements",
                description: """
                Unlock exclusive badges:
                • First Steps: Visit 1 location
                • Explorer: Complete 10 locations
                • Adventurer: Complete 25 locations
                • History Buff: Complete 50 locations
                • Munich Master: Complete ALL locations!
                """,
                color: Color(red: 0.9, green: 0.3, blue: 0.6)
            )
        }
    }
}

// MARK: - FAQ View
struct FAQView: View {
    @State private var expandedQuestion: Int? = nil

    var body: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Frequently Asked Questions", icon: "questionmark.circle.fill")

            FAQItem(
                question: "How close do I need to be to unlock a location?",
                answer: "You need to be within 100 meters (about 330 feet) of a location to unlock its quiz. The app uses your GPS to detect when you're nearby!",
                index: 0,
                expandedIndex: $expandedQuestion
            )

            FAQItem(
                question: "Can I retake quizzes?",
                answer: "Currently, once you answer a quiz question, it's marked as complete. This makes each decision count and encourages thoughtful answers!",
                index: 1,
                expandedIndex: $expandedQuestion
            )

            FAQItem(
                question: "What if there are no quizzes at a location?",
                answer: "Some locations auto-complete when you visit them! They'll turn golden on the map immediately. We're constantly adding new quizzes to more locations.",
                index: 2,
                expandedIndex: $expandedQuestion
            )

            FAQItem(
                question: "How is my level calculated?",
                answer: "Your level is based on total XP earned. Each quiz gives you XP based on difficulty (15-30 XP). The more locations you complete, the higher your level!",
                index: 3,
                expandedIndex: $expandedQuestion
            )

            FAQItem(
                question: "Is the app free?",
                answer: "Yes! Munich Quest is completely free. Explore Munich, learn its history, and have fun without any costs or in-app purchases.",
                index: 4,
                expandedIndex: $expandedQuestion
            )

            FAQItem(
                question: "How do I climb the leaderboard?",
                answer: "Complete more locations and answer questions correctly to earn points. The leaderboard ranks players by total points earned. Can you reach #1?",
                index: 5,
                expandedIndex: $expandedQuestion
            )

            FAQItem(
                question: "Does this work offline?",
                answer: "The game data works offline once loaded, but you'll need internet for the map, leaderboard, and account features. GPS works offline for location detection!",
                index: 6,
                expandedIndex: $expandedQuestion
            )
        }
    }
}

// MARK: - About View
struct AboutView: View {
    var body: some View {
        VStack(spacing: 24) {
            // App icon and version
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.4, green: 0.49, blue: 0.92), Color(red: 0.6, green: 0.3, blue: 0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)

                    Text("🏰")
                        .font(.system(size: 60))
                }

                Text("Munich Quest")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Version 1.0")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.vertical)

            // Description
            ModernCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("About")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("Munich Quest transforms exploring Munich into an interactive adventure. Discover hidden gems, learn fascinating history, and compete with friends while exploring Bavaria's capital city.")
                        .font(.body)
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Features
            ModernCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("✨ Features")
                        .font(.headline)
                        .foregroundColor(.white)

                    FeatureRow(icon: "map.fill", text: "113 unique locations")
                    FeatureRow(icon: "brain.head.profile", text: "377 engaging quiz questions")
                    FeatureRow(icon: "trophy.fill", text: "5 achievement badges")
                    FeatureRow(icon: "chart.bar.fill", text: "Real-time leaderboard")
                    FeatureRow(icon: "star.fill", text: "XP & leveling system")
                }
            }

            // Credits
            ModernCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Created with ❤️ in Munich")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("Built for curious explorers who want to experience Munich beyond the tourist trails.")
                        .font(.body)
                        .foregroundColor(.gray)
                }
            }

            // Social
            ModernCard {
                VStack(spacing: 12) {
                    Text("Share Your Adventure")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("Found a cool location? Share your progress with #MunichQuest")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}

// MARK: - Reusable Components

struct QuickStepCard: View {
    let number: String
    let icon: String
    let title: String
    let description: String
    let gradient: [Color]

    var body: some View {
        HStack(spacing: 16) {
            // Number badge
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                Text(number)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(gradient[0])

                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                }

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(white: 0.1, opacity: 0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [gradient[0].opacity(0.3), gradient[1].opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

struct GameMechanicCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        ModernCard {
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
        }
    }
}

struct ProTipCard: View {
    let tip: String

    var body: some View {
        HStack(spacing: 12) {
            Text("💡")
                .font(.title2)

            VStack(alignment: .leading, spacing: 4) {
                Text("Pro Tip")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.9, green: 0.6, blue: 0.2))

                Text(tip)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.9, green: 0.6, blue: 0.2).opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(red: 0.9, green: 0.6, blue: 0.2).opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct FAQItem: View {
    let question: String
    let answer: String
    let index: Int
    @Binding var expandedIndex: Int?

    var isExpanded: Bool {
        expandedIndex == index
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if isExpanded {
                        expandedIndex = nil
                    } else {
                        expandedIndex = index
                    }
                }
            } label: {
                HStack {
                    Text(question)
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.4, green: 0.49, blue: 0.92))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding()
            }

            if isExpanded {
                Text(answer)
                    .font(.body)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                    .padding(.bottom)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(white: 0.1, opacity: 0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isExpanded ?
                            Color(red: 0.4, green: 0.49, blue: 0.92).opacity(0.5) :
                            Color.clear,
                            lineWidth: 1
                        )
                )
        )
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color(red: 0.4, green: 0.49, blue: 0.92))

            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Spacer()
        }
        .padding(.top)
    }
}

struct ModernCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(white: 0.1, opacity: 0.5))
            )
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(Color(red: 0.4, green: 0.49, blue: 0.92))
                .frame(width: 24)

            Text(text)
                .font(.body)
                .foregroundColor(.gray)

            Spacer()
        }
    }
}
