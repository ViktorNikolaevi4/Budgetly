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
    @State private var passwordError: String? = nil

    @Environment(\.authService) private var authService

    private var isFormValid: Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty
    }
    var onSwitchToLogin: (() -> Void)? = nil

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
                        isSecure: false,
                        contentType: .username
                    )

                    IconTextField(
                        systemImage: "envelope.fill",
                        placeholder: "Ваш e-mail",
                        text: $email,
                        keyboard: .emailAddress,
                        isSecure: false,
                        contentType: .emailAddress,
                        isError: false
                    )

                    IconTextField(
                        systemImage: "lock.fill",
                        placeholder: "Пароль",
                        text: $password,
                        keyboard: .default,
                        isSecure: true,
                        contentType: .password,
                        isError: passwordError != nil
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
                                .opacity(isFormValid ? 1.0 : 0.6)
                        }
                        .disabled(!isFormValid)
                        .padding(.top, 16)
                    }

                    Button(action: {
                        onSwitchToLogin?()
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
                    authService.register(email: email, password: password)
                    _ = authService.login(email: email, password: password)
//                    alertMessage = "Регистрация успешна!"
//                    showAlert = true
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
struct IconTextField: View {
    let systemImage: String
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var isSecure: Bool = false
    var contentType: UITextContentType? = nil   // можно передавать .emailAddress, .password и т.п.
    var isError: Bool = false

    // локальный стейт «показать/скрыть»
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
                            .textContentType(contentType)
                            .focused($isFocused)
                    } else {
                        TextField(placeholder, text: $text)
                            .textContentType(contentType)
                            .focused($isFocused)
                            .autocapitalization(.none)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                    }
                }
                .keyboardType(keyboard)

                Button {
                    isSecuredText.toggle()
                } label: {
                    Image(systemName: isSecuredText ? "eye.slash" : "eye")
                        .foregroundColor(.secondary)
                }
                .animation(.none, value: isSecuredText) // чтобы размер не «прыгал»
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboard)
                    .textContentType(contentType)
                    .autocapitalization(.none)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .focused($isFocused)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isError ? Color.red :
                    (isFocused || !text.isEmpty) ? Color.appPurple : Color.clear,
                    lineWidth: 2
                )
        )
    }
}
