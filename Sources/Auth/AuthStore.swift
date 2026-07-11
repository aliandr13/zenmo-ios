import Foundation

@MainActor
final class AuthStore: ObservableObject {
    @Published var currentUser: CurrentUser?
    @Published var isLoading = false
    @Published var isRestoring = true

    var isAuthenticated: Bool { currentUser != nil }

    init() {
        Task { await tryRestoreSession() }
    }

    func login(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        let tokens = try await AuthAPI.login(email: email, password: password)
        await storeTokens(tokens)
        currentUser = try await AuthAPI.me()
    }

    func register(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        let tokens = try await AuthAPI.register(email: email, password: password)
        await storeTokens(tokens)
        currentUser = try await AuthAPI.me()
    }

    func logout() async {
        await APIClient.shared.clearTokens()
        KeychainService.clearTokens()
        currentUser = nil
    }

    // MARK: - Private

    private func tryRestoreSession() async {
        defer { isRestoring = false }
        guard let (access, refresh) = KeychainService.loadTokens() else { return }
        await APIClient.shared.setTokens(access: access, refresh: refresh)
        do {
            currentUser = try await AuthAPI.me()
        } catch {
            await APIClient.shared.clearTokens()
            KeychainService.clearTokens()
        }
    }

    private func storeTokens(_ tokens: TokensResponse) async {
        await APIClient.shared.setTokens(access: tokens.accessToken, refresh: tokens.refreshToken)
        KeychainService.saveTokens(access: tokens.accessToken, refresh: tokens.refreshToken)
    }
}
