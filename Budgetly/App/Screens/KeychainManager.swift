import Security
import Foundation

struct KeychainManager {
    static func savePassword(_ password: String, for email: String) -> Bool {
        let data = Data(password.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: email,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary) // Удаляем предыдущий пароль, если он существует

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    static func retrievePassword(for email: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: email,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        guard status == errSecSuccess, let data = dataTypeRef as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    static func deletePassword(for email: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: email
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
}

