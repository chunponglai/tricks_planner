import Foundation

struct APIClient {
    static let shared = APIClient()

    let baseURL = URL(string: "http://192.168.86.22:8000")!

    private let logger = Logger()

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    func register(email: String, password: String) async throws {
        logger.log("register(email=\(email), password=<redacted>)")
        let url = baseURL.appendingPathComponent("/auth/register")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["email": email, "password": password]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw APIError("Register failed: \( (response as? HTTPURLResponse)?.statusCode ?? 0) \(body)")
        }
    }

    func login(email: String, password: String) async throws -> String {
        logger.log("login(email=\(email), password=<redacted>)")
        let url = baseURL.appendingPathComponent("/auth/login")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body = "username=\(email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? email)&password=\(password.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? password)"
        request.httpBody = body.data(using: .utf8)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw APIError("Login failed: \( (response as? HTTPURLResponse)?.statusCode ?? 0) \(body)")
        }
        let token = try decoder.decode(TokenResponse.self, from: data)
        return token.accessToken
    }

    func fetchSync(token: String) async throws -> SyncPayload {
        logger.log("fetchSync(token=<redacted>)")
        let url = baseURL.appendingPathComponent("/sync")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw APIError("Sync fetch failed: \( (response as? HTTPURLResponse)?.statusCode ?? 0) \(body)")
        }
        return try decoder.decode(SyncPayload.self, from: data)
    }

    func pushSync(token: String, payload: SyncPayload) async throws {
        logger.log("pushSync(token=<redacted>, payload=categories:\(payload.categories.count), tricks:\(payload.tricks.count), templates:\(payload.templates.count), challenges:\(payload.challenges.count), trainingPlans:\(payload.trainingPlans.count))")
        let url = baseURL.appendingPathComponent("/sync")
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(payload)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw APIError("Sync push failed: \( (response as? HTTPURLResponse)?.statusCode ?? 0) \(body)")
        }
    }
}

private struct Logger {
    func log(_ message: String) {
        print("[API] \(message)")
    }
}

struct APIError: LocalizedError {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? { message }
}

private struct TokenResponse: Codable {
    let accessToken: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
    }
}
