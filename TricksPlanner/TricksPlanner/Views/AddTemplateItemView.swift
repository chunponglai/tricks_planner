import SwiftUI

struct AddTemplateItemView: View {
    @EnvironmentObject private var store: TrickStore
    @Environment(\.dismiss) private var dismiss
    let onAdd: (TrainingTemplateItem) -> Void

    @State private var selectedTrickIds: Set<UUID> = []
    @State private var targetCount = 5
    @State private var searchText = ""
    @State private var selectedCategory: String = "All"

    private var categories: [String] {
        ["All"] + store.categories.sorted()
    }

    private var filteredTricks: [Trick] {
        store.tricks.filter { trick in
            let matchesCategory = selectedCategory == "All" || trick.category == selectedCategory
            let matchesSearch = searchText.isEmpty || trick.name.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        List {
            Section("Filter") {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
            }

            Section("Select Trick") {
                if filteredTricks.isEmpty {
                    ContentUnavailableView("No Tricks", systemImage: "magnifyingglass", description: Text("Try a different search or category."))
                } else {
                    ForEach(filteredTricks) { trick in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(trick.name)
                                    .font(Theme.bodyFont(size: 16))
                                    .foregroundStyle(Theme.textPrimary)
                                Text(trick.category)
                                    .font(Theme.bodyFont(size: 12))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                            if selectedTrickIds.contains(trick.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Theme.accent)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedTrickIds.contains(trick.id) {
                                selectedTrickIds.remove(trick.id)
                            } else {
                                selectedTrickIds.insert(trick.id)
                            }
                        }
                    }
                }
            }

            Section("Target Reps") {
                Stepper(value: $targetCount, in: 1...100, step: 1) {
                    Text("\(targetCount) reps")
                }
            }
        }
        .navigationTitle("Add Item")
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search tricks")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Add") {
                    let selected = store.tricks.filter { selectedTrickIds.contains($0.id) }
                    for trick in selected {
                        let item = TrainingTemplateItem(
                            trickId: trick.id,
                            trickName: trick.name,
                            category: trick.category,
                            difficulty: trick.difficulty,
                            targetCount: targetCount
                        )
                        onAdd(item)
                    }
                    dismiss()
                }
                .disabled(selectedTrickIds.isEmpty)
            }
        }
    }
}

#Preview {
    NavigationStack {
        AddTemplateItemView { _ in }
            .environmentObject(TrickStore())
    }
}
