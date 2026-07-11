import Foundation

// MARK: - Auth

struct LoginRequest: Codable, Sendable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable, Sendable {
    let email: String
    let password: String
}

struct TokensResponse: Codable, Sendable {
    let accessToken: String
    let refreshToken: String
}

struct RefreshRequest: Codable, Sendable {
    let refreshToken: String
}

struct CurrentUser: Codable, Sendable {
    let userId: String
    let email: String
}

// MARK: - Accounts

enum AccountType: String, Codable, CaseIterable, Sendable {
    case checking = "CHECKING"
    case cash = "CASH"
    case savings = "SAVINGS"
    case credit = "CREDIT"

    var displayName: String {
        switch self {
        case .checking: "Checking"
        case .cash: "Cash"
        case .savings: "Savings"
        case .credit: "Credit"
        }
    }
}

// MARK: - Internal

struct APIErrorBody: Decodable, Sendable {
    let message: String?
}
