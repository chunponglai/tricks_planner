import SwiftUI

struct CategoryManagerView: View {
    @EnvironmentObject private var store: TrickStore
    @Environment(\.dismiss) private var dismiss
    @State private var newCategory = ""
    @State private var editingCategory: EditingCategory?
    @State private var editName = ""

    private struct EditingCategory: Identifiable {
        let id = UUID()
        let name: String
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Add Category") {
                    HStack {
                        TextField("New category", text: $newCategory)
                        Button("Add") {
                            store.addCategory(newCategory)
                            newCategory = ""
                        }
                        .disabled(newCategory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

                Section("Categories") {
                    if store.categories.isEmpty {
                        ContentUnavailableView("No Categories", systemImage: "tag")
                    } else {
                        ForEach(store.categories, id: \.self) { category in
                            HStack {
                                Text(category)
                                Spacer()
                                Button("Edit") {
                                    editingCategory = EditingCategory(name: category)
                                    editName = category
                                }
                                .font(.system(size: 14, weight: .semibold))
                            }
                        }
                        .onDelete { offsets in
                            let names = offsets.map { store.categories[$0] }
                            for name in names {
                                store.deleteCategory(name)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Manage Categories")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .sheet(item: $editingCategory) { item in
                NavigationStack {
                    Form {
                        TextField("Category name", text: $editName)
                    }
                    .navigationTitle("Edit Category")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { editingCategory = nil }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                store.renameCategory(from: item.name, to: editName)
                                editingCategory = nil
                            }
                            .disabled(editName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    CategoryManagerView()
        .environmentObject(TrickStore())
}
