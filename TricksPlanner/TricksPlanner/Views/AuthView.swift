import SwiftUI
import UniformTypeIdentifiers

struct AuthView: View {
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var store: TrickStore
    @State private var isRegister = false
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showExporter = false
    @State private var exportDocument: SyncPayloadDocument?
    @State private var importError: String?

    private var exportFileName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm"
        return "tricksplanner-backup-\(formatter.string(from: Date()))"
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("TricksPlanner")
                    .font(Theme.titleFont(size: 28))
                    .foregroundStyle(Theme.textPrimary)

                Picker("Mode", selection: $isRegister) {
                    Text("Login").tag(false)
                    Text("Register").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 24)

                VStack(spacing: 12) {
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        Group {
                            if showPassword {
                                TextField("Password", text: $password)
                                    .textInputAutocapitalization(.never)
                            } else {
                                SecureField("Password", text: $password)
                            }
                        }
                        .textFieldStyle(.roundedBorder)

                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)

                if let error = session.errorMessage {
                    Text(error)
                        .font(Theme.bodyFont(size: 13))
                        .foregroundStyle(.red)
                }

                Button {
                    Task {
                        if isRegister {
                            await session.register(email: email, password: password)
                        } else {
                            await session.login(email: email, password: password)
                        }
                    }
                } label: {
                    Text(isRegister ? "Create Account" : "Login")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)
                .disabled(email.isEmpty || password.count < 6 || session.isLoading)

                VStack(spacing: 8) {
                    Text("Migration")
                        .font(Theme.bodyFont(size: 14))
                        .foregroundStyle(Theme.textSecondary)

                    Button("Export Data") {
                        do {
                            let data = try store.exportSyncData()
                            exportDocument = SyncPayloadDocument(data: data)
                            showExporter = true
                        } catch {
                            importError = error.localizedDescription
                        }
                    }
                    .buttonStyle(.bordered)

                    if let importError {
                        Text(importError)
                            .font(Theme.bodyFont(size: 12))
                            .foregroundStyle(.red)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .padding(.top, 40)
        }
        .fileExporter(
            isPresented: $showExporter,
            document: exportDocument,
            contentType: .json,
            defaultFilename: exportFileName
        ) { result in
            if case .failure(let error) = result {
                importError = error.localizedDescription
            }
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(SessionStore())
        .environmentObject(TrickStore())
}
