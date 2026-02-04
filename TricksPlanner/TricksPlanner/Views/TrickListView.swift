import SwiftUI

struct TrickListView: View {
    @EnvironmentObject private var store: TrickStore
    @State private var showAdd = false
    @State private var editTrick: Trick?

    private var grouped: [(key: String, value: [Trick])] {
        let groups = Dictionary(grouping: store.tricks, by: { $0.category })
        return groups.keys.sorted().map { key in
            (key, groups[key] ?? [])
        }
    }

    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Your Tricks")
                            .font(Theme.titleFont(size: 26))
                            .foregroundStyle(Theme.textPrimary)
                        Text("Tap a trick to edit. Swipe left to delete.")
                            .font(Theme.bodyFont(size: 14))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "sparkles")
                        .foregroundStyle(Theme.accent)
                }
                .padding(.vertical, 6)
                .listRowBackground(Color.clear)
            }

            if store.tricks.isEmpty {
                ContentUnavailableView("No Tricks Yet", systemImage: "skateboard", description: Text("Add a trick to get started."))
            } else {
                ForEach(grouped, id: \.key) { group in
                    Section {
                        Text(group.key.uppercased())
                            .font(Theme.bodyFont(size: 12))
                            .foregroundStyle(Theme.textSecondary)
                            .listRowBackground(Color.clear)

                        ForEach(group.value) { trick in
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Theme.difficultyColor(trick.difficulty))
                                    .frame(width: 8, height: 8)
                                Text(trick.name)
                                    .font(Theme.bodyFont(size: 16))
                                    .foregroundStyle(Theme.textPrimary)
                                Spacer()
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 14)
                            .background(Theme.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Theme.cardBorder, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .contentShape(Rectangle())
                            .onTapGesture { editTrick = trick }
                            .listRowBackground(Color.clear)
                        }
                        .onDelete { offsets in
                            delete(at: offsets, in: group.key)
                        }
                    }
                    .textCase(nil)
                }
            }
        }
        .navigationTitle("Tricks")
        .scrollContentBackground(.hidden)
        .listSectionSpacing(.compact)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            NavigationStack {
                TrickEditorView(mode: .add)
            }
        }
        .sheet(item: $editTrick) { trick in
            NavigationStack {
                TrickEditorView(mode: .edit(trick))
            }
        }
    }

    private func delete(at offsets: IndexSet, in category: String) {
        let tricksInCategory = store.tricks.filter { $0.category == category }
        let idsToDelete = offsets.map { tricksInCategory[$0].id }
        let globalOffsets = IndexSet(store.tricks.enumerated().compactMap { index, trick in
            idsToDelete.contains(trick.id) ? index : nil
        })
        store.deleteTricks(at: globalOffsets)
    }
}

#Preview {
    NavigationStack {
        TrickListView()
            .environmentObject(TrickStore())
    }
}
