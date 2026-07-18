import Foundation

enum CategoriesAPI {
    static func list() async throws -> [CategoryResponse] {
        try await APIClient.shared.get("/api/categories")
    }
}
