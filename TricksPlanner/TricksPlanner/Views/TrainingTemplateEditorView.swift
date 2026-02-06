import SwiftUI

struct TrainingTemplateEditorView: View {
    @EnvironmentObject private var store: TrickStore
    @Environment(\.dismiss) private var dismiss
    @State private var template: TrainingTemplate
    @State private var showAddItem = false

    init(template: TrainingTemplate) {
        _template = State(initialValue: template)
    }

    var body: some View {
        List {
            Section("Template Name") {
                TextField("Name", text: $template.name)
            }

            Section("Items") {
                if template.items.isEmpty {
                    ContentUnavailableView("No Items", systemImage: "list.bullet")
                } else {
                    ForEach(template.items.indices, id: \.self) { index in
                        let item = template.items[index]
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Theme.difficultyColor(item.difficulty))
                                .frame(width: 8, height: 8)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.trickName)
                                    .font(Theme.bodyFont(size: 16))
                                    .foregroundStyle(Theme.textPrimary)
                                Text("\(item.targetCount) reps")
                                    .font(Theme.bodyFont(size: 12))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                            Button {
                                template.items[index].targetCount = max(1, template.items[index].targetCount - 1)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                            }
                            .buttonStyle(.plain)

                            Button {
                                template.items[index].targetCount += 1
                            } label: {
                                Image(systemName: "plus.circle.fill")
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 6)
                    }
                    .onDelete { offsets in
                        template.items.remove(atOffsets: offsets)
                    }
                }
            }
        }
        .navigationTitle("Template")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add Item") { showAddItem = true }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    store.updateTemplate(template)
                    dismiss()
                }
                .disabled(template.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .sheet(isPresented: $showAddItem) {
            NavigationStack {
                AddTemplateItemView { newItem in
                    template.items.append(newItem)
                    showAddItem = false
                }
                .environmentObject(store)
            }
        }
    }
}

#Preview {
    NavigationStack {
        TrainingTemplateEditorView(template: TrainingTemplate(name: "Daily Warmup"))
            .environmentObject(TrickStore())
    }
}
