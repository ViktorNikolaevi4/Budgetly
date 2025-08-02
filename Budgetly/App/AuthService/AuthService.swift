import Foundation
import AuthenticationServices
import Observation
import CloudKit
import SwiftData

@Observable
final class AuthService {
    var cloudUserRecordID: String?
    var currentName: String?
    var currentEmail: String?
    var originalEmail: String?

    private let container = CKContainer(identifier: "iCloud.Korolvoff.Budgetly2")

    func fetchCloudUserRecordID() {
        CKContainer.default().fetchUserRecordID { [weak self] recordID, error in
            guard let self = self else { return }
            guard let recordName = recordID?.recordName, error == nil else {
                print("❌ Ошибка получения userRecordID: \(error?.localizedDescription ?? "Неизвестная ошибка") в \(Date())")
                return
            }
            DispatchQueue.main.async {
                self.cloudUserRecordID = recordName
                print("👉 iCloud userRecordID = \(recordName) в \(Date())")
            }
        }
    }

    func signInWithApple(
        credential: ASAuthorizationAppleIDCredential,
        modelContext: ModelContext,
        completion: @escaping (Result<Void, AuthError>) -> Void
    ) {
        let userId = credential.user
        let db = container.privateCloudDatabase
        let recordID = CKRecord.ID(recordName: userId)

        let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        let email = credential.email ?? userId

        let record = CKRecord(recordType: "User", recordID: recordID)
        record["email"] = email
        record["name"] = fullName.isEmpty ? nil : fullName

        db.save(record) { [weak self] _, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Ошибка CloudKit: \(error.localizedDescription) в \(Date())")
                    completion(.failure(.unknown))
                    return
                }
                self.cloudUserRecordID = userId
                self.currentEmail = email
                self.originalEmail = email
                self.currentName = fullName.isEmpty ? nil : fullName

                let user = User(id: userId, name: fullName.isEmpty ? nil : fullName, email: email)
                modelContext.insert(user)
                try? modelContext.save()

                completion(.success(()))
            }
        }
    }

    func signUp(
        name: String,
        email: String,
        password: String,
        modelContext: ModelContext,
        completion: @escaping (Result<Void, AuthError>) -> Void
    ) {
        if email.isEmpty || password.isEmpty || name.isEmpty {
            completion(.failure(.emptyFields))
            return
        }
        if !isValidEmail(email) {
            completion(.failure(.unknown))
            return
        }

        let userId = email
        let db = container.privateCloudDatabase
        let recordID = CKRecord.ID(recordName: userId)

        let record = CKRecord(recordType: "User", recordID: recordID)
        record["email"] = email
        record["name"] = name
        record["password"] = password // В реальном приложении хешировать

        db.save(record) { [weak self] _, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Ошибка сохранения пользователя в CloudKit: \(error.localizedDescription) в \(Date())")
                    completion(.failure(.unknown))
                    return
                }
                self.cloudUserRecordID = userId
                self.currentEmail = email
                self.originalEmail = email
                self.currentName = name

                let user = User(id: userId, name: name, email: email)
                modelContext.insert(user)
                try? modelContext.save()

                completion(.success(()))
            }
        }
    }

    func login(email: String, password: String) -> Result<Void, AuthError> {
        if email.isEmpty || password.isEmpty {
            return .failure(.emptyFields)
        }
        if email == "test@example.com" && password == "password123" {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.currentEmail = email
                self.originalEmail = email
                self.fetchCloudUserRecordID()
            }
            return .success(())
        } else if email != "test@example.com" {
            return .failure(.userNotFound)
        } else {
            return .failure(.wrongPassword)
        }
    }

    func sendPasswordReset(email: String) -> Result<Void, AuthError> {
        if email.isEmpty || !isValidEmail(email) {
            return .failure(.emptyFields)
        }
        if email == "test@example.com" {
            return .success(())
        } else {
            return .failure(.userNotFound)
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }

    func logout() {
        cloudUserRecordID = nil
        currentEmail = nil
        currentName = nil
    }

    enum AuthError: LocalizedError {
        case userNotFound
        case wrongPassword
        case emptyFields
        case unknown

        var errorDescription: String? {
            switch self {
            case .userNotFound: return "Не удалось найти такой e-mail."
            case .wrongPassword: return "Пароль неверный."
            case .emptyFields: return "Заполните все поля."
            case .unknown: return "Неизвестная ошибка."
            }
        }
    }
}
