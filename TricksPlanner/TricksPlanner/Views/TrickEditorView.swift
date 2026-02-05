import SwiftUI

struct TrickEditorView: View {
    enum Mode: Identifiable {
        case add
        case edit(Trick)

        var id: String {
            switch self {
            case .add: return "add"
            case .edit(let trick): return trick.id.uuidString
            }
        }
    }

    @EnvironmentObject private var store: TrickStore
    @Environment(\.dismiss) private var dismiss

    let mode: Mode

    @State private var name: String = ""
    @State private var category: String = "Uncategorized"
    @State private var newCategory: String = ""
    @State private var difficulty: Difficulty = .none

    var body: some View {
        Form {
            Section("Trick") {
                TextField("Name", text: $name)
            }

            Section("Category") {
                Picker("Category", selection: $category) {
                    ForEach(store.categories, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }

                TextField("Or add new category", text: $newCategory)
            }

            Section("Difficulty") {
                Picker("Difficulty", selection: $difficulty) {
                    ForEach(Difficulty.allCases) { option in
                        Text(option.rawValue.capitalized).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .navigationTitle(title)
        .scrollContentBackground(.hidden)
        .background(Theme.background.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onAppear(perform: loadIfNeeded)
    }

    private var title: String {
        switch mode {
        case .add: return "Add Trick"
        case .edit: return "Edit Trick"
        }
    }

    private func loadIfNeeded() {
        guard case let .edit(trick) = mode else { return }
        name = trick.name
        category = trick.category
        difficulty = trick.difficulty
    }

    private func save() {
        let finalCategory = newCategory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? category
            : newCategory

        switch mode {
        case .add:
            store.addTrick(name: name, category: finalCategory, difficulty: difficulty)
        case .edit(let trick):
            store.updateTrick(trick, name: name, category: finalCategory, difficulty: difficulty)
        }

        dismiss()
    }
}

#Preview {
    NavigationStack {
        TrickEditorView(mode: .add)
            .environmentObject(TrickStore())
    }
}
