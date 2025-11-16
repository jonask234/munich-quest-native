import SwiftUI
import MapKit

struct LocationDetailSheet: View {
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var locationManager: LocationManager
    @Environment(\.dismiss) var dismiss

    let location: LocationData
    var autoTriggered: Bool = false
    @State private var showQuiz = false

    private var distanceToLocation: Double? {
        locationManager.distance(to: location)
    }

    private var isNearby: Bool {
        guard let distance = distanceToLocation else { return false }
        return distance <= Double(location.radius)
    }

    private var isVisited: Bool {
        gameManager.userProgress?.locationsVisited.contains(location.id) ?? false
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(spacing: 10) {
                    Text(location.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .padding(.top, 20)

                // Description
                VStack(alignment: .leading, spacing: 10) {
                    Text("About")
                        .font(.headline)

                    Text(location.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                // Additional Info
                VStack(alignment: .leading, spacing: 10) {
                    Text("Details")
                        .font(.headline)

                    if let district = location.district {
                        HStack(alignment: .top, spacing: 8) {
                            Text("📍")
                            Text("District: \(district)")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack(alignment: .top, spacing: 8) {
                        Text("⭐")
                        Text("Difficulty: \(location.difficulty)")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)

                // Distance and Navigation
                if let distance = distanceToLocation {
                    HStack {
                        Image(systemName: "location.circle.fill")
                            .foregroundColor(isNearby ? .green : Color(red: 0.4, green: 0.49, blue: 0.92))
                        Text(distance < 1000 ? String(format: "%.0f m away", distance) : String(format: "%.1f km away", distance / 1000))
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Spacer()

                        Button(action: openInMaps) {
                            HStack(spacing: 4) {
                                Image(systemName: "map.fill")
                                Text("Navigate")
                            }
                            .font(.subheadline)
                            .foregroundColor(Color(red: 0.4, green: 0.49, blue: 0.92))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(red: 0.4, green: 0.49, blue: 0.92).opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }

                // Quiz/Check-in Button
                let quizzes = gameManager.getQuizzesForLocation(location.id)
                let quizCount = quizzes.count
                let completedQuizzes = quizzes.filter { gameManager.userProgress?.quizzesCompleted.contains($0.id) ?? false }
                let isCompleted = !quizzes.isEmpty && completedQuizzes.count == quizzes.count

                VStack(spacing: 15) {
                    if quizCount > 0 {
                        if isNearby && !isVisited {
                            // Check In button
                            Button(action: checkIn) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title2)
                                    VStack(alignment: .leading) {
                                        Text("Check In")
                                            .font(.headline)
                                            .foregroundColor(.green)
                                        Text("You're here! Check in to unlock quizzes")
                                            .font(.caption)
                                            .foregroundColor(.green.opacity(0.8))
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(10)
                            }
                            .foregroundColor(.green)
                        } else if isVisited {
                            // Quiz button (unlocked)
                            Button(action: { showQuiz = true }) {
                                HStack {
                                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "play.circle.fill")
                                        .font(.title2)
                                    VStack(alignment: .leading) {
                                        Text(isCompleted ? "All Quizzes Completed!" : "Take Quiz")
                                            .font(.headline)
                                            .foregroundColor(isCompleted ? .green : Color(red: 0.4, green: 0.49, blue: 0.92))
                                        Text("\(completedQuizzes.count)/\(quizCount) questions completed")
                                            .font(.caption)
                                            .foregroundColor((isCompleted ? Color.green : Color(red: 0.4, green: 0.49, blue: 0.92)).opacity(0.8))
                                    }
                                    Spacer()
                                    if !isCompleted {
                                        Image(systemName: "chevron.right")
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(isCompleted ? Color.green.opacity(0.1) : Color(red: 0.4, green: 0.49, blue: 0.92).opacity(0.1))
                                .cornerRadius(10)
                            }
                            .foregroundColor(isCompleted ? .green : Color(red: 0.4, green: 0.49, blue: 0.92))
                            .disabled(isCompleted)
                        } else {
                            // Locked (not nearby)
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(Color(red: 0.4, green: 0.49, blue: 0.92))
                                VStack(alignment: .leading) {
                                    Text("Quiz Locked")
                                        .font(.headline)
                                    Text("Visit this location to unlock \(quizCount) quiz questions")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(red: 0.4, green: 0.49, blue: 0.92).opacity(0.1))
                            .cornerRadius(10)
                            .foregroundColor(Color(red: 0.4, green: 0.49, blue: 0.92))
                        }
                    } else {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.secondary)
                            Text("No quizzes available yet")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .padding(.bottom, 20)
        }
        .overlay(alignment: .topTrailing) {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .sheet(isPresented: $showQuiz) {
            QuizView(location: location)
                .environmentObject(gameManager)
        }
        .onAppear {
            // Auto-trigger quiz if location detail was auto-opened due to proximity
            // and user has already visited this location
            if autoTriggered && isVisited {
                let quizzes = gameManager.getQuizzesForLocation(location.id)
                let hasIncompleteQuizzes = quizzes.contains { quiz in
                    !(gameManager.userProgress?.quizzesCompleted.contains(quiz.id) ?? false)
                }

                if hasIncompleteQuizzes {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showQuiz = true
                    }
                }
            }
        }
    }

    private func checkIn() {
        guard let userLocation = locationManager.userLocation else { return }
        gameManager.visitLocation(location, at: userLocation)

        // Auto-trigger quiz after check-in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showQuiz = true
        }
    }

    private func openInMaps() {
        let coordinate = CLLocationCoordinate2D(
            latitude: location.coordinates.lat,
            longitude: location.coordinates.lng
        )

        // Use iOS 26+ API
        if #available(iOS 26.0, *) {
            let clLocation = CLLocation(latitude: location.coordinates.lat, longitude: location.coordinates.lng)
            let mapItem = MKMapItem(location: clLocation, address: nil)
            mapItem.name = location.name
            mapItem.openInMaps(launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
            ])
        } else {
            // Fallback for older iOS versions
            let placemark = MKPlacemark(coordinate: coordinate)
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = location.name
            mapItem.openInMaps(launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
            ])
        }
    }
}
