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

    private var hasLoaded = false

    init() {
        load()
        hasLoaded = true
    }

    // MARK: - CRUD

    func addTrick(name: String, category: String, difficulty: Difficulty) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty, !cleanCategory.isEmpty else { return }

        if !categories.contains(cleanCategory) {
            categories.append(cleanCategory)
        }

        let newTrick = Trick(name: cleanName, category: cleanCategory, difficulty: difficulty)
        tricks.append(newTrick)
        sortTricks()
    }

    func updateTrick(_ trick: Trick, name: String, category: String, difficulty: Difficulty) {
        guard let index = tricks.firstIndex(where: { $0.id == trick.id }) else { return }
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty, !cleanCategory.isEmpty else { return }

        if !categories.contains(cleanCategory) {
            categories.append(cleanCategory)
        }

        tricks[index].name = cleanName
        tricks[index].category = cleanCategory
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

    // MARK: - Combo

    func randomCombo(from selections: [String: Int]) -> [Trick] {
        let categoryList = selections.isEmpty ? categories : selections.keys.sorted()
        var combo: [Trick] = []

        for category in categoryList {
            let count = selections[category] ?? 1
            guard count > 0 else { continue }
            let options = tricks.filter { $0.category == category }.shuffled()
            combo.append(contentsOf: options.prefix(count))
        }

        return combo
    }

    // MARK: - Persistence

    private func load() {
        let loadedTricks = loadJSON([Trick].self, from: tricksURL()) ?? []
        let loadedCategories = loadJSON([String].self, from: categoriesURL()) ?? []

        if loadedTricks.isEmpty {
            tricks = SampleData.tricks
        } else {
            tricks = loadedTricks
        }

        if loadedCategories.isEmpty {
            categories = mergeCategories(from: tricks)
        } else {
            categories = loadedCategories
        }

        sortTricks()
    }

    private func save() {
        saveJSON(tricks, to: tricksURL())
        categories = mergeCategories(from: tricks, existing: categories)
    }

    private func saveCategories() {
        saveJSON(categories, to: categoriesURL())
    }

    private func mergeCategories(from tricks: [Trick], existing: [String] = []) -> [String] {
        let trickCategories = Set(tricks.map { $0.category })
        let existingSet = Set(existing)
        let combined = trickCategories.union(existingSet).union(CategoryLibrary.defaultCategories)
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
