import Foundation

enum APIClientError: LocalizedError, Sendable {
    case unauthorized
    case httpError(Int, String)
    case decoding(any Error)
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Session expired. Please log in again."
        case .httpError(_, let msg):
            return msg
        case .decoding(let e):
            return "Unexpected server response: \(e.localizedDescription)"
        case .invalidURL:
            return "Invalid URL"
        }
    }
}

actor APIClient {
    static let shared = APIClient()
    private init() {}

    private let session = URLSession.shared
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    #if DEBUG
    var baseURL = "http://localhost:8080"
    #else
    let baseURL = "https://zenmo.fyi"
    #endif

    private(set) var accessToken: String?
    private(set) var storedRefreshToken: String?

    func setTokens(access: String, refresh: String) {
        accessToken = access
        storedRefreshToken = refresh
    }

    func clearTokens() {
        accessToken = nil
        storedRefreshToken = nil
    }

    // MARK: - Public interface

    func get<T: Decodable & Sendable>(_ path: String) async throws -> T {
        let url = try makeURL(path)
        do {
            return try await execute(url: url, method: "GET", body: nil, token: accessToken)
        } catch APIClientError.unauthorized {
            try await doRefresh()
            return try await execute(url: url, method: "GET", body: nil, token: accessToken)
        }
    }

    func post<B: Encodable & Sendable, T: Decodable & Sendable>(_ path: String, body: B) async throws -> T {
        let url = try makeURL(path)
        let encoded = try encoder.encode(body)
        do {
            return try await execute(url: url, method: "POST", body: encoded, token: accessToken)
        } catch APIClientError.unauthorized {
            try await doRefresh()
            return try await execute(url: url, method: "POST", body: encoded, token: accessToken)
        }
    }

    func put<B: Encodable & Sendable, T: Decodable & Sendable>(_ path: String, body: B) async throws -> T {
        let url = try makeURL(path)
        let encoded = try encoder.encode(body)
        do {
            return try await execute(url: url, method: "PUT", body: encoded, token: accessToken)
        } catch APIClientError.unauthorized {
            try await doRefresh()
            return try await execute(url: url, method: "PUT", body: encoded, token: accessToken)
        }
    }

    func delete(_ path: String) async throws {
        let url = try makeURL(path)
        do {
            try await executeVoid(url: url, method: "DELETE", body: nil, token: accessToken)
        } catch APIClientError.unauthorized {
            try await doRefresh()
            try await executeVoid(url: url, method: "DELETE", body: nil, token: accessToken)
        }
    }

    /// For auth endpoints that don't carry a Bearer token (login, register, refresh).
    func postPublic<B: Encodable & Sendable, T: Decodable & Sendable>(_ path: String, body: B) async throws -> T {
        let url = try makeURL(path)
        let encoded = try encoder.encode(body)
        return try await execute(url: url, method: "POST", body: encoded, token: nil)
    }

    // MARK: - Private

    private func doRefresh() async throws {
        guard let refresh = storedRefreshToken else { throw APIClientError.unauthorized }
        let url = try makeURL("/api/auth/refresh")
        let encoded = try encoder.encode(RefreshRequest(refreshToken: refresh))
        do {
            let tokens: TokensResponse = try await execute(url: url, method: "POST", body: encoded, token: nil)
            setTokens(access: tokens.accessToken, refresh: tokens.refreshToken)
            KeychainService.saveTokens(access: tokens.accessToken, refresh: tokens.refreshToken)
        } catch {
            clearTokens()
            KeychainService.clearTokens()
            throw APIClientError.unauthorized
        }
    }

    private func execute<T: Decodable & Sendable>(
        url: URL, method: String, body: Data?, token: String?
    ) async throws -> T {
        let (data, response) = try await session.data(for: buildRequest(url: url, method: method, body: body, token: token))
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if status == 401 { throw APIClientError.unauthorized }
        guard (200..<300).contains(status) else {
            let msg = (try? decoder.decode(APIErrorBody.self, from: data))?.message ?? "Request failed (\(status))"
            throw APIClientError.httpError(status, msg)
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIClientError.decoding(error)
        }
    }

    private func executeVoid(url: URL, method: String, body: Data?, token: String?) async throws {
        let (data, response) = try await session.data(for: buildRequest(url: url, method: method, body: body, token: token))
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if status == 401 { throw APIClientError.unauthorized }
        guard (200..<300).contains(status) else {
            let msg = (try? decoder.decode(APIErrorBody.self, from: data))?.message ?? "Request failed (\(status))"
            throw APIClientError.httpError(status, msg)
        }
    }

    private func buildRequest(url: URL, method: String, body: Data?, token: String?) -> URLRequest {
        var req = URLRequest(url: url)
        req.httpMethod = method
        if let token { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        if let body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = body
        }
        return req
    }

    private func makeURL(_ path: String) throws -> URL {
        guard let url = URL(string: baseURL + path) else { throw APIClientError.invalidURL }
        return url
    }
}
