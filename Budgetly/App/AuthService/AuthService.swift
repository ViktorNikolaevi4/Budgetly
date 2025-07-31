import Foundation
import Observation
import CloudKit
import AuthenticationServices

@Observable
final class AuthService {
    var currentEmail: String? {
        didSet {
            UserDefaults.standard.set(currentEmail, forKey: "currentEmail")
            print("currentEmail updated to: \(String(describing: currentEmail))")
        }
    }
    var originalEmail: String? {
        didSet {
            UserDefaults.standard.set(originalEmail, forKey: "originalEmail")
            print("originalEmail updated to: \(String(describing: originalEmail))")
        }
    }
    var currentName: String? {
        didSet {
            print("currentName updated to: \(String(describing: currentName))")
        }
    }

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

    init() {
        self.currentEmail = UserDefaults.standard.string(forKey: "currentEmail")
        self.originalEmail = UserDefaults.standard.string(forKey: "originalEmail")
        print("Init: currentEmail = \(String(describing: currentEmail)), originalEmail = \(String(describing: originalEmail))")
    }

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
        originalEmail = trimmed
        currentName = nil

        let recordID = CKRecord.ID(recordName: trimmed)
        let container = CKContainer(identifier: "iCloud.Korolvoff.Budgetly2")
        container.publicCloudDatabase.fetch(withRecordID: recordID) { record, error in
            DispatchQueue.main.async {
                if let name = record?["name"] as? String {
                    self.currentName = name
                }
            }
        }
        return .success(())
    }

    func logout() {
        currentEmail = nil
        originalEmail = nil
        currentName = nil
        UserDefaults.standard.removeObject(forKey: "currentEmail")
        UserDefaults.standard.removeObject(forKey: "originalEmail")
    }

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

        let saved = KeychainManager.savePassword(password, for: trimmed)
        guard saved else {
            completion(.failure(.unknown))
            return
        }

        let recordID = CKRecord.ID(recordName: trimmed)
        let userRecord = CKRecord(recordType: "User", recordID: recordID)
        userRecord["name"] = name as NSString
        userRecord["email"] = trimmed as NSString

        let container = CKContainer(identifier: "iCloud.Korolvoff.Budgetly2")
        let db = container.publicCloudDatabase
        db.save(userRecord) { _, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ CloudKit signUp error: \(error.localizedDescription)")
                    completion(.failure(.unknown))
                } else {
                    self.currentEmail = trimmed
                    self.originalEmail = trimmed
                    self.currentName = name
                    completion(.success(()))
                }
            }
        }
    }

    func signInWithApple(
        credential: ASAuthorizationAppleIDCredential,
        completion: @escaping (Result<Void, AuthError>) -> Void
    ) {
        let userId = credential.user
        let container = CKContainer(identifier: "iCloud.Korolvoff.Budgetly2")
        let db = container.publicCloudDatabase

        // 1) Попытка получить e-mail из credential (выдаётся только при первом ever-login)
        let emailFromApple = credential.email
        let savedKey = "appleEmail_\(userId)"
        if let email = emailFromApple {
            UserDefaults.standard.set(email, forKey: savedKey)
        }

        // 2) Собираем полное имя (если Apple его вернул)
        let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")

        // 3) Определяем recordID по userId
        let recordID = CKRecord.ID(recordName: userId)

        // 4) Сначала пытаемся получить уже существующую запись
        print("Fetching existing record for userId: \(userId)")
        db.fetch(withRecordID: recordID) { existingRecord, fetchError in
            DispatchQueue.main.async {
                if let fetchError = fetchError {
                    print("❌ Fetch error: \(fetchError.localizedDescription)")
                }

                // Берём найденную запись или создаём новую
                let record = existingRecord ?? CKRecord(recordType: "User", recordID: recordID)

                // Извлекаем e-mail, который мог быть раньше записан в CloudKit
                let cloudEmail = record["email"] as? String
                // Ещё раз смотрим в UserDefaults на случай, если credential.email == nil
                let udEmail = UserDefaults.standard.string(forKey: savedKey)

                // Выбираем приоритет: cloudEmail → emailFromApple → udEmail → fallback userId
                let finalEmail = cloudEmail ?? emailFromApple ?? udEmail ?? userId

                // 5) Обновляем поля записи
                record["email"] = finalEmail as NSString
                if !fullName.isEmpty {
                    record["name"] = fullName as NSString
                }

                // 6) Обновляем состояние
                self.currentEmail = finalEmail
                self.originalEmail = (finalEmail == userId ? nil : finalEmail)
                self.currentName = fullName.isEmpty ? nil : fullName

                // 7) Асинхронно сохраняем запись в CloudKit с обработкой конфликтов
                print("Saving record for userId: \(userId)")
                db.save(record) { _, saveError in
                    DispatchQueue.main.async {
                        if let saveError = saveError {
                            print("❌ CloudKit save error: \(saveError.localizedDescription)")
                            // Логируем ошибку, но не прерываем процесс, так как пользователь уже вошёл
                        } else {
                            print("Record saved successfully for userId: \(userId)")
                        }
                        // Вызываем completion после попытки сохранения (для надёжности)
                        completion(.success(()))
                    }
                }
            }
        }
    }


    private func fetchUserEmail(userId: String, completion: @escaping (String?) -> Void) {
        let recordID = CKRecord.ID(recordName: userId)
        let container = CKContainer(identifier: "iCloud.Korolvoff.Budgetly2")
        let db = container.publicCloudDatabase
        print("Fetching email for userId: \(userId)")
        db.fetch(withRecordID: recordID) { record, error in
            DispatchQueue.main.async {
                if let record = record, let email = record["email"] as? String {
                    print("Fetched email from CloudKit: \(email)")
                    completion(email)
                } else {
                    print("Failed to fetch email: \(String(describing: error?.localizedDescription))")
                    completion(nil)
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

