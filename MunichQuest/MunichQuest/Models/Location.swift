import Foundation
import CoreLocation

// MARK: - Location Models
struct LocationData: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let emoji: String
    let coordinates: Coordinates
    private let _radius: Double?
    let category: String
    let district: String?
    let difficulty: String
    let unlockLevel: Int
    let description: String
    let shortDescription: String
    let imageUrl: String
    let quizIds: [String]
    let transportation: Transportation?
    let venues: [Venue]?
    let visitInfo: VisitInfo?

    var radius: Double {
        _radius ?? 100.0 // Default to 100 meters if not specified
    }

    enum CodingKeys: String, CodingKey {
        case id, name, emoji, coordinates, category, district, difficulty, unlockLevel, description, shortDescription, imageUrl, quizIds, transportation, venues, visitInfo
        case _radius = "radius"
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: coordinates.lat, longitude: coordinates.lng)
    }

    var categoryColor: String {
        switch category {
        case "historic": return "blue"
        case "nature": return "green"
        case "culture": return "purple"
        case "food": return "orange"
        case "entertainment": return "pink"
        case "sports": return "red"
        default: return "gray"
        }
    }

    var difficultyStars: Int {
        switch difficulty {
        case "easy": return 1
        case "medium": return 2
        case "hard": return 3
        default: return 1
        }
    }
}

struct Coordinates: Codable, Hashable, Sendable {
    let lat: Double
    let lng: Double
}

struct Transportation: Codable, Hashable, Sendable {
    let transit: [String]?
    let walking: String?
}

struct Venue: Codable, Identifiable, Hashable, Sendable {
    var id: String { name }
    let icon: String
    let name: String
    let description: String
    let address: String?
}

struct VisitInfo: Codable, Hashable, Sendable {
    let bestTime: String?
    let events: [String]?
    let tips: [String]?
}

// MARK: - Quiz Models
struct Quiz: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let locationId: String
    let category: String
    let difficulty: String
    let question: String
    let options: [String]
    let correctAnswer: Int
    let points: Int
    let xpReward: Int
    let explanation: String
    let funFact: String
    let tags: [String]
}

// MARK: - Game Data Container
struct GameData: Codable, Sendable {
    let locations: [String: LocationData]
    let quizzes: [String: Quiz]
}

// MARK: - Leaderboard Entry
struct LeaderboardEntry: Identifiable, Codable {
    let id: String
    let username: String
    let totalXP: Int
    let level: Int
    let locationsVisited: Int
    let quizzesPassed: Int
    let rank: Int
}
