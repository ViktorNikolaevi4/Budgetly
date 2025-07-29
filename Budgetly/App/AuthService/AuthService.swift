import Foundation
import Observation
import CloudKit
import AuthenticationServices

@Observable
final class AuthService {
    // MARK: — Состояние
    /// Текущий залогиненный e‑mail или Apple User ID
    var currentEmail: String? = nil
    var currentName:  String? = nil

    // MARK: — Ошибки
    enum AuthError: LocalizedError {
        case userNotFound
        case wrongPassword
        case emptyFields
        case unknown

        var errorDescription: String? {
            switch self {
            case .userNotFound:  return "Пользователь не найден."
            case .wrongPassword: return "Неверный пароль."
            case .emptyFields:   return "Заполните все поля."
            case .unknown:       return "Неизвестная ошибка."
            }
        }
    }

    // MARK: — Логин локально по email+паролю
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
        currentName  = nil
        return .success(())
    }

    func logout() {
        currentEmail = nil
        currentName  = nil
    }

    // MARK: — Восстановление пароля (заглушка)
    func sendPasswordReset(email: String) -> Result<Void, AuthError> {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .failure(.emptyFields)
        }
        guard KeychainManager.retrievePassword(for: trimmed) != nil else {
            return .failure(.userNotFound)
        }
        return .success(())
    }
}

// MARK: — Регистрация Email+CloudKit + Sign In with Apple

extension AuthService {
    /// Sign Up по e‑mail + паролю: сохраняем в Keychain и CloudKit
    func signUp(
        name: String,
        email: String,
        password: String,
        completion: @escaping (Result<Void, AuthError>) -> Void
    ) {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !password.isEmpty, !name.isEmpty else {
            completion(.failure(.emptyFields))
            return
        }

        // 1) Keychain
        let saved = KeychainManager.savePassword(password, for: trimmed)
        guard saved else {
            completion(.failure(.unknown))
            return
        }

        // 2) CloudKit
        let recordID = CKRecord.ID(recordName: trimmed)
        let userRecord = CKRecord(recordType: "User", recordID: recordID)
        userRecord["name"]  = name as NSString
        userRecord["email"] = trimmed as NSString

        let db = CKContainer.default().publicCloudDatabase
        db.save(userRecord) { _, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ CloudKit signUp error:", error)
                    completion(.failure(.unknown))
                } else {
                    self.currentEmail = trimmed
                    self.currentName  = name
                    completion(.success(()))
                }
            }
        }
    }

    /// Sign In / Up через Sign in with Apple
    func signInWithApple(
        credential: ASAuthorizationAppleIDCredential,
        completion: @escaping (Result<Void, AuthError>) -> Void
    ) {
        let userId = credential.user

        // 1) Сохраняем идентификатор как «пароль»
        _ = KeychainManager.savePassword(userId, for: userId)

        // 2) Готовим данные
        var fullName: String?
        if let given = credential.fullName?.givenName,
           let family = credential.fullName?.familyName {
            fullName = "\(given) \(family)"
        } else if let given = credential.fullName?.givenName {
            fullName = given
        }
        let emailFromApple = credential.email

        // 3) CloudKit
        let recordID = CKRecord.ID(recordName: userId)
        let userRecord = CKRecord(recordType: "User", recordID: recordID)
        if let name = fullName {
            userRecord["name"] = name as NSString
        }
        if let email = emailFromApple {
            userRecord["email"] = email as NSString
        }

        let db = CKContainer.default().publicCloudDatabase
        db.save(userRecord) { _, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ CloudKit signInWithApple error:", error)
                    completion(.failure(.unknown))
                } else {
                    self.currentEmail = userId
                    self.currentName  = fullName
                    completion(.success(()))
                }
            }
        }
    }
}

// MARK: — EnvironmentKey

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

