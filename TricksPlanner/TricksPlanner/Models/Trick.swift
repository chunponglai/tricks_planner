import Foundation

enum Difficulty: String, CaseIterable, Identifiable, Codable {
    case none
    case easy
    case medium
    case hard

    var id: String { rawValue }
}

enum ChallengeStatus: String, CaseIterable, Identifiable, Codable {
    case notDone
    case success
    case fail

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .notDone: return "Not Done"
        case .success: return "Success"
        case .fail: return "Fail"
        }
    }
}

struct Challenge: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var combo: [Trick]
    var status: ChallengeStatus

    init(id: UUID = UUID(), date: Date, combo: [Trick], status: ChallengeStatus = .notDone) {
        self.id = id
        self.date = date
        self.combo = combo
        self.status = status
    }
}

struct Trick: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var category: String
    var difficulty: Difficulty

    init(id: UUID = UUID(), name: String, category: String, difficulty: Difficulty = .none) {
        self.id = id
        self.name = name
        self.category = category
        self.difficulty = difficulty
    }

    enum CodingKeys: String, CodingKey {
        case id, name, category, difficulty
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        category = try container.decode(String.self, forKey: .category)
        difficulty = (try? container.decode(Difficulty.self, forKey: .difficulty)) ?? .none
    }
}
