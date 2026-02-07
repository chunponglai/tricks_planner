import Combine
import Foundation
import SwiftUI

@MainActor
final class SessionStore: ObservableObject {
    @AppStorage("authToken") private var storedToken: String = ""
    @Published private(set) var token: String? = nil
    @Published var isLoading = false
    @Published var errorMessage: String?

    init() {
        token = storedToken.isEmpty ? nil : storedToken
    }

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let token = try await APIClient.shared.login(email: email, password: password)
            storedToken = token
            self.token = token
        } catch {
            errorMessage = "Login failed. Check email/password."
        }
        isLoading = false
    }

    func register(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await APIClient.shared.register(email: email, password: password)
            let token = try await APIClient.shared.login(email: email, password: password)
            storedToken = token
            self.token = token
        } catch {
            errorMessage = "Registration failed. Try a different email."
        }
        isLoading = false
    }

    func logout() {
        storedToken = ""
        token = nil
    }
}
