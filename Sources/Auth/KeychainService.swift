import Foundation
import Security

enum KeychainService {
    private static let accessTokenKey = "com.zenmo.accessToken"
    private static let refreshTokenKey = "com.zenmo.refreshToken"

    static func saveTokens(access: String, refresh: String) {
        set(access, forKey: accessTokenKey)
        set(refresh, forKey: refreshTokenKey)
    }

    static func loadTokens() -> (access: String, refresh: String)? {
        guard let access = get(forKey: accessTokenKey),
              let refresh = get(forKey: refreshTokenKey) else { return nil }
        return (access, refresh)
    }

    static func clearTokens() {
        delete(forKey: accessTokenKey)
        delete(forKey: refreshTokenKey)
    }

    // MARK: - Private primitives

    private static func set(_ value: String, forKey key: String) {
        let data = Data(value.utf8)
        delete(forKey: key)
        let attrs: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData: data,
        ]
        SecItemAdd(attrs as CFDictionary, nil)
    }

    private static func get(forKey key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func delete(forKey key: String) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
