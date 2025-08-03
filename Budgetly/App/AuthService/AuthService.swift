import Foundation
import AuthenticationServices
import Observation
import CloudKit
import SwiftData
import FirebaseAuth
import FirebaseFirestore

@Observable
final class AuthService {
    var cloudUserRecordID: String?
    var currentName: String?
    var currentEmail: String?
    var originalEmail: String?
    var firebaseUserID: String?

    private let container = CKContainer(identifier: "iCloud.Korolvoff.Budgetly2")

    private var db: Firestore { Firestore.firestore() }

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

        db.fetch(withRecordID: recordID) { [weak self] fetchedRecord, fetchError in
            guard let self = self else { return }
            DispatchQueue.main.async {
                let record: CKRecord
                if let fetchedRecord = fetchedRecord {
                    // Запись есть, обновим её
                    record = fetchedRecord
                } else {
                    // Записи нет, создаём новую
                    record = CKRecord(recordType: "User", recordID: recordID)
                }
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
        }
    }


    func signUp(
        name: String,
        email: String,
        password: String,
        modelContext: ModelContext,
        completion: @escaping (Result<Void, AuthError>) -> Void
      ) {
        // валидация осталась прежней
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
          completion(.failure(.emptyFields)); return
        }

        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, err in
          DispatchQueue.main.async {
            guard let self = self else { return }
              if let err = err as NSError? {
                // 1) Выведем и-код и подробности userInfo
                print("❌ Firebase signUp error: code=\(err.code), domain=\(err.domain)\nuserInfo=\(err.userInfo)")
                // 2) Подумайте, как его обработать:
                switch AuthErrorCode(rawValue: err.code) {
                  case .emailAlreadyInUse:
                    completion(.failure(.emailExists))
                  case .invalidEmail:
                    completion(.failure(.invalidEmail))
                  case .weakPassword:
                    completion(.failure(.weakPassword))
                  default:
                    completion(.failure(.unknown))
                }
                return
              }
            let user = result!.user
            self.firebaseUserID = user.uid
            self.currentEmail  = email
            self.currentName   = name
            self.originalEmail = email

            // Сохраняем профиль в Firestore → collection "users" / doc uid
            self.db.collection("users")
              .document(user.uid)
              .setData([
                "name":  name,
                "email": email
              ]) { err in
                DispatchQueue.main.async {
                  if let err = err {
                    print("❌ Firestore setData error:", err.localizedDescription)
                    completion(.failure(.unknown))
                    return
                  }
                  // В локальный SwiftData вставляем модель User
                  let u = User(id: user.uid, name: name, email: email)
                  modelContext.insert(u)
                  try? modelContext.save()
                  completion(.success(()))
                }
              }
          }
        }
      }

    func login(
        email: String,
        password: String,
        modelContext: ModelContext,
        completion: @escaping (Result<Void, AuthError>) -> Void
      ) {
        guard !email.isEmpty, !password.isEmpty else {
          completion(.failure(.emptyFields)); return
        }

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, err in
          DispatchQueue.main.async {
            guard let self = self else { return }
            if let ns = err as NSError? {
              switch AuthErrorCode(rawValue: ns.code) {
              case .userNotFound:
                completion(.failure(.userNotFound))
              case .wrongPassword:
                completion(.failure(.wrongPassword))
              default:
                completion(.failure(.unknown))
              }
              return
            }
            // Успешно зашли
            let user = result!.user
            self.firebaseUserID  = user.uid
            self.currentEmail   = user.email
            self.currentName    = user.displayName

            // Теперь подтягиваем данные
            Task {
              await self.fetchFirestoreData(into: modelContext)
              completion(.success(()))
            }
          }
        }
      }

    func sendPasswordReset(email: String) async throws {
      // 1) базовая валидация
      guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            isValidEmail(email)
      else {
        throw AuthError.emptyFields
      }

      // 2) оборачиваем callback Firebase в continuation
      try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
        Auth.auth().sendPasswordReset(withEmail: email) { error in
          if let err = error as NSError? {
            switch AuthErrorCode(rawValue: err.code) {
            case .userNotFound:
              continuation.resume(throwing: AuthError.userNotFound)
            default:
              continuation.resume(throwing: AuthError.unknown)
            }
          } else {
            continuation.resume()  // успех
          }
        }
      }
    }

    private func fetchFirestoreData(into modelContext: ModelContext) async {
        guard let uid = firebaseUserID else { return }
        let userRoot = db.collection("users").document(uid)

        do {
            // 1) ACCOUNTS
            let acctSnap = try await userRoot.collection("accounts").getDocuments()
            for doc in acctSnap.documents {
                let d = doc.data()
                let acct = Account(
                    id: UUID(uuidString: doc.documentID) ?? UUID(),
                    name: d["name"] as? String ?? "",
                    currency: d["currency"] as? String,
                    initialBalance: d["initialBalance"] as? Double,
                    sortOrder: d["sortOrder"] as? Int ?? 0
                )
                acct.ownerUserRecordID = uid
                modelContext.insert(acct)
            }

            // 2) CATEGORIES
            let catSnap = try await userRoot.collection("categories").getDocuments()
            for doc in catSnap.documents {
                let d = doc.data()
                let cat = Category(
                    id: UUID(uuidString: doc.documentID) ?? UUID(),
                    name: d["name"] as? String ?? "",
                    type: CategoryType(rawValue: d["type"] as? String ?? "") ?? .expenses
                )
                cat.ownerUserRecordID = uid
                modelContext.insert(cat)
            }

            // 3) TRANSACTIONS
//            let txSnap = try await userRoot.collection("transactions").getDocuments()
//            for doc in txSnap.documents {
//                let d = doc.data()
//                let tx = Transaction(
//                    id: UUID(uuidString: doc.documentID) ?? UUID(),
//                    category: d["category"] as? String ?? "",
//                    amount: d["amount"] as? Double ?? 0,
//                    date: (d["date"] as? Timestamp)?.dateValue() ?? Date(),
//                    type: TransactionType(from: d["type"] as? String ?? "") ?? .expenses
//                )
//                tx.ownerUserRecordID = uid
//                modelContext.insert(tx)
//            }

            // 4) REGULAR PAYMENTS
            let rpSnap = try await userRoot.collection("regularPayments").getDocuments()
                    for doc in rpSnap.documents {
                        let d = doc.data()
                        let rp = RegularPayment(
                            id: UUID(uuidString: doc.documentID) ?? UUID(),
                            name: d["name"] as? String ?? "",
                            frequency: .monthly, // Добавляем по умолчанию, так как требуется
                            startDate: (d["date"] as? Timestamp)?.dateValue() ?? Date(), // Перемещаем перед amount
                            amount: d["amount"] as? Double ?? 0 // Перемещаем после startDate
                        )
                     //   rp.ownerUserRecordID = uid
                        modelContext.insert(rp)
                    }

            // 5) REMINDERS
            let remSnap = try await userRoot.collection("reminders").getDocuments()
            for doc in remSnap.documents {
                let d = doc.data()
                let rem = Reminder(
                    id: UUID(uuidString: doc.documentID) ?? UUID(),
                    name: d["title"] as? String ?? "", // Исправлено на name
                    date: (d["date"] as? Timestamp)?.dateValue() ?? Date()
                )
             //   rem.ownerUserRecordID = uid
                modelContext.insert(rem)
            }

            // 6) ASSETS
            let assetSnap = try await userRoot.collection("assets").getDocuments()
            for doc in assetSnap.documents {
                let d = doc.data()
                let asset = Asset(
                    id: UUID(uuidString: doc.documentID) ?? UUID(),
                    name: d["name"] as? String ?? "",
                    price: d["price"] as? Double ?? 0
                )
                // Убрано присваивание ownerUserRecordID, так как его нет в Asset
                modelContext.insert(asset)
            }

            await MainActor.run {
                try? modelContext.save()
            }
        } catch {
            print("❌ Ошибка загрузки из Firestore: \(error)")
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
      case emailExists
      case invalidEmail
      case weakPassword
      case unknown

      var errorDescription: String? {
        switch self {
          case .userNotFound:   return "Пользователь не найден."
          case .wrongPassword:  return "Неверный пароль."
          case .emptyFields:    return "Заполните все поля."
          case .emailExists:    return "Пользователь с таким e-mail уже зарегистрирован."
          case .invalidEmail:   return "Неправильный формат e-mail."
          case .weakPassword:   return "Пароль слишком простой."
          case .unknown:        return "Неизвестная ошибка."
        }
      }
    }
}
