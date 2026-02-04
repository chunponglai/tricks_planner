import SwiftUI

struct ComboResultsScreen: View {
    let combo: [Trick]
    @EnvironmentObject private var store: TrickStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            if combo.isEmpty {
                ContentUnavailableView("No Combo Yet", systemImage: "shuffle", description: Text("Pick some categories and generate a combo."))
            } else {
                Section {
                    Button("Accept Challenge") {
                        store.addChallenge(combo: combo, date: Date())
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)
                }

                Section("Your Combo") {
                    ComboResultView(combo: combo)
                }
            }
        }
        .navigationTitle("Combo Result")
        .scrollContentBackground(.hidden)
        .background(Theme.background.ignoresSafeArea())
    }
}

#Preview {
    NavigationStack {
        ComboResultsScreen(combo: SampleData.tricks)
    }
}
