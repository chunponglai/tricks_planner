import SwiftUI

struct DayChallengesView: View {
    @EnvironmentObject private var store: TrickStore
    @Environment(\.dismiss) private var dismiss
    let date: Date

    private var dateTitle: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    var body: some View {
        NavigationStack {
            List {
                let dayChallenges = store.challenges(on: date)
                if dayChallenges.isEmpty {
                    ContentUnavailableView("No Challenges", systemImage: "calendar", description: Text("No challenges recorded for this day."))
                } else {
                    ForEach(dayChallenges) { challenge in
                        Section {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Challenge")
                                        .font(Theme.bodyFont(size: 12))
                                        .foregroundStyle(Theme.textSecondary)
                                    Text("\(challenge.combo.count) tricks")
                                        .font(Theme.bodyFont(size: 14))
                                        .foregroundStyle(Theme.textPrimary)
                                }
                                Spacer()
                                Menu {
                                    ForEach(ChallengeStatus.allCases) { option in
                                        Button(option.displayName) {
                                            store.updateChallengeStatus(challenge, status: option)
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(Theme.statusColor(challenge.status))
                                            .frame(width: 8, height: 8)
                                        Text(challenge.status.displayName)
                                            .font(Theme.bodyFont(size: 14))
                                            .foregroundStyle(Theme.textPrimary)
                                    }
                                }
                            }

                            ComboResultView(combo: challenge.combo)

                            Button("Re-challenge Today") {
                                store.addChallenge(combo: challenge.combo, date: Date())
                            }
                            .foregroundStyle(Theme.accent)
                        }
                    }
                    .onDelete { offsets in
                        store.deleteChallenges(at: offsets, on: date)
                    }
                }
            }
            .navigationTitle(dateTitle)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
        }
    }
}

#Preview {
    DayChallengesView(date: Date())
        .environmentObject(TrickStore())
}
