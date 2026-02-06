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
                Section {
                    let items = store.trainingItems(on: date)
                    let completion = store.trainingCompletion(for: date)
                    if items.isEmpty {
                        Text("No training items for this day.")
                            .font(Theme.bodyFont(size: 13))
                            .foregroundStyle(Theme.textSecondary)
                    } else {
                        HStack {
                            Text("Progress")
                            Spacer()
                            Text("\(completion.completed)/\(completion.target)")
                                .foregroundStyle(Theme.textSecondary)
                        }
                        ProgressView(value: Double(completion.completed), total: Double(max(completion.target, 1)))
                            .tint(Theme.accent)

                        let grouped = Dictionary(grouping: items, by: { $0.templateId })
                        ForEach(grouped.keys.sorted { store.templateName(for: $0) < store.templateName(for: $1) }, id: \.self) { key in
                            let groupItems = grouped[key] ?? []
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(store.templateName(for: key))
                                        .font(Theme.bodyFont(size: 13))
                                        .foregroundStyle(Theme.textSecondary)
                                    Spacer()
                                    if let templateId = key,
                                       let template = store.trainingTemplates.first(where: { $0.id == templateId }) {
                                        Button("Remove Template") {
                                            store.removeTemplateFromPlan(template, on: date)
                                        }
                                        .font(Theme.bodyFont(size: 12))
                                        .foregroundStyle(.red)
                                    }
                                }

                                ForEach(groupItems) { item in
                                    HStack(spacing: 12) {
                                        Circle()
                                            .fill(Theme.difficultyColor(item.difficulty))
                                            .frame(width: 8, height: 8)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.trickName)
                                                .font(Theme.bodyFont(size: 14))
                                                .foregroundStyle(Theme.textPrimary)
                                            Text("\(item.completedCount)/\(item.targetCount) reps")
                                                .font(Theme.bodyFont(size: 12))
                                                .foregroundStyle(Theme.textSecondary)
                                        }
                                        Spacer()
                                        Button {
                                            store.incrementTrainingItem(item, date: date, delta: -1)
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                        }
                                        .buttonStyle(.plain)
                                        Button {
                                            store.incrementTrainingItem(item, date: date, delta: 1)
                                        } label: {
                                            Image(systemName: "plus.circle.fill")
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.vertical, 6)
                                }
                            }
                            .padding(.vertical, 4)
                        }

                        Button("Remove All Training For This Day") {
                            store.clearTraining(on: date)
                        }
                        .foregroundStyle(.red)
                    }
                } header: {
                    HStack {
                        Text("Training")
                        Spacer()
                    }
                }

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

                            Button("Delete Challenge") {
                                store.deleteChallenge(challenge)
                            }
                            .foregroundStyle(.red)
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
