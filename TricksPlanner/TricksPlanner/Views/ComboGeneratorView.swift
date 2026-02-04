import SwiftUI

struct ComboGeneratorView: View {
    @EnvironmentObject private var store: TrickStore
    @State private var selections: [String: Int] = [:]
    @State private var combo: [Trick] = []
    @State private var showCombo = false

    private var categoriesWithTricks: [String] {
        let categories = Set(store.tricks.map { $0.category })
        return store.categories.filter { categories.contains($0) }
    }

    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Combo Builder")
                            .font(Theme.titleFont(size: 26))
                            .foregroundStyle(Theme.textPrimary)
                        Text("Pick categories and generate a practice line.")
                            .font(Theme.bodyFont(size: 14))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "dice")
                        .foregroundStyle(Theme.accentSecondary)
                }
                .padding(.vertical, 6)
                .listRowBackground(Color.clear)
            }

            Section("Pick Categories") {
                if categoriesWithTricks.isEmpty {
                    ContentUnavailableView("No Categories", systemImage: "tag", description: Text("Add some tricks first."))
                } else {
                    ForEach(categoriesWithTricks, id: \.self) { category in
                        let maxCount = max(store.tricks.filter { $0.category == category }.count, 1)
                        Stepper(value: Binding(
                            get: { selections[category, default: 0] },
                            set: { selections[category] = min($0, maxCount) }
                        ), in: 0...maxCount, step: 1) {
                            HStack {
                                Text(category)
                                Spacer()
                                Text("\(selections[category, default: 0])")
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                    }
                }
            }

            Section {
                Button("Reset") {
                    selections = [:]
                    combo = []
                }
                .foregroundStyle(Theme.textSecondary)

                Button("Generate Combo") {
                    combo = store.randomCombo(from: selections)
                    showCombo = true
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
                .disabled(store.tricks.isEmpty)
            }
        }
        .navigationTitle("Combo")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Reset") {
                    selections = [:]
                    combo = []
                }
            }
        }
        .scrollContentBackground(.hidden)
        .navigationDestination(isPresented: $showCombo) {
            ComboResultsScreen(combo: combo)
        }
    }
}

#Preview {
    NavigationStack {
        ComboGeneratorView()
            .environmentObject(TrickStore())
    }
}
