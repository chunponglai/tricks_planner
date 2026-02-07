import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var store: TrickStore
    @State private var monthOffset = 0
    @State private var selectedDay: SelectedDay?
    @State private var summaryDate: Date = Date()
    @State private var showItemComplete = false
    @State private var completedItemName = ""
    @State private var showDayComplete = false
    @State private var burstTrigger = false

    private var calendar: Calendar { Calendar.current }

    private struct SelectedDay: Identifiable {
        let id = UUID()
        let date: Date
    }

    private struct WeekdayLabel: Identifiable {
        let id: Int
        let text: String
    }

    private let weekdayLabels: [WeekdayLabel] = [
        WeekdayLabel(id: 0, text: "S"),
        WeekdayLabel(id: 1, text: "M"),
        WeekdayLabel(id: 2, text: "T"),
        WeekdayLabel(id: 3, text: "W"),
        WeekdayLabel(id: 4, text: "T"),
        WeekdayLabel(id: 5, text: "F"),
        WeekdayLabel(id: 6, text: "S")
    ]

    private var monthDate: Date {
        calendar.date(byAdding: .month, value: monthOffset, to: Date()) ?? Date()
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: monthDate)
    }

    private var daysInGrid: [Date?] {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate)) ?? monthDate
        let weekday = calendar.component(.weekday, from: startOfMonth)
        let leadingEmpty = (weekday - calendar.firstWeekday + 7) % 7
        let range = calendar.range(of: .day, in: .month, for: startOfMonth) ?? 1..<1
        var days: [Date?] = Array(repeating: nil, count: leadingEmpty)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        while days.count % 7 != 0 {
            days.append(nil)
        }
        return days
    }

    private func challengeCount(for date: Date) -> Int {
        store.challenges(on: date).count
    }

    private func trainingDotColor(for date: Date) -> Color? {
        let completion = store.trainingCompletion(for: date)
        guard completion.target > 0 else { return nil }
        return Theme.trainingStatusColor(completed: completion.completed, target: completion.target)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Calendar")
                            .font(Theme.titleFont(size: 26))
                            .foregroundStyle(Theme.textPrimary)
                        Text("Track challenges and success rate.")
                            .font(Theme.bodyFont(size: 14))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 8) {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Challenges Success Rate")
                                .font(Theme.bodyFont(size: 12))
                                .foregroundStyle(Theme.textSecondary)
                            Text("\(Int(store.successRate() * 100))%")
                                .font(Theme.titleFont(size: 18))
                                .foregroundStyle(Theme.textPrimary)
                        }

                        let training = store.trainingCompletion(for: summaryDate)
                        let trainingRate = training.target == 0 ? 0 : Int((Double(training.completed) / Double(training.target)) * 100)
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Training Finish Rate")
                                .font(Theme.bodyFont(size: 12))
                                .foregroundStyle(Theme.textSecondary)
                            Text("\(trainingRate)%")
                                .font(Theme.titleFont(size: 18))
                                .foregroundStyle(Theme.textPrimary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                VStack(spacing: 12) {
                    HStack {
                        Button {
                            monthOffset -= 1
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                        .buttonStyle(.plain)

                        Spacer()
                        Text(monthTitle)
                            .font(Theme.titleFont(size: 18))
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()

                        Button {
                            monthOffset += 1
                        } label: {
                            Image(systemName: "chevron.right")
                        }
                        .buttonStyle(.plain)
                    }

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                        ForEach(weekdayLabels) { label in
                            Text(label.text)
                                .font(Theme.bodyFont(size: 12))
                                .foregroundStyle(Theme.textSecondary)
                        }

                        ForEach(daysInGrid.indices, id: \.self) { index in
                            let day = daysInGrid[index]
                            if let date = day {
                                let isToday = calendar.isDateInToday(date)
                                let count = challengeCount(for: date)
                                Button {
                                    summaryDate = date
                                    selectedDay = SelectedDay(date: date)
                                } label: {
                                    VStack(spacing: 4) {
                                        Text("\(calendar.component(.day, from: date))")
                                            .font(Theme.bodyFont(size: 14))
                                            .foregroundStyle(Theme.textPrimary)
                                            .frame(maxWidth: .infinity)

                                    HStack(spacing: 3) {
                                        ForEach(0..<min(count, 2), id: \.self) { _ in
                                            Circle()
                                                .fill(Theme.accent)
                                                .frame(width: 5, height: 5)
                                        }
                                        if let trainingColor = trainingDotColor(for: date) {
                                            Circle()
                                                .fill(trainingColor)
                                                .frame(width: 5, height: 5)
                                        }
                                        if count > 2 {
                                            Text("+")
                                                .font(.system(size: 10, weight: .semibold))
                                                .foregroundStyle(Theme.textSecondary)
                                        }
                                    }
                                        .frame(height: 6)
                                    }
                                    .padding(.vertical, 6)
                                    .background(isToday ? Theme.accent.opacity(0.12) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                            } else {
                                Color.clear
                                    .frame(height: 34)
                            }
                        }
                    }
                }
                .padding(16)
                .background(Theme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Theme.cardBorder, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 16)

                // Today's plan + summary
                VStack(alignment: .leading, spacing: 12) {
                    let dateLabel = DateFormatter.localizedString(from: summaryDate, dateStyle: .medium, timeStyle: .none)
                    Text(dateLabel)
                        .font(Theme.titleFont(size: 18))
                        .foregroundStyle(Theme.textPrimary)

                    let completion = store.trainingCompletion(for: summaryDate)
                    HStack {
                        Text("Training Progress")
                            .font(Theme.bodyFont(size: 14))
                        Spacer()
                        Text("\(completion.completed)/\(completion.target)")
                            .font(Theme.bodyFont(size: 12))
                            .foregroundStyle(Theme.textSecondary)
                    }

                    if completion.target > 0 {
                        ProgressView(value: Double(completion.completed), total: Double(completion.target))
                            .tint(Theme.accent)
                    }

                    let byDifficulty = store.trainingSummaryByDifficulty(on: summaryDate)
                    if !byDifficulty.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("By Difficulty")
                                .font(Theme.bodyFont(size: 12))
                                .foregroundStyle(Theme.textSecondary)
                            ForEach(byDifficulty, id: \.0) { item in
                                HStack {
                                    Text(item.0.rawValue.capitalized)
                                    Spacer()
                                    Text("\(item.1)")
                                        .foregroundStyle(Theme.textSecondary)
                                }
                            }
                        }
                    }

                    let byCategory = store.trainingSummaryByCategory(on: summaryDate)
                    if !byCategory.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("By Category")
                                .font(Theme.bodyFont(size: 12))
                                .foregroundStyle(Theme.textSecondary)
                            ForEach(byCategory, id: \.0) { item in
                                HStack {
                                    Text(item.0)
                                    Spacer()
                                    Text("\(item.1)")
                                        .foregroundStyle(Theme.textSecondary)
                                }
                            }
                        }
                    }

                    let items = store.trainingItems(on: summaryDate)
                    if items.isEmpty {
                        Text("No training items today.")
                            .font(Theme.bodyFont(size: 13))
                            .foregroundStyle(Theme.textSecondary)
                    } else {
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
                                       let _ = store.trainingTemplates.first(where: { $0.id == templateId }) {
                                        Text("Template")
                                            .font(Theme.bodyFont(size: 12))
                                            .foregroundStyle(Theme.textSecondary)
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
                                            store.incrementTrainingItem(item, date: summaryDate, delta: -1)
                                        } label: {
                                            Image(systemName: "minus")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundStyle(Theme.textPrimary)
                                                .frame(width: 28, height: 28)
                                                .background(Theme.card)
                                                .overlay(
                                                    Circle().stroke(Theme.cardBorder, lineWidth: 1)
                                                )
                                                .clipShape(Circle())
                                        }
                                        .buttonStyle(.plain)

                                        Button {
                                            let before = item.completedCount
                                            store.incrementTrainingItem(item, date: summaryDate, delta: 1)
                                            let after = min(before + 1, item.targetCount)

                                            if after == item.targetCount {
                                                completedItemName = item.trickName
                                                showItemComplete = true
                                                burstTrigger.toggle()
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
                                                    showItemComplete = false
                                                }
                                            }

                                            let completion = store.trainingCompletion(for: summaryDate)
                                            if completion.target > 0 && completion.completed >= completion.target {
                                                showDayComplete = true
                                                burstTrigger.toggle()
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                                                    showDayComplete = false
                                                }
                                            }
                                        } label: {
                                            Image(systemName: "plus")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundStyle(.white)
                                                .frame(width: 28, height: 28)
                                                .background(Theme.accent)
                                                .clipShape(Circle())
                                                .shadow(color: Theme.accent.opacity(0.25), radius: 6, x: 0, y: 2)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    HStack {
                        Button("Open Day") {
                            selectedDay = SelectedDay(date: summaryDate)
                        }
                        .font(Theme.bodyFont(size: 14))
                        .foregroundStyle(Theme.accent)

                        Spacer()

                        Button("Today") {
                            summaryDate = Date()
                        }
                        .font(Theme.bodyFont(size: 14))
                        .foregroundStyle(Theme.textSecondary)
                    }
                }
                .padding(16)
                .background(Theme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Theme.cardBorder, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 16)

                Spacer(minLength: 12)
            }
        }
        .navigationTitle("Calendar")
        .scrollContentBackground(.hidden)
        .background(Theme.background.ignoresSafeArea())
        .refreshable {
            await store.syncFromServer()
        }
        .overlay {
            ZStack {
                if showItemComplete {
                    CelebrationOverlay(
                        title: "Nice!",
                        subtitle: "\(completedItemName) complete",
                        icon: "checkmark.seal.fill",
                        accent: Theme.accent,
                        burstTrigger: burstTrigger
                    )
                }

                if showDayComplete {
                    CelebrationOverlay(
                        title: "Day Complete!",
                        subtitle: "You crushed today's training",
                        icon: "sparkles",
                        accent: Theme.accentSecondary,
                        burstTrigger: burstTrigger
                    )
                }
            }
        }
        .onAppear {
            summaryDate = Date()
        }
        .sheet(item: $selectedDay) { item in
            DayChallengesView(date: item.date)
                .environmentObject(store)
        }
    }
}

#Preview {
    NavigationStack {
        CalendarView()
            .environmentObject(TrickStore())
    }
}

private struct CelebrationOverlay: View {
    let title: String
    let subtitle: String
    let icon: String
    let accent: Color
    let burstTrigger: Bool

    @State private var animate = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            ZStack {
                ForEach(0..<10, id: \.self) { index in
                    Circle()
                        .fill(accent.opacity(0.4))
                        .frame(width: animate ? 14 : 6, height: animate ? 14 : 6)
                        .offset(x: animate ? offset(for: index).0 : 0,
                                y: animate ? offset(for: index).1 : 0)
                        .opacity(animate ? 0 : 1)
                        .animation(.easeOut(duration: 0.9).delay(Double(index) * 0.02), value: animate)
                }

                VStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 54, weight: .bold))
                        .foregroundStyle(accent)
                        .scaleEffect(animate ? 1.1 : 0.8)
                        .animation(.spring(response: 0.45, dampingFraction: 0.6), value: animate)
                    Text(title)
                        .font(Theme.titleFont(size: 26))
                        .foregroundStyle(Theme.textPrimary)
                    Text(subtitle)
                        .font(Theme.bodyFont(size: 14))
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(30)
                .background(Theme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Theme.cardBorder, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .scaleEffect(animate ? 1.0 : 0.7)
                .opacity(animate ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: animate)
            }
        }
        .onAppear { animate = true }
    }

    private func offset(for index: Int) -> (CGFloat, CGFloat) {
        let angle = Double(index) / 10.0 * (Double.pi * 2)
        let radius: CGFloat = 120
        return (CGFloat(cos(angle)) * radius, CGFloat(sin(angle)) * radius)
    }
}
