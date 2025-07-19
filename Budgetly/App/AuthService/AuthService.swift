import SwiftUI
import Observation
import Foundation

@Observable
final class AuthService {
    var currentEmail: String? = nil

    enum AuthError: LocalizedError {
        case userNotFound
        case wrongPassword
        case emptyFields
        case unknown

        var errorDescription: String? {
            switch self {
            case .userNotFound:  return "Пользователь не найден."
            case .wrongPassword: return "Неверный пароль."
            case .emptyFields:   return "Заполните поля."
            case .unknown:       return "Неизвестная ошибка."
            }
        }
    }

    @discardableResult
    func login(email: String, password: String) -> Result<Void, AuthError> {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !password.isEmpty else { return .failure(.emptyFields) }
        guard let stored = KeychainManager.retrievePassword(for: trimmed) else { return .failure(.userNotFound) }
        guard stored == password else { return .failure(.wrongPassword) }
        currentEmail = trimmed
        return .success(())
    }

    func logout() {
        currentEmail = nil
    }

    @discardableResult
    func register(email: String, password: String) -> Bool {
        KeychainManager.savePassword(password, for: email)
    }

    func sendPasswordReset(email: String) -> Result<Void, AuthError> {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .failure(.emptyFields) }
        guard KeychainManager.retrievePassword(for: trimmed) != nil else { return .failure(.userNotFound) }

        // Пока заглушка: просто успех
        return .success(())
    }
}

import SwiftUI

private struct AuthServiceKey: EnvironmentKey {
    static let defaultValue: AuthService = AuthService()
}

extension EnvironmentValues {
    var authService: AuthService {
        get { self[AuthServiceKey.self] }
        set { self[AuthServiceKey.self] = newValue }
    }
}
