import Foundation

struct Trick: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var category: String

    init(id: UUID = UUID(), name: String, category: String) {
        self.id = id
        self.name = name
        self.category = category
    }
}
