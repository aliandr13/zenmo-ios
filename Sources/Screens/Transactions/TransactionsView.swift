import SwiftUI

@MainActor
final class TransactionsViewModel: ObservableObject {
    @Published var transactions: [TxnResponse] = []
    @Published var accounts: [AccountResponse] = []
    @Published var categories: [CategoryResponse] = []
    @Published var isLoading = true
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var selectedAccountId: String?

    private var currentPage = 0
    private var isLastPage = false
    private let pageSize = 20

    func accountName(for id: String) -> String {
        accounts.first { $0.id == id }?.name ?? "Unknown account"
    }

    func categoryName(for id: String?) -> String? {
        guard let id else { return nil }
        return categories.first { $0.id == id }?.name
    }

    func loadInitial() async {
        isLoading = true
        errorMessage = nil
        do {
            async let accountsResult = AccountsAPI.list()
            async let categoriesResult = CategoriesAPI.list()
            accounts = try await accountsResult
            categories = try await categoriesResult
        } catch {
            // Filters and labels are best-effort; the transaction list below still loads.
        }
        await reload()
        isLoading = false
    }

    func reload() async {
        currentPage = 0
        isLastPage = false
        do {
            let page = try await TransactionsAPI.list(accountId: selectedAccountId, page: 0, size: pageSize)
            transactions = page.content
            isLastPage = page.last
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadMoreIfNeeded(currentItem: TxnResponse) async {
        guard currentItem.id == transactions.last?.id, !isLastPage, !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let nextPage = currentPage + 1
            let page = try await TransactionsAPI.list(accountId: selectedAccountId, page: nextPage, size: pageSize)
            transactions.append(contentsOf: page.content)
            currentPage = nextPage
            isLastPage = page.last
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(_ txn: TxnResponse) async {
        do {
            try await TransactionsAPI.delete(id: txn.id)
            transactions.removeAll { $0.id == txn.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct TransactionsView: View {
    @StateObject private var viewModel = TransactionsViewModel()
    @State private var showAddForm = false
    @State private var pendingDelete: TxnResponse?

    var body: some View {
        List {
            if let errorMessage = viewModel.errorMessage {
                Section {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }

            if !viewModel.isLoading && viewModel.transactions.isEmpty && viewModel.errorMessage == nil {
                Section {
                    Text("No transactions.").foregroundStyle(.secondary)
                }
            }

            Section {
                ForEach(viewModel.transactions) { txn in
                    TransactionRow(
                        txn: txn,
                        accountName: viewModel.accountName(for: txn.accountId),
                        categoryName: viewModel.categoryName(for: txn.categoryId)
                    )
                    .swipeActions {
                        Button("Delete", role: .destructive) {
                            pendingDelete = txn
                        }
                    }
                    .task { await viewModel.loadMoreIfNeeded(currentItem: txn) }
                }
                if viewModel.isLoadingMore {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Transactions")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Menu {
                    Button("All accounts") {
                        viewModel.selectedAccountId = nil
                        Task { await viewModel.reload() }
                    }
                    ForEach(viewModel.accounts) { account in
                        Button(account.name) {
                            viewModel.selectedAccountId = account.id
                            Task { await viewModel.reload() }
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
                Button {
                    showAddForm = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .overlay {
            if viewModel.isLoading && viewModel.transactions.isEmpty {
                ProgressView()
            }
        }
        .refreshable { await viewModel.reload() }
        .task { await viewModel.loadInitial() }
        .sheet(isPresented: $showAddForm) {
            AddTransactionView(viewModel: viewModel)
        }
        .confirmationDialog(
            "Delete this transaction? This action cannot be undone.",
            isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let txn = pendingDelete {
                    Task { await viewModel.delete(txn) }
                }
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        }
    }
}

private struct TransactionRow: View {
    let txn: TxnResponse
    let accountName: String
    let categoryName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(txn.description)
                Spacer()
                Text(formattedMoney(txn.amount, currency: txn.currency))
                    .font(.body.weight(.medium))
            }
            HStack(spacing: 6) {
                Text(txn.transactionDate)
                Text("·")
                Text(accountName)
                if let categoryName {
                    Text("·")
                    Text(categoryName)
                }
                Spacer()
                statusBadge
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            if let merchant = txn.merchant, !merchant.isEmpty {
                Text(merchant)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private var statusBadge: some View {
        Text(txn.status.displayName)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background((txn.status == .posted ? Color.green : Color.orange).opacity(0.15))
            .foregroundStyle(txn.status == .posted ? .green : .orange)
            .clipShape(Capsule())
    }

    private func formattedMoney(_ amount: Decimal, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount) \(currency)"
    }
}

private struct AddTransactionView: View {
    @ObservedObject var viewModel: TransactionsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var accountId = ""
    @State private var categoryId = ""
    @State private var date = Date()
    @State private var amountText = ""
    @State private var currency = "USD"
    @State private var description = ""
    @State private var status: TxnStatus = .posted
    @State private var merchant = ""
    @State private var notes = ""
    @State private var errorMessage: String?
    @State private var submitting = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Account", selection: $accountId) {
                        Text("Select").tag("")
                        ForEach(viewModel.accounts) { account in
                            Text(account.name).tag(account.id)
                        }
                    }
                    Picker("Category", selection: $categoryId) {
                        Text("None").tag("")
                        ForEach(viewModel.categories) { category in
                            Text(category.name).tag(category.id)
                        }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                    TextField("Currency", text: $currency)
                        .textInputAutocapitalization(.characters)
                    TextField("Description", text: $description)
                    Picker("Status", selection: $status) {
                        ForEach(TxnStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    .pickerStyle(.segmented)
                    TextField("Merchant (optional)", text: $merchant)
                    TextField("Notes (optional)", text: $notes)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Transaction")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(submitting ? "Saving…" : "Save") {
                        Task { await submit() }
                    }
                    .disabled(submitting)
                }
            }
        }
    }

    private func submit() async {
        guard !accountId.isEmpty else {
            errorMessage = "Select an account"
            return
        }
        guard let amount = Decimal(string: amountText) else {
            errorMessage = "Enter a valid amount"
            return
        }
        guard !description.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Description is required"
            return
        }
        submitting = true
        errorMessage = nil
        let request = TxnRequest(
            accountId: accountId,
            categoryId: categoryId.isEmpty ? nil : categoryId,
            transactionDate: DateOnlyFormatter.string(from: date),
            postDate: nil,
            amount: amount,
            currency: currency,
            description: description,
            merchant: merchant.isEmpty ? nil : merchant,
            status: status,
            notes: notes.isEmpty ? nil : notes
        )
        do {
            _ = try await TransactionsAPI.create(request)
            submitting = false
            dismiss()
            await viewModel.reload()
        } catch {
            submitting = false
            errorMessage = error.localizedDescription
        }
    }
}

private enum DateOnlyFormatter {
    static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func string(from date: Date) -> String {
        formatter.string(from: date)
    }
}
