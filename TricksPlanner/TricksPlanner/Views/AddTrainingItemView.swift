import SwiftUI

struct AddTrainingItemView: View {
    @EnvironmentObject private var store: TrickStore
    @Environment(\.dismiss) private var dismiss
    let date: Date
    let onDone: () -> Void

    @State private var selectedTrickId: UUID?
    @State private var targetCount = 5

    private var selectedTrick: Trick? {
        guard let id = selectedTrickId else { return nil }
        return store.tricks.first { $0.id == id }
    }

    var body: some View {
        Form {
            Section("Select Trick") {
                Picker("Trick", selection: $selectedTrickId) {
                    ForEach(store.tricks) { trick in
                        Text(trick.name).tag(Optional(trick.id))
                    }
                }
            }

            Section("Target Reps") {
                Stepper(value: $targetCount, in: 1...100, step: 1) {
                    Text("\(targetCount) reps")
                }
            }
        }
        .navigationTitle("Add Training")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Add") {
                    if let trick = selectedTrick {
                        store.addTrainingItem(trick: trick, target: targetCount, date: date)
                    }
                    onDone()
                    dismiss()
                }
                .disabled(selectedTrickId == nil)
            }
        }
    }
}

#Preview {
    NavigationStack {
        AddTrainingItemView(date: Date(), onDone: {})
            .environmentObject(TrickStore())
    }
}
