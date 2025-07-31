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

        // 1) Попытка получить email из credential
        let emailFromApple = credential.email
        let savedEmailKey = "appleEmail_\(userId)"
        let resolvedEmail: String? = emailFromApple ?? UserDefaults.standard.string(forKey: savedEmailKey)

        // 2) Имя
        let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }.joined(separator: " ")

        // 3) Выбираем recordID = email, если он известен, иначе fallback — userId
        let recordName = resolvedEmail ?? userId
        let recordID = CKRecord.ID(recordName: recordName)

        // 4) Fetch + save
        print("Fetching existing record for userId: \(userId)")
        db.fetch(withRecordID: recordID) { existing, fetchError in
            DispatchQueue.main.async {
                if let fetchError = fetchError {
                    print("❌ Fetch error: \(fetchError.localizedDescription)")
                }
                let record = existing ?? CKRecord(recordType: "User", recordID: recordID)

                // Имя
                if !fullName.isEmpty {
                    record["name"] = fullName as NSString
                    self.currentName = fullName
                }

                // Email
                if let email = emailFromApple {
                    record["email"] = email as NSString
                    UserDefaults.standard.set(email, forKey: savedEmailKey)
                    self.currentEmail = email
                    self.originalEmail = email
                } else if let email = resolvedEmail {
                    record["email"] = email as NSString
                    self.currentEmail = email
                    self.originalEmail = email
                } else {
                    print("No email available, using userId as recordName")
                    self.currentEmail = userId
                    self.originalEmail = nil
                }

                print("Saving record for userId: \(userId)")
                db.save(record) { _, saveError in
                    DispatchQueue.main.async {
                        if let saveError = saveError {
                            print("❌ Save error: \(saveError.localizedDescription)")
                            completion(.failure(.unknown))
                        } else {
                            print("Record saved successfully for userId: \(userId)")
                            self.currentEmail = recordName // Убедимся, что currentEmail установлен
                            completion(.success(()))
                        }
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

