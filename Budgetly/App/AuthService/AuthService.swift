import Foundation
import SwiftUI
import Observation

@Observable
final class AuthService {
    /// Текущий авторизованный email (nil если не вошёл)
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

    // MARK: – API

    @discardableResult
    func login(email: String, password: String) -> Result<Void, AuthError> {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !password.isEmpty else {
            return .failure(.emptyFields)
        }
        guard let stored = KeychainManager.retrievePassword(for: trimmed) else {
            return .failure(.userNotFound)
        }
        guard stored == password else {
            return .failure(.wrongPassword)
        }
        currentEmail = trimmed
        return .success(())
    }

    func logout() {
        currentEmail = nil
    }

    /// Зарегистрировать пользователя локально (Keychain + можно расширить CloudKit)
    @discardableResult
    func register(email: String, password: String) -> Bool {
        KeychainManager.savePassword(password, for: email)
    }
}


private struct AuthServiceKey: EnvironmentKey {
    static let defaultValue = AuthService() // можно «пустой» или shared
}

extension EnvironmentValues {
    var authService: AuthService {
        get { self[AuthServiceKey.self] }
        set { self[AuthServiceKey.self] = newValue }
    }
}
