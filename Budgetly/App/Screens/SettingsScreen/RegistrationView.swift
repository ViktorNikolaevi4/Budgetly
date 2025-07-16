import SwiftUI
import CloudKit

struct RegistrationView: View {
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Регистрация")
                    .font(.largeTitle)
                    .bold()

                TextField("Имя пользователя", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()

                SecureField("Пароль", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                if isLoading {
                    ProgressView()
                } else {
                    Button(action: handleRegistration) {
                        Text("Зарегистрироваться")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(username.isEmpty || email.isEmpty || password.isEmpty)
                }

                Spacer()
            }
            .padding()
            .alert(alertMessage, isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    /// Основной метод для обработки регистрации
    private func handleRegistration() {
        guard !username.isEmpty, !email.isEmpty, !password.isEmpty else { return }

        // Проверка формата email
        guard isValidEmail(email) else {
            alertMessage = "Некорректный email."
            showAlert = true
            return
        }

        // Проверка уникальности email
        isEmailUnique { isUnique in
            if isUnique {
                // Сохранение пароля в Keychain
                if registerUser(email: email, password: password) {
                    saveUserToCloudKit()
                } else {
                    alertMessage = "Ошибка сохранения пароля."
                    showAlert = true
                }
            } else {
                alertMessage = "Этот email уже зарегистрирован."
                showAlert = true
            }
        }
    }

    /// Проверяет уникальность email в CloudKit
    private func isEmailUnique(completion: @escaping (Bool) -> Void) {
        let predicate = NSPredicate(format: "email == %@", email)
        let query = CKQuery(recordType: "User", predicate: predicate)

        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = 1 // Ограничиваем количество результатов до 1

        var isUnique = true

        // Обрабатываем каждый найденный результат
        operation.recordMatchedBlock = { recordID, result in
            switch result {
            case .success:
                isUnique = false // Если запись найдена, email не уникален
            case .failure(let error):
                print("Ошибка получения записи: \(error.localizedDescription)")
            }
        }

        // Завершающий блок запроса
        operation.queryResultBlock = { result in
            switch result {
            case .success:
                completion(isUnique) // Если нет ошибок, возвращаем результат
            case .failure(let error):
                print("Ошибка выполнения запроса: \(error.localizedDescription)")
                completion(false) // Если произошла ошибка, считаем, что email не уникален
            }
        }

        // Выполняем операцию
        CKContainer.default().publicCloudDatabase.add(operation)
    }



    /// Проверяет правильность формата email
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: email)
    }

    /// Сохраняет данные пользователя в CloudKit
    private func saveUserToCloudKit() {
        isLoading = true
        let record = CKRecord(recordType: "User")
        record["username"] = username
        record["email"] = email

        CKContainer.default().publicCloudDatabase.save(record) { record, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    alertMessage = "Ошибка: \(error.localizedDescription)"
                    showAlert = true
                } else {
                    alertMessage = "Регистрация успешна!"
                    showAlert = true
                }
            }
        }
    }

    /// Сохраняет пароль пользователя в Keychain
    private func registerUser(email: String, password: String) -> Bool {
        if KeychainManager.savePassword(password, for: email) {
            print("Пароль успешно сохранен в Keychain!")
            return true
        } else {
            print("Ошибка при сохранении пароля.")
            return false
        }
    }
}
