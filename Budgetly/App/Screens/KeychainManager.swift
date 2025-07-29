import Foundation
import Security

struct KeychainManager {
    @discardableResult
    static func savePassword(_ password: String, for account: String) -> Bool {
        let data = Data(password.utf8)
        let query: [String: Any] = [
            kSecClass as String:            kSecClassGenericPassword,
            kSecAttrAccount as String:      account,
            kSecValueData as String:        data
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    static func retrievePassword(for account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String:           kSecClassGenericPassword,
            kSecAttrAccount as String:     account,
            kSecReturnData as String:      true,
            kSecMatchLimit as String:      kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let pw = String(data: data, encoding: .utf8)
        else {
            return nil
        }
        return pw
    }

    @discardableResult
    static func deletePassword(for account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
}


