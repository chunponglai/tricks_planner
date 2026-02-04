import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var store: TrickStore
    @State private var monthOffset = 0
    @State private var selectedDay: SelectedDay?

    private var calendar: Calendar { Calendar.current }

    private struct SelectedDay: Identifiable {
        let id = UUID()
        let date: Date
    }

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
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Success Rate")
                            .font(Theme.bodyFont(size: 12))
                            .foregroundStyle(Theme.textSecondary)
                        Text("\(Int(store.successRate() * 100))%")
                            .font(Theme.titleFont(size: 20))
                            .foregroundStyle(Theme.textPrimary)
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
                        ForEach(["S","M","T","W","T","F","S"], id: \.self) { label in
                            Text(label)
                                .font(Theme.bodyFont(size: 12))
                                .foregroundStyle(Theme.textSecondary)
                        }

                        ForEach(daysInGrid.indices, id: \.self) { index in
                            let day = daysInGrid[index]
                            if let date = day {
                                let isToday = calendar.isDateInToday(date)
                                let count = challengeCount(for: date)
                                Button {
                                    selectedDay = SelectedDay(date: date)
                                } label: {
                                    VStack(spacing: 4) {
                                        Text("\(calendar.component(.day, from: date))")
                                            .font(Theme.bodyFont(size: 14))
                                            .foregroundStyle(Theme.textPrimary)
                                            .frame(maxWidth: .infinity)

                                        HStack(spacing: 3) {
                                            ForEach(0..<min(count, 3), id: \.self) { _ in
                                                Circle()
                                                    .fill(Theme.accent)
                                                    .frame(width: 5, height: 5)
                                            }
                                            if count > 3 {
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

                Spacer(minLength: 12)
            }
        }
        .navigationTitle("Calendar")
        .scrollContentBackground(.hidden)
        .background(Theme.background.ignoresSafeArea())
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
