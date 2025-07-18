import SwiftUI
import CloudKit
import AuthenticationServices

struct RegistrationView: View {
    @State private var username:     String = ""
    @State private var email:        String = ""
    @State private var password:     String = ""
    @State private var isLoading:    Bool   = false
    @State private var alertMessage: String = ""
    @State private var showAlert:    Bool   = false

    var body: some View {
        NavigationStack {
            ZStack {
                // общий фон, как в grouped-views
                Color(.systemGray6)
                    .ignoresSafeArea()

                VStack(spacing: 12) {
                    Spacer().frame(height: 40)

                    IconTextField(
                        systemImage: "person.fill",
                        placeholder: "Имя или никнейм",
                        text: $username,
                        keyboard: .default,
                        isSecure: false
                    )

                    IconTextField(
                        systemImage: "envelope.fill",
                        placeholder: "Ваш e-mail",
                        text: $email,
                        keyboard: .emailAddress,
                        isSecure: false
                    )

                    IconTextField(
                        systemImage: "lock.fill",
                        placeholder: "Пароль",
                        text: $password,
                        keyboard: .default,
                        isSecure: true
                    )

                    if isLoading {
                        ProgressView()
                            .padding(.top, 16)
                    } else {
                        Button(action: handleRegistration) {
                            Text("Регистрация")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.appPurple)
                                .foregroundColor(.white)
                                .cornerRadius(16)
                        }
                        .disabled(username.isEmpty || email.isEmpty || password.isEmpty)
                        .padding(.top, 16)
                    }

                    Button(action: {
                        // переход на экран входа
                    }) {
                        Text("Войти")
                            .foregroundColor(.appPurple)
                            .font(.subheadline.bold())
                    }
                    .padding(.top, 8)

                    Text("или")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                        .padding(.vertical, 4)
                        .padding(.top, 30)

                    SignInWithAppleButton(.signUp) { request in
                        // конфигурация, если нужно
                    } onCompletion: { result in
                        // обработка результата
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 44)
                    .cornerRadius(16)
                    .padding(.top, 24)

                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("Регистрация")
            .alert(alertMessage, isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            }
        }
    }

    /// Обёртка для полей с иконкой
    struct IconTextField: View {
        let systemImage: String
        let placeholder: String
        @Binding var text: String
        var keyboard: UIKeyboardType = .default
        var isSecure: Bool = false

        // локальный стейт для переключения режима
        @State private var isSecuredText: Bool = true
        @FocusState private var isFocused: Bool

        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .foregroundColor(.appPurple)

                if isSecure {
                    Group {
                        if isSecuredText {
                            SecureField(placeholder, text: $text)
                                .focused($isFocused)
                        } else {
                            TextField(placeholder, text: $text)
                                .autocapitalization(.none)
                                .focused($isFocused)
                        }
                    }
                    .keyboardType(keyboard)
                    .frame(maxWidth: .infinity)
                    .autocapitalization(.none)

                    // кнопка «глазик»
                    Button {
                        isSecuredText.toggle()
                    } label: {
                        Image(systemName: isSecuredText ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                } else {
                    TextField(placeholder, text: $text)
                        .focused($isFocused)
                        .keyboardType(keyboard)
                        .autocapitalization(.none)
                }
            }
            .padding(12)
            .background(Color(.white))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        (isFocused || !text.isEmpty)
                            ? Color.appPurple
                            : Color.clear,
                        lineWidth: 2
                    )
            )
        }
    }

    @Environment(\.dismiss) private var dismiss

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
