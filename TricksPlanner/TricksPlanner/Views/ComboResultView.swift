import SwiftUI

struct ComboResultView: View {
    let combo: [Trick]

    var body: some View {
        ForEach(combo) { trick in
            HStack {
                Text(trick.name)
                    .font(Theme.bodyFont(size: 16))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text(trick.category)
                    .font(Theme.bodyFont(size: 12))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(Theme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Theme.cardBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .listRowBackground(Color.clear)
        }
    }
}

#Preview {
    List {
        ComboResultView(combo: SampleData.tricks)
    }
}
