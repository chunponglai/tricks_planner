import Combine
import Foundation

final class TrickStore: ObservableObject {
    @Published private(set) var tricks: [Trick] = [] {
        didSet {
            guard hasLoaded else { return }
            save()
        }
    }

    @Published private(set) var categories: [String] = CategoryLibrary.defaultCategories {
        didSet {
            guard hasLoaded else { return }
            saveCategories()
        }
    }

    @Published private(set) var challenges: [Challenge] = [] {
        didSet {
            guard hasLoaded else { return }
            saveChallenges()
        }
    }

    private var hasLoaded = false

    init() {
        load()
        hasLoaded = true
    }

    // MARK: - CRUD

    func addTrick(name: String, category: String, difficulty: Difficulty) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }

        let finalCategory = cleanCategory.isEmpty ? "Uncategorized" : cleanCategory
        if !categories.contains(finalCategory) {
            categories.append(finalCategory)
        }

        let newTrick = Trick(name: cleanName, category: finalCategory, difficulty: difficulty)
        tricks.append(newTrick)
        sortTricks()
    }

    func updateTrick(_ trick: Trick, name: String, category: String, difficulty: Difficulty) {
        guard let index = tricks.firstIndex(where: { $0.id == trick.id }) else { return }
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }

        let finalCategory = cleanCategory.isEmpty ? "Uncategorized" : cleanCategory
        if !categories.contains(finalCategory) {
            categories.append(finalCategory)
        }

        tricks[index].name = cleanName
        tricks[index].category = finalCategory
        tricks[index].difficulty = difficulty
        sortTricks()
    }

    func deleteTricks(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            if tricks.indices.contains(index) {
                tricks.remove(at: index)
            }
        }
    }

    func addCategory(_ name: String) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }
        guard !categories.contains(cleanName) else { return }
        categories.append(cleanName)
        categories.sort()
    }

    func renameCategory(from oldName: String, to newName: String) {
        let cleanOld = oldName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanNew = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanOld.isEmpty, !cleanNew.isEmpty else { return }
        guard cleanOld != cleanNew else { return }
        guard let index = categories.firstIndex(of: cleanOld) else { return }
        categories[index] = cleanNew
        categories.sort()

        for i in tricks.indices {
            if tricks[i].category == cleanOld {
                tricks[i].category = cleanNew
            }
        }
        sortTricks()
    }

    func deleteCategory(_ name: String) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }
        let fallback = "Uncategorized"
        if !categories.contains(fallback) {
            categories.append(fallback)
        }
        categories.removeAll { $0 == cleanName }
        for i in tricks.indices {
            if tricks[i].category == cleanName {
                tricks[i].category = fallback
            }
        }
    }

    // MARK: - Combo

    private func difficultyRank(_ difficulty: Difficulty) -> Int {
        switch difficulty {
        case .none: return 0
        case .easy: return 1
        case .medium: return 2
        case .hard: return 3
        }
    }

    func randomCombo(from selections: [String: Int], maxDifficulty: Difficulty, randomAll: Bool) -> [Trick] {
        let allowedRank = difficultyRank(maxDifficulty)
        let filteredTricks = tricks.filter { difficultyRank($0.difficulty) <= allowedRank }
        let categoriesWithTricks = Set(filteredTricks.map { $0.category })
        let categoryList = randomAll
            ? categories.filter { categoriesWithTricks.contains($0) }
            : (selections.isEmpty ? categories : selections.keys.sorted())
        var combo: [Trick] = []

        for category in categoryList {
            let count = randomAll ? 1 : (selections[category] ?? 1)
            guard count > 0 else { continue }
            let options = filteredTricks.filter { $0.category == category }.shuffled()
            combo.append(contentsOf: options.prefix(count))
        }

        return combo
    }

    // MARK: - Challenges

    func addChallenge(combo: [Trick], date: Date) {
        let day = Calendar.current.startOfDay(for: date)
        let challenge = Challenge(date: day, combo: combo, status: .notDone)
        challenges.append(challenge)
        challenges.sort { $0.date > $1.date }
    }

    func updateChallengeStatus(_ challenge: Challenge, status: ChallengeStatus) {
        guard let index = challenges.firstIndex(where: { $0.id == challenge.id }) else { return }
        challenges[index].status = status
    }

    func deleteChallenges(at offsets: IndexSet, on date: Date) {
        let dayChallenges = challenges(on: date)
        let idsToDelete = offsets.map { dayChallenges[$0].id }
        challenges.removeAll { idsToDelete.contains($0.id) }
    }

    func deleteChallenge(_ challenge: Challenge) {
        challenges.removeAll { $0.id == challenge.id }
    }

    func challenges(on date: Date) -> [Challenge] {
        let day = Calendar.current.startOfDay(for: date)
        return challenges.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }
    }

    func successRate() -> Double {
        let completed = challenges.filter { $0.status != .notDone }
        guard !completed.isEmpty else { return 0 }
        let successCount = completed.filter { $0.status == .success }.count
        return Double(successCount) / Double(completed.count)
    }

    // MARK: - Persistence

    private func load() {
        let loadedTricks = loadJSON([Trick].self, from: tricksURL()) ?? []
        let loadedCategories = loadJSON([String].self, from: categoriesURL()) ?? []
        let loadedChallenges = loadJSON([Challenge].self, from: challengesURL()) ?? []

        if loadedTricks.isEmpty {
            tricks = SampleData.tricks
        } else {
            tricks = loadedTricks
        }

        if loadedCategories.isEmpty {
            categories = mergeCategories(from: tricks, existing: CategoryLibrary.defaultCategories)
        } else {
            categories = loadedCategories
        }

        if !categories.contains("Uncategorized") {
            categories.append("Uncategorized")
        }

        challenges = loadedChallenges
        sortTricks()
    }

    private func save() {
        saveJSON(tricks, to: tricksURL())
        categories = mergeCategories(from: tricks, existing: categories)
    }

    private func saveCategories() {
        saveJSON(categories, to: categoriesURL())
    }

    private func saveChallenges() {
        saveJSON(challenges, to: challengesURL())
    }

    private func mergeCategories(from tricks: [Trick], existing: [String] = []) -> [String] {
        let trickCategories = Set(tricks.map { $0.category })
        let existingSet = Set(existing)
        let combined = trickCategories.union(existingSet)
        return Array(combined).sorted()
    }

    private func sortTricks() {
        tricks.sort { lhs, rhs in
            if lhs.category == rhs.category {
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            return lhs.category.localizedCaseInsensitiveCompare(rhs.category) == .orderedAscending
        }
    }

    private func tricksURL() -> URL {
        documentsDirectory().appendingPathComponent("tricks.json")
    }

    private func categoriesURL() -> URL {
        documentsDirectory().appendingPathComponent("categories.json")
    }

    private func challengesURL() -> URL {
        documentsDirectory().appendingPathComponent("challenges.json")
    }

    private func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func loadJSON<T: Decodable>(_ type: T.Type, from url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func saveJSON<T: Encodable>(_ value: T, to url: URL) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
