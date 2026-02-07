import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var store: TrickStore
    @AppStorage("colorSchemeOverride") private var colorSchemeOverride = 0
    @Environment(\.scenePhase) private var scenePhase
    @State private var showIntro = true
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var exportDocument: SyncPayloadDocument?
    @State private var importError: String?
    @State private var importErrorTitle = "Import Failed"
    @State private var pendingImportData: Data?
    @State private var showImportConfirm = false

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

            if session.token == nil {
                AuthView()
            } else {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        let isSyncing = store.isSyncing || store.isSyncQueued
                        Circle()
                            .fill(isSyncing ? Color.orange : (store.syncError == nil ? Color.green : Color.red))
                            .frame(width: 6, height: 6)
                        Text(isSyncing ? "Syncing..." : (store.syncError == nil ? "Synced" : "Sync Error"))
                            .font(Theme.bodyFont(size: 11))
                            .foregroundStyle(Theme.textSecondary)
                        Spacer()
                        Button("Logout") {
                            session.logout()
                        }
                        .font(Theme.bodyFont(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme.cardBorder, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 12)
                    .padding(.top, 6)

                    TabView {
                        NavigationStack {
                            CalendarView()
                        }
                        .tabItem {
                            Label("Calendar", systemImage: "calendar")
                        }

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

                        NavigationStack {
                            TrainingView()
                        }
                        .tabItem {
                            Label("Templates", systemImage: "square.stack")
                        }
                    }
                    .tint(Theme.accent)
                }
            }

            Menu {
                Picker("Appearance", selection: $colorSchemeOverride) {
                    Text("System").tag(0)
                    Text("Light").tag(1)
                    Text("Dark").tag(2)
                }

                if session.token != nil {
                    Button("Import Data") {
                        showImporter = true
                    }
                    Button("Export Data") {
                        do {
                            let data = try store.exportSyncData()
                            exportDocument = SyncPayloadDocument(data: data)
                            showExporter = true
                        } catch {
                            importError = error.localizedDescription
                            importErrorTitle = "Export Failed"
                            showImportConfirm = true
                        }
                    }
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
        .fileExporter(
            isPresented: $showExporter,
            document: exportDocument,
            contentType: .json,
            defaultFilename: "tricksplanner-backup"
        ) { result in
            if case .failure(let error) = result {
                importError = error.localizedDescription
                importErrorTitle = "Export Failed"
                showImportConfirm = true
            }
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.json]
        ) { result in
            switch result {
            case .success(let url):
                do {
                    let didAccess = url.startAccessingSecurityScopedResource()
                    defer {
                        if didAccess { url.stopAccessingSecurityScopedResource() }
                    }
                    let data = try Data(contentsOf: url)
                    pendingImportData = data
                    showImportConfirm = true
                } catch {
                    importError = error.localizedDescription
                    importErrorTitle = "Import Failed"
                    showImportConfirm = true
                }
            case .failure(let error):
                importError = error.localizedDescription
                importErrorTitle = "Import Failed"
                showImportConfirm = true
            }
        }
        .alert(pendingImportData == nil ? importErrorTitle : "Import Data", isPresented: $showImportConfirm) {
            if let data = pendingImportData {
                Button("Replace Current Data", role: .destructive) {
                    do {
                        try store.importSyncData(data)
                        importError = nil
                    } catch {
                        importError = error.localizedDescription
                    }
                    pendingImportData = nil
                }
                Button("Cancel", role: .cancel) {
                    pendingImportData = nil
                }
            } else {
                Button("OK", role: .cancel) { }
            }
        } message: {
            if pendingImportData != nil {
                Text("This will replace the current on-device data with the imported backup.")
            } else {
                Text(importError ?? "Export failed.")
            }
        }
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
        .task {
            store.updateAuthToken(session.token)
            if session.token != nil {
                await store.syncFromServer()
            }
        }
        .onChange(of: session.token) { _, newValue in
            store.updateAuthToken(newValue)
            if newValue == nil {
                return
            }
            Task { await store.syncFromServer() }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(TrickStore())
        .environmentObject(SessionStore())
}
