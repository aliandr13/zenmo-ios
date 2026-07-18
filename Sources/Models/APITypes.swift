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

struct AccountResponse: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let type: AccountType
    let currency: String
    let creditLimit: Decimal?
    let currentBalance: Decimal
    let statementBalance: Decimal?
    let paymentDueDay: Int?
    let closingDay: Int?
    let archived: Bool
}

// MARK: - Categories

struct CategoryResponse: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let parentId: String?
    let color: String?
}

// MARK: - Transactions

enum TxnStatus: String, Codable, CaseIterable, Sendable {
    case pending = "PENDING"
    case posted = "POSTED"

    var displayName: String {
        switch self {
        case .pending: "Pending"
        case .posted: "Posted"
        }
    }
}

struct TxnResponse: Codable, Identifiable, Sendable {
    let id: String
    let accountId: String
    let categoryId: String?
    let transactionDate: String
    let postDate: String?
    let amount: Decimal
    let currency: String
    let description: String
    let merchant: String?
    let status: TxnStatus
    let notes: String?
}

struct TxnRequest: Codable, Sendable {
    let accountId: String
    let categoryId: String?
    let transactionDate: String
    let postDate: String?
    let amount: Decimal
    let currency: String
    let description: String
    let merchant: String?
    let status: TxnStatus
    let notes: String?
}

struct PageTxnResponse: Codable, Sendable {
    let content: [TxnResponse]
    let totalElements: Int
    let totalPages: Int
    let number: Int
    let last: Bool
}

// MARK: - Internal

struct APIErrorBody: Decodable, Sendable {
    let message: String?
}
