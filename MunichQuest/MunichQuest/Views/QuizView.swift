import SwiftUI

struct QuizView: View {
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.dismiss) var dismiss

    let location: LocationData
    @State private var currentQuizIndex = 0
    @State private var selectedAnswer: Int? = nil
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var sessionXP = 0  // XP earned in this quiz session
    @State private var showLevelUpAlert = false
    @State private var previousLevel = 0

    private var quizzes: [Quiz] {
        gameManager.getQuizzesForLocation(location.id)
    }

    private var currentQuiz: Quiz? {
        quizzes.indices.contains(currentQuizIndex) ? quizzes[currentQuizIndex] : nil
    }

    private var userTotalXP: Int {
        gameManager.userProgress?.totalXP ?? 0
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    if let quiz = currentQuiz {
                        // Header with progress and XP
                        VStack(spacing: 12) {
                            HStack {
                                Text("Question \(currentQuizIndex + 1)/\(quizzes.count)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                // Total XP Display
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.caption)
                                        .foregroundColor(Color(red: 0.95, green: 0.75, blue: 0.0))
                                    Text("\(userTotalXP) XP")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                }
                            }

                            // XP Reward Badge
                            if !showResult {
                                HStack(spacing: 6) {
                                    Image(systemName: "star.fill")
                                        .font(.caption2)
                                        .foregroundColor(Color(red: 0.95, green: 0.75, blue: 0.0))
                                    Text("+\(quiz.xpReward) XP")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(Color(red: 0.95, green: 0.75, blue: 0.0))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(red: 0.95, green: 0.75, blue: 0.0).opacity(0.15))
                                .cornerRadius(20)
                            }
                        }
                        .padding()
                        .background(Color(UIColor.systemBackground))

                        Divider()

                        // Question
                        VStack(alignment: .leading, spacing: 20) {
                            Text(quiz.question)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 8)

                            // Answer Options
                            VStack(spacing: 12) {
                                ForEach(Array(quiz.options.enumerated()), id: \.offset) { index, option in
                                    AnswerOption(
                                        text: option,
                                        isSelected: selectedAnswer == index,
                                        isCorrect: showResult && index == quiz.correctAnswer,
                                        isWrong: showResult && selectedAnswer == index && index != quiz.correctAnswer
                                    )
                                    .onTapGesture {
                                        if !showResult {
                                            selectedAnswer = index
                                            // Auto-submit immediately after selection
                                            submitAnswer()
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(UIColor.systemBackground))

                        // Feedback Section
                        if showResult {
                            VStack(spacing: 16) {
                                Divider()

                                // Result message
                                HStack(spacing: 12) {
                                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(isCorrect ? .green : .red)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(isCorrect ? "Correct!" : "Incorrect")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        if isCorrect {
                                            Text("+\(quiz.xpReward) XP earned")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding()
                                .background(isCorrect ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                                .cornerRadius(12)

                                // Explanation
                                if !quiz.explanation.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Explanation")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text(quiz.explanation)
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(12)
                                }

                                // Fun Fact
                                if !quiz.funFact.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Image(systemName: "lightbulb.fill")
                                                .foregroundColor(Color(red: 0.95, green: 0.75, blue: 0.0))
                                            Text("Fun Fact")
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                        }
                                        Text(quiz.funFact)
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .background(Color(red: 0.95, green: 0.75, blue: 0.0).opacity(0.1))
                                    .cornerRadius(12)
                                }
                            }
                            .padding()
                            .background(Color(UIColor.systemBackground))
                        }

                        // Action Button - only show after answer is submitted
                        if showResult {
                            VStack {
                                Button(action: nextQuestion) {
                                    Text(currentQuizIndex < quizzes.count - 1 ? "Next Question" : "Complete")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color(red: 0.4, green: 0.49, blue: 0.92))
                                        .cornerRadius(12)
                                }
                            }
                            .padding()
                            .background(Color(UIColor.systemBackground))
                        }

                    } else {
                        VStack(spacing: 20) {
                            Text("No quizzes available")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                }
            }
            .background(Color(UIColor.secondarySystemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(location.name)
                        .font(.headline)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onAppear {
                previousLevel = gameManager.userProgress?.level ?? 1
            }
            .alert("Level Up!", isPresented: $showLevelUpAlert) {
                Button("Awesome!") { }
            } message: {
                Text("You reached level \(gameManager.userProgress?.level ?? 1)!")
            }
        }
    }

    private func submitAnswer() {
        guard let selected = selectedAnswer, let quiz = currentQuiz else { return }

        isCorrect = selected == quiz.correctAnswer
        showResult = true

        // Store level before submission
        let levelBefore = gameManager.userProgress?.level ?? 1

        // Always submit the answer (for both correct and incorrect)
        gameManager.submitQuizAnswer(quiz: quiz, selectedAnswer: selected)

        // Check for level up
        let levelAfter = gameManager.userProgress?.level ?? 1
        if levelAfter > levelBefore {
            showLevelUpAlert = true
        }
    }

    private func nextQuestion() {
        if currentQuizIndex < quizzes.count - 1 {
            currentQuizIndex += 1
            selectedAnswer = nil
            showResult = false
            isCorrect = false
        } else {
            dismiss()
        }
    }
}

struct AnswerOption: View {
    let text: String
    let isSelected: Bool
    let isCorrect: Bool
    let isWrong: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            if isCorrect {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.green)
            } else if isWrong {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 2)
        )
    }

    private var backgroundColor: Color {
        if isCorrect {
            return Color.green.opacity(0.1)
        } else if isWrong {
            return Color.red.opacity(0.1)
        } else if isSelected {
            return Color(red: 0.4, green: 0.49, blue: 0.92).opacity(0.1)
        } else {
            return Color(UIColor.tertiarySystemBackground)
        }
    }

    private var borderColor: Color {
        if isCorrect {
            return .green
        } else if isWrong {
            return .red
        } else if isSelected {
            return Color(red: 0.4, green: 0.49, blue: 0.92)
        } else {
            return Color(UIColor.separator)
        }
    }
}
