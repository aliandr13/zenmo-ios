import SwiftUI

@MainActor
final class AccountsViewModel: ObservableObject {
    @Published var accounts: [AccountResponse] = []
    @Published var isLoading = true
    @Published var errorMessage: String?

    var creditAccounts: [AccountResponse] {
        accounts.filter { $0.type == .credit }
    }

    var checkingAndCashAccounts: [AccountResponse] {
        accounts.filter { $0.type == .checking || $0.type == .cash }
    }

    var savingsAccounts: [AccountResponse] {
        accounts.filter { $0.type == .savings }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            accounts = try await AccountsAPI.list()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct AccountsView: View {
    @StateObject private var viewModel = AccountsViewModel()

    var body: some View {
        List {
            if let errorMessage = viewModel.errorMessage {
                Section {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }

            if !viewModel.isLoading && viewModel.accounts.isEmpty && viewModel.errorMessage == nil {
                Section {
                    Text("No accounts.").foregroundStyle(.secondary)
                }
            }

            accountSection("Credit", accounts: viewModel.creditAccounts)
            accountSection("Checking & Cash", accounts: viewModel.checkingAndCashAccounts)
            accountSection("Savings", accounts: viewModel.savingsAccounts)
        }
        .navigationTitle("Accounts")
        .overlay {
            if viewModel.isLoading && viewModel.accounts.isEmpty {
                ProgressView()
            }
        }
        .refreshable { await viewModel.load() }
        .task { await viewModel.load() }
    }

    @ViewBuilder
    private func accountSection(_ title: String, accounts: [AccountResponse]) -> some View {
        if !accounts.isEmpty {
            Section(title) {
                ForEach(accounts) { account in
                    AccountRow(account: account)
                }
            }
        }
    }
}

private struct AccountRow: View {
    let account: AccountResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(account.name)
                .font(.body)
            HStack {
                Text(formattedMoney(account.currentBalance, currency: account.currency))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                if account.type == .credit, let limit = account.creditLimit, limit != 0 {
                    Text(utilization(balance: account.currentBalance, limit: limit))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func formattedMoney(_ amount: Decimal, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount) \(currency)"
    }

    private func utilization(balance: Decimal, limit: Decimal) -> String {
        // Credit balances are negative when money is owed (-200 = 200 owed), so owed = -balance.
        let ratio = (-balance / limit) as NSDecimalNumber
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 1
        return formatter.string(from: ratio) ?? "—"
    }
}
