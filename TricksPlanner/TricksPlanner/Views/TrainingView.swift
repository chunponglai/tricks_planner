import SwiftUI

struct TrainingView: View {
    @EnvironmentObject private var store: TrickStore
    @State private var showNewTemplatePrompt = false
    @State private var newTemplateName = ""
    @State private var editingTemplate: EditingTemplate?
    private var today: Date { Date() }

    private struct EditingTemplate: Identifiable {
        let id = UUID()
        let template: TrainingTemplate
    }

    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Templates")
                            .font(Theme.titleFont(size: 26))
                            .foregroundStyle(Theme.textPrimary)
                        Text("Create reusable training plans.")
                            .font(Theme.bodyFont(size: 14))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 6)
                .listRowBackground(Color.clear)
            }

            Section {
                if store.trainingTemplates.isEmpty {
                    ContentUnavailableView("No Templates", systemImage: "square.stack.3d.down.right", description: Text("Create a template to reuse daily plans."))
                } else {
                    ForEach(store.trainingTemplates) { template in
                        let applied = store.hasAppliedTemplate(template, on: today)
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(template.name)
                                    .font(Theme.bodyFont(size: 16))
                                    .foregroundStyle(Theme.textPrimary)
                                Text("\(template.items.count) items")
                                    .font(Theme.bodyFont(size: 12))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                            Button("Apply") {
                                store.applyTemplate(template, to: today)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .disabled(applied)

                            Button("Edit") {
                                editingTemplate = EditingTemplate(template: template)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)

                            if applied {
                                Button("Remove") {
                                    store.removeTemplateFromPlan(template, on: today)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .tint(.red)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .onDelete { offsets in
                        let templates = store.trainingTemplates
                        let ids = offsets.map { templates[$0].id }
                        for id in ids {
                            if let template = templates.first(where: { $0.id == id }) {
                                store.deleteTemplate(template)
                            }
                        }
                    }
                }
            }
            header: {
                HStack {
                    Text("Templates")
                    Spacer()
                    Button("Add Template") {
                        showNewTemplatePrompt = true
                    }
                    .font(Theme.bodyFont(size: 12))
                }
            }

        }
        .navigationTitle("Templates")
        .scrollContentBackground(.hidden)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showNewTemplatePrompt = true
                } label: {
                    Image(systemName: "square.stack.3d.up.badge.plus")
                }
            }
        }
        .sheet(item: $editingTemplate) { wrapper in
            NavigationStack {
                TrainingTemplateEditorView(template: wrapper.template)
                    .environmentObject(store)
            }
        }
        .alert("New Template", isPresented: $showNewTemplatePrompt) {
            TextField("Template name", text: $newTemplateName)
            Button("Create") {
                let name = newTemplateName.trimmingCharacters(in: .whitespacesAndNewlines)
                if let template = store.addTemplate(name: name.isEmpty ? "New Template" : name) {
                    editingTemplate = EditingTemplate(template: template)
                }
                newTemplateName = ""
            }
            Button("Cancel", role: .cancel) {
                newTemplateName = ""
            }
        }
    }
}

#Preview {
    NavigationStack {
        TrainingView()
            .environmentObject(TrickStore())
    }
}
