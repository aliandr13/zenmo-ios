import Foundation

enum TransactionsAPI {
    static func list(accountId: String?, page: Int, size: Int) async throws -> PageTxnResponse {
        var query = "page=\(page)&size=\(size)"
        if let accountId, !accountId.isEmpty {
            query += "&accountId=\(accountId)"
        }
        return try await APIClient.shared.get("/api/transactions?\(query)")
    }

    static func create(_ request: TxnRequest) async throws -> TxnResponse {
        try await APIClient.shared.post("/api/transactions", body: request)
    }

    static func delete(id: String) async throws {
        try await APIClient.shared.delete("/api/transactions/\(id)")
    }
}
