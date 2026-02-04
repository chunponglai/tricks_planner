import SwiftUI

struct ComboResultsScreen: View {
    let combo: [Trick]

    var body: some View {
        List {
            if combo.isEmpty {
                ContentUnavailableView("No Combo Yet", systemImage: "shuffle", description: Text("Pick some categories and generate a combo."))
            } else {
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
