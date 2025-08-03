import SwiftUI
import AuthenticationServices
import Observation
import SwiftData

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.authService)      private var auth
    @Environment(\.modelContext) private var modelContext

    let onSwitchToRegister: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var emailError: String? = nil
    @State private var passwordError: String? = nil
    @State private var showForgot = false

    @FocusState private var focused: Field?
    enum Field { case email, password }

    private var formValid: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6).ignoresSafeArea()
                VStack(spacing: 12) {
                    Spacer().frame(height: 40)

                    IconTextField(
                        systemImage: "envelope.fill",
                        placeholder: "Ваш e‑mail",
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
                            showForgot = true
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
                        onSwitchToRegister()
                    }
                    .foregroundColor(.appPurple)
                    .font(.subheadline.bold())
                    .padding(.top, 8)

                    Text("или")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                        .padding(.vertical, 4)
                        .padding(.top, 18)

                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            print("🍎 Apple onRequest")
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            print("🍎 Apple onCompletion:", result)
                            handleApple(result: result)
                        }
                    )
                    .signInWithAppleButtonStyle(.whiteOutline)
                    .frame(height: 44)
                    .cornerRadius(16)

                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("Вход")
            .alert(alertMessage, isPresented: $showAlert) {
                Button("OK") { }
            }
            .navigationDestination(isPresented: $showForgot) {
                ForgotPasswordView()
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

    private func handleApple(result: Result<ASAuthorization, Error>) {
        switch result {
        case .failure(let err):
            alertMessage = err.localizedDescription
            showAlert = true

        case .success(let authResults):
            guard let cred = authResults.credential as? ASAuthorizationAppleIDCredential else {
                alertMessage = "Что-то пошло не так в Apple Sign In"
                showAlert = true
                return
            }

            isLoading = true
            auth.signInWithApple(credential: cred, modelContext: modelContext) { authResult in
                isLoading = false

                switch authResult {
                case .success:
                    dismiss()
                case .failure(let err):
                    alertMessage = err.errorDescription ?? "Ошибка Apple Sign-In"
                    showAlert = true
                }
            }
        }
    }

    private func login() {
      guard formValid else { return }
      emailError = nil
      passwordError = nil
      isLoading = true

      auth.login(
        email: email,
        password: password,
        modelContext: modelContext   // ← здесь прокинули контекст
      ) { result in
        // Обязательно назад на main, чтобы обновить UI
        DispatchQueue.main.async {
          isLoading = false
          switch result {
          case .success:
            dismiss()

          case .failure(let err):
              switch err {
              case .userNotFound:
                  emailError = "Не удалось найти такой e-mail."
              case .wrongPassword:
                  passwordError = "Пароль неверный."
              case .emptyFields:
                  if email.isEmpty    { emailError    = "Введите e-mail" }
                  if password.isEmpty { passwordError = "Введите пароль" }
              case .emailExists:
                  alertMessage = err.errorDescription!
                  showAlert    = true
              case .invalidEmail:
                  emailError   = err.errorDescription
              case .weakPassword:
                  passwordError = err.errorDescription
              case .unknown:
                  alertMessage = err.errorDescription ?? "Неизвестная ошибка"
                  showAlert    = true
              @unknown default:
                  alertMessage = err.errorDescription ?? "Неизвестная ошибка"
                  showAlert    = true
              }

          }
        }
      }
    }
}

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.authService) private var auth
    @Environment(\.modelContext) private var modelContext

    @State private var email: String = ""
    @State private var isSending: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var emailError: String? = nil
    @State private var showSent = false

    

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "envelope.open.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.appPurple)
                        .padding(.top, 8)

                    VStack(spacing: 4) {
                        Text("Введите e-mail, с которым вы регистрировались —")
                        Text("мы пришлём ссылку для сброса пароля.")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)

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
                            .padding(.top, -12)
                    }

                    Button {
                      Task {
                        await sendReset()
                      }
                    } label: {
                      if isSending {
                        ProgressView().frame(maxWidth: .infinity).padding(.vertical, 14)
                      } else {
                            Text("Отправить ссылку")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                    }
                    .background(Color.appPurple)
                    .foregroundColor(.white)
                    .font(.headline)
                    .cornerRadius(16)
                    .opacity(isFormValid ? 1 : 0.6)
                    .disabled(!isFormValid || isSending)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .navigationTitle("Забыли пароль?")
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(isPresented: $showSent) {
                    PasswordResetSentView(email: email)
                }
            }
        }
        .alert(alertMessage, isPresented: $showAlert) {
          Button("OK") {
            // если успешно — уходим назад
            if alertMessage.contains("отправлена") {
              dismiss()
            }
          }
        }
      }

    private var isFormValid: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        isValidEmail(email)
    }

    private func isValidEmail(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }

    private func sendReset() async {
        guard isFormValid else {
          emailError = email.isEmpty ? "Введите e-mail" : "Некорректный e-mail"
          return
        }
        emailError = nil
        isSending = true

        do {
          try await auth.sendPasswordReset(email: email)
          alertMessage = "📧 Ссылка для сброса пароля отправлена на \(email)."
        } catch let err as AuthService.AuthError {
          switch err {
          case .emptyFields:
            alertMessage = "Введите корректный e-mail."
          case .userNotFound:
            alertMessage = "Пользователь с таким e-mail не найден."
          default:
            alertMessage = err.errorDescription ?? "Не удалось отправить ссылку."
          }
        } catch {
          alertMessage = error.localizedDescription
        }

        isSending = false
        showAlert = true
      }
}
