import Foundation

enum AuthAPI {
    static func login(email: String, password: String) async throws -> TokensResponse {
        try await APIClient.shared.postPublic(
            "/api/auth/login",
            body: LoginRequest(email: email, password: password)
        )
    }

    static func register(email: String, password: String) async throws -> TokensResponse {
        try await APIClient.shared.postPublic(
            "/api/auth/register",
            body: RegisterRequest(email: email, password: password)
        )
    }

    static func me() async throws -> CurrentUser {
        try await APIClient.shared.get("/api/auth/me")
    }
}
