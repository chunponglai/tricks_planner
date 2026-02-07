import Combine
import Foundation

final class TrickStore: ObservableObject {
    @Published private(set) var isSyncing = false
    @Published private(set) var isSyncQueued = false
    @Published private(set) var syncError: String?

    @Published private(set) var tricks: [Trick] = [] {
        didSet {
            guard hasLoaded else { return }
            save()
            scheduleSync()
        }
    }

    @Published private(set) var categories: [String] = CategoryLibrary.defaultCategories {
        didSet {
            guard hasLoaded else { return }
            saveCategories()
            scheduleSync()
        }
    }

    @Published private(set) var challenges: [Challenge] = [] {
        didSet {
            guard hasLoaded else { return }
            saveChallenges()
            scheduleSync()
        }
    }

    @Published private(set) var trainingPlans: [DailyTrainingPlan] = [] {
        didSet {
            guard hasLoaded else { return }
            saveTrainingPlans()
            scheduleSync()
        }
    }

    @Published private(set) var trainingTemplates: [TrainingTemplate] = [] {
        didSet {
            guard hasLoaded else { return }
            saveTrainingTemplates()
            scheduleSync()
        }
    }

    private var hasLoaded = false
    private var authToken: String?
    private var isApplyingRemote = false
    private var syncTask: Task<Void, Never>?
    private var syncFailureCount = 0
    private var pendingSyncErrorToken: UUID?
    private let syncEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()
    private let syncDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    init() {
        load()
        hasLoaded = true
    }

    func updateAuthToken(_ token: String?) {
        authToken = token
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

    // MARK: - Training

    func trainingItems(on date: Date) -> [TrainingItem] {
        let day = Calendar.current.startOfDay(for: date)
        return trainingPlans.first(where: { Calendar.current.isDate($0.date, inSameDayAs: day) })?.items ?? []
    }

    func hasAppliedTemplate(_ template: TrainingTemplate, on date: Date) -> Bool {
        let day = Calendar.current.startOfDay(for: date)
        guard let plan = trainingPlans.first(where: { Calendar.current.isDate($0.date, inSameDayAs: day) }) else { return false }
        return plan.appliedTemplateIds.contains(template.id)
    }

    func addTrainingItem(trick: Trick, target: Int, date: Date) {
        let day = Calendar.current.startOfDay(for: date)
        let safeTarget = max(target, 1)
        let newItem = TrainingItem(
            trickId: trick.id,
            trickName: trick.name,
            category: trick.category,
            difficulty: trick.difficulty,
            targetCount: safeTarget,
            templateId: nil
        )

        if let index = trainingPlans.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: day) }) {
            if let itemIndex = trainingPlans[index].items.firstIndex(where: { $0.trickId == trick.id }) {
                trainingPlans[index].items[itemIndex].targetCount += safeTarget
            } else {
                trainingPlans[index].items.append(newItem)
            }
        } else {
            trainingPlans.append(DailyTrainingPlan(date: day, items: [newItem]))
        }
        sortTrainingPlans()
    }

    func updateTrainingItem(_ item: TrainingItem, completed: Int, date: Date) {
        let day = Calendar.current.startOfDay(for: date)
        guard let planIndex = trainingPlans.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: day) }) else { return }
        guard let itemIndex = trainingPlans[planIndex].items.firstIndex(where: { $0.id == item.id }) else { return }
        let safeValue = max(0, min(completed, trainingPlans[planIndex].items[itemIndex].targetCount))
        trainingPlans[planIndex].items[itemIndex].completedCount = safeValue
    }

    func incrementTrainingItem(_ item: TrainingItem, date: Date, delta: Int) {
        let day = Calendar.current.startOfDay(for: date)
        guard let planIndex = trainingPlans.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: day) }) else { return }
        guard let itemIndex = trainingPlans[planIndex].items.firstIndex(where: { $0.id == item.id }) else { return }
        let current = trainingPlans[planIndex].items[itemIndex].completedCount
        let target = trainingPlans[planIndex].items[itemIndex].targetCount
        let next = max(0, min(current + delta, target))
        trainingPlans[planIndex].items[itemIndex].completedCount = next
    }

    func deleteTrainingItem(_ item: TrainingItem, date: Date) {
        let day = Calendar.current.startOfDay(for: date)
        guard let planIndex = trainingPlans.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: day) }) else { return }
        trainingPlans[planIndex].items.removeAll { $0.id == item.id }
        if trainingPlans[planIndex].items.isEmpty {
            trainingPlans.remove(at: planIndex)
        }
    }

    func clearTraining(on date: Date) {
        let day = Calendar.current.startOfDay(for: date)
        trainingPlans.removeAll { Calendar.current.isDate($0.date, inSameDayAs: day) }
    }

    func trainingCompletion(for date: Date) -> (completed: Int, target: Int) {
        let items = trainingItems(on: date)
        let completed = items.reduce(0) { $0 + $1.completedCount }
        let target = items.reduce(0) { $0 + $1.targetCount }
        return (completed, target)
    }

    // MARK: - Templates

    func addTemplate(name: String) -> TrainingTemplate? {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return nil }
        let template = TrainingTemplate(name: cleanName)
        trainingTemplates.append(template)
        trainingTemplates.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        return template
    }

    func updateTemplate(_ template: TrainingTemplate) {
        guard let index = trainingTemplates.firstIndex(where: { $0.id == template.id }) else { return }
        trainingTemplates[index] = template
        trainingTemplates.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func deleteTemplate(_ template: TrainingTemplate) {
        trainingTemplates.removeAll { $0.id == template.id }
    }

    func applyTemplate(_ template: TrainingTemplate, to date: Date) {
        guard !hasAppliedTemplate(template, on: date) else { return }
        let day = Calendar.current.startOfDay(for: date)
        let items = template.items.map {
            TrainingItem(
                trickId: $0.trickId,
                trickName: $0.trickName,
                category: $0.category,
                difficulty: $0.difficulty,
                targetCount: $0.targetCount,
                completedCount: 0,
                templateId: template.id
            )
        }

        if let index = trainingPlans.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: day) }) {
            trainingPlans[index].items.append(contentsOf: items)
            trainingPlans[index].appliedTemplateIds.append(template.id)
        } else {
            trainingPlans.append(DailyTrainingPlan(date: day, items: items, appliedTemplateIds: [template.id]))
        }
        sortTrainingPlans()
    }

    func removeTemplateFromPlan(_ template: TrainingTemplate, on date: Date) {
        let day = Calendar.current.startOfDay(for: date)
        guard let planIndex = trainingPlans.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: day) }) else { return }
        trainingPlans[planIndex].items.removeAll { $0.templateId == template.id }
        trainingPlans[planIndex].appliedTemplateIds.removeAll { $0 == template.id }
        if trainingPlans[planIndex].items.isEmpty {
            trainingPlans.remove(at: planIndex)
        }
    }

    func appliedTemplates(on date: Date) -> [TrainingTemplate] {
        let day = Calendar.current.startOfDay(for: date)
        guard let plan = trainingPlans.first(where: { Calendar.current.isDate($0.date, inSameDayAs: day) }) else { return [] }
        let ids = Set(plan.appliedTemplateIds)
        return trainingTemplates.filter { ids.contains($0.id) }
    }

    func templateName(for id: UUID?) -> String {
        guard let id else { return "Manual" }
        return trainingTemplates.first(where: { $0.id == id })?.name ?? "Manual"
    }

    func trainingSummaryByDifficulty(on date: Date) -> [(Difficulty, Int)] {
        let items = trainingItems(on: date)
        return Difficulty.allCases.map { difficulty in
            (difficulty, items.filter { $0.difficulty == difficulty }.count)
        }.filter { $0.1 > 0 }
    }

    func trainingSummaryByCategory(on date: Date) -> [(String, Int)] {
        let items = trainingItems(on: date)
        let grouped = Dictionary(grouping: items, by: { $0.category })
        return grouped.keys.sorted().map { key in
            (key, grouped[key]?.count ?? 0)
        }.filter { $0.1 > 0 }
    }

    // MARK: - Sync

    @MainActor
    func syncFromServer() async {
        guard let token = authToken else { return }
        isSyncing = true
        syncError = nil
        pendingSyncErrorToken = nil
        do {
            let payload = try await APIClient.shared.fetchSync(token: token)
            isApplyingRemote = true
            applySyncPayload(payload)
            isApplyingRemote = false
            syncFailureCount = 0
        } catch {
            syncFailureCount += 1
            if syncFailureCount < 2 {
                scheduleSync()
            } else {
                let token = UUID()
                pendingSyncErrorToken = token
                let message = error.localizedDescription
                Task { [weak self] in
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    await MainActor.run {
                        guard let self else { return }
                        if self.pendingSyncErrorToken == token && !self.isSyncing && !self.isSyncQueued {
                            self.syncError = message
                        }
                    }
                }
                syncFailureCount = 0
            }
        }
        isSyncing = false
    }

    @MainActor
    func syncToServer() async {
        guard let token = authToken else { return }
        isSyncing = true
        isSyncQueued = false
        syncError = nil
        pendingSyncErrorToken = nil
        defer { isSyncing = false }
        let payload = makeSyncPayload()
        do {
            try await APIClient.shared.pushSync(token: token, payload: payload)
            syncError = nil
            syncFailureCount = 0
        } catch {
            syncFailureCount += 1
            if syncFailureCount < 2 {
                scheduleSync()
            } else {
                let token = UUID()
                pendingSyncErrorToken = token
                let message = error.localizedDescription
                Task { [weak self] in
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    await MainActor.run {
                        guard let self else { return }
                        if self.pendingSyncErrorToken == token && !self.isSyncing && !self.isSyncQueued {
                            self.syncError = message
                        }
                    }
                }
                syncFailureCount = 0
            }
        }
    }

    private func scheduleSync() {
        guard let _ = authToken else { return }
        guard !isApplyingRemote else { return }
        isSyncQueued = true
        syncError = nil
        pendingSyncErrorToken = nil
        syncTask?.cancel()
        syncTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 800_000_000)
            guard let self else { return }
            while await MainActor.run(resultType: Bool.self, body: { self.isSyncing }) {
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
            await self.syncToServer()
        }
    }

    private func makeSyncPayload() -> SyncPayload {
        SyncPayload(
            categories: categories,
            tricks: tricks,
            templates: trainingTemplates,
            challenges: challenges,
            trainingPlans: trainingPlans
        )
    }

    func exportSyncData() throws -> Data {
        let payload = makeSyncPayload()
        return try syncEncoder.encode(payload)
    }

    func importSyncData(_ data: Data) throws {
        let payload = try syncDecoder.decode(SyncPayload.self, from: data)
        isApplyingRemote = true
        applySyncPayload(payload)
        isApplyingRemote = false
        scheduleSync()
    }

    private func applySyncPayload(_ payload: SyncPayload) {
        categories = payload.categories.isEmpty ? categories : payload.categories
        if !categories.contains("Uncategorized") {
            categories.append("Uncategorized")
        }
        tricks = payload.tricks
        trainingTemplates = payload.templates
        challenges = payload.challenges
        trainingPlans = payload.trainingPlans
        sortTricks()
    }

    // MARK: - Persistence

    private func load() {
        let loadedTricks = loadJSON([Trick].self, from: tricksURL()) ?? []
        let loadedCategories = loadJSON([String].self, from: categoriesURL()) ?? []
        let loadedChallenges = loadJSON([Challenge].self, from: challengesURL()) ?? []
        let loadedTrainingPlans = loadJSON([DailyTrainingPlan].self, from: trainingPlansURL()) ?? []
        let loadedTemplates = loadJSON([TrainingTemplate].self, from: trainingTemplatesURL()) ?? []

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
        trainingPlans = loadedTrainingPlans
        trainingTemplates = loadedTemplates
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

    private func saveTrainingPlans() {
        saveJSON(trainingPlans, to: trainingPlansURL())
    }

    private func saveTrainingTemplates() {
        saveJSON(trainingTemplates, to: trainingTemplatesURL())
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

    private func trainingPlansURL() -> URL {
        documentsDirectory().appendingPathComponent("training_plans.json")
    }

    private func trainingTemplatesURL() -> URL {
        documentsDirectory().appendingPathComponent("training_templates.json")
    }

    private func sortTrainingPlans() {
        trainingPlans.sort { $0.date > $1.date }
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
