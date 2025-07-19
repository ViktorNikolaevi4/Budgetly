import SwiftUI
import AuthenticationServices
import Observation

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.authService) private var auth

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var passwordError: String? = nil
    @State private var emailError: String? = nil

    @FocusState private var focused: Field?
    enum Field { case email, password }

    private var formValid: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty
    }

    var onSwitchToRegister: (() -> Void)? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6).ignoresSafeArea()
                VStack(spacing: 12) {
                    Spacer().frame(height: 40)

                    IconTextField(
                        systemImage: "envelope.fill",
                        placeholder: "Ваш e-mail",
                        text: $email,
                        keyboard: .emailAddress,
                        isSecure: false,
                        contentType: .emailAddress,
                        isError: emailError != nil
                    )
                    if let emailError {
                        Text(emailError)
                            .font(.caption)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 4)
                    }

                    IconTextField(
                        systemImage: "lock.fill",
                        placeholder: "Пароль",
                        text: $password,
                        keyboard: .default,
                        isSecure: true,
                        contentType: .password,
                        isError: passwordError != nil
                    )

                    if let passwordError {
                        Text(passwordError)
                            .font(.caption)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 4)
                    }

                    HStack {
                        Spacer()
                        Button("Забыли пароль?") {
                            // TODO: Реализация восстановления
                        }
                        .font(.caption)
                        .foregroundColor(.appPurple)
                    }
                    .padding(.top, 4)

                    if isLoading {
                        ProgressView().padding(.top, 12)
                    } else {
                        Button {
                            login()
                        } label: {
                            Text("Войти")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.appPurple)
                                .foregroundColor(.white)
                                .cornerRadius(16)
                                .opacity(formValid ? 1 : 0.6)
                        }
                        .disabled(!formValid)
                        .padding(.top, 8)
                    }

                    Button("Зарегистрироваться") {
                        onSwitchToRegister?()
                    }
                    .foregroundColor(.appPurple)
                    .font(.subheadline.bold())
                    .padding(.top, 8)

                    Text("или")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                        .padding(.vertical, 4)
                        .padding(.top, 18)

                    SignInWithAppleButton(.signIn) { _ in } onCompletion: { _ in }
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 44)
                        .cornerRadius(16)
                        .padding(.top, 16)

                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("Вход")
            .alert(alertMessage, isPresented: $showAlert) {
                Button("OK") { }
            }
        }
        .onChange(of: email) { _ in
            emailError = nil
            passwordError = nil
        }
        .onChange(of: password) { _ in
            passwordError = nil
        }
    }

    private func login() {
        guard formValid else { return }
        emailError = nil
        passwordError = nil
        isLoading = true

        DispatchQueue.global().async {
            let result = auth.login(email: email, password: password)
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success:
                    dismiss()
                case .failure(let err):
                    switch err {
                    case .userNotFound:
                        emailError = "Не удалось найти такой e-mail. Попробуйте ещё раз."
                    case .wrongPassword:
                        passwordError = "Пароль неверный. Попробуйте снова или воспользуйтесь восстановлением."
                    case .emptyFields:
                        // Можно подсветить оба
                        if email.isEmpty { emailError = "Введите e-mail" }
                        if password.isEmpty { passwordError = "Введите пароль" }
                    default:
                        // Общий fallback – через alert
                        alertMessage = err.errorDescription ?? "Ошибка входа."
                        showAlert = true
                    }
                }
            }
        }
    }

}
