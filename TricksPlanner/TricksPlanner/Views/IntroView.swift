import SwiftUI

struct IntroView: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "skateboard")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundStyle(Theme.accent)
                    .padding(24)
                    .background(Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Theme.cardBorder, lineWidth: 1)
                    )

                VStack(spacing: 10) {
                    Text("Built for Lucas")
                        .font(Theme.titleFont(size: 28))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Made for excellence in skateboarding tricks planning.")
                        .font(Theme.bodyFont(size: 16))
                        .foregroundStyle(Theme.textSecondary)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

                Spacer()

                Button(action: onContinue) {
                    Text("Get Started")
                        .font(Theme.bodyFont(size: 16))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
            }
        }
    }
}

#Preview {
    IntroView(onContinue: {})
}
