import SwiftUI

struct ContentView: View {
    @AppStorage("colorSchemeOverride") private var colorSchemeOverride = 0
    @Environment(\.scenePhase) private var scenePhase
    @State private var showIntro = true

    private var preferredScheme: ColorScheme? {
        switch colorSchemeOverride {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }

    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()

            TabView {
                NavigationStack {
                    TrickListView()
                }
                .tabItem {
                    Label("Tricks", systemImage: "list.bullet")
                }

                NavigationStack {
                    ComboGeneratorView()
                }
                .tabItem {
                    Label("Combo", systemImage: "shuffle")
                }
            }
            .tint(Theme.accent)

            Menu {
                Picker("Appearance", selection: $colorSchemeOverride) {
                    Text("System").tag(0)
                    Text("Light").tag(1)
                    Text("Dark").tag(2)
                }
            } label: {
                Image(systemName: "circle.lefthalf.filled")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(10)
                    .background(Theme.card)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Theme.cardBorder, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
            }
            .padding(.trailing, 16)
            .padding(.bottom, 18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .preferredColorScheme(preferredScheme)
        .fullScreenCover(isPresented: $showIntro) {
            IntroView {
                showIntro = false
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                showIntro = true
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(TrickStore())
}
