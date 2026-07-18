import Foundation

enum AccountsAPI {
    static func list() async throws -> [AccountResponse] {
        try await APIClient.shared.get("/api/accounts")
    }
}
