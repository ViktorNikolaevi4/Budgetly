import SwiftUI
import CloudKit
import AuthenticationServices


struct RegistrationView: View {
    let onSwitchToLogin: () -> Void
    @Environment(\.authService) private var auth

    @State private var name      = ""
    @State private var email     = ""
    @State private var password  = ""
    @State private var isLoading = false
    @State private var alertMsg  = ""
    @State private var showAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        Spacer().frame(height: 40)
                        IconTextField(
                            systemImage: "person.fill",
                            placeholder: "Имя или никнейм",
                            text: $name
                        )
                        IconTextField(
                            systemImage: "envelope.fill",
                            placeholder: "Ваш e‑mail",
                            text: $email,
                            keyboard: .emailAddress,
                            contentType: .emailAddress
                        )
                        IconTextField(
                            systemImage: "lock.fill",
                            placeholder: "Пароль",
                            text: $password,
                            isSecure: true,
                            contentType: .password
                        )

                        if isLoading {
                            ProgressView().padding(.top, 12)
                        } else {
                            Button(action: signUp) {
                                Text("Регистрация")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.appPurple)
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                            }
                            .disabled(name.isEmpty || email.isEmpty || password.isEmpty)
                        }

                        Button("Войти") {
                            onSwitchToLogin()
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(.appPurple)
                        .padding(.top, 8)

                        Text("или")
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)

                        SignInWithAppleButton(
                            .signUp,
                            onRequest: { req in req.requestedScopes = [.fullName, .email] },
                            onCompletion: handleApple
                        )
                        .signInWithAppleButtonStyle(.whiteOutline)
                        .frame(height: 44)
                        .cornerRadius(16)

                        Spacer()
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationTitle("Регистрация")
            .alert(alertMsg, isPresented: $showAlert) {
                Button("OK") { }
            }
        }
    }

    private func signUp() {
        isLoading = true
        auth.signUp(name: name, email: email, password: password) { result in
            isLoading = false
            switch result {
            case .success:
                onSwitchToLogin()  // после успешной регистрации сразу переключаем на Login или dismiss
            case .failure(let err):
                alertMsg  = err.errorDescription ?? "Ошибка регистрации"
                showAlert = true
            }
        }
    }

    private func handleApple(result: Result<ASAuthorization, Error>) {
        switch result {
        case .failure(let err):
            alertMsg  = err.localizedDescription
            showAlert = true
        case .success(let res):
            guard let cred = res.credential as? ASAuthorizationAppleIDCredential else { return }
            isLoading = true
            auth.signInWithApple(credential: cred) { res in
                isLoading = false
                switch res {
                case .success:
                    onSwitchToLogin()
                case .failure(let err):
                    alertMsg  = err.errorDescription ?? "Ошибка Apple Sign‑In"
                    showAlert = true
                }
            }
        }
    }
}

struct IconTextField: View {
    let systemImage: String
    let placeholder: String
    @Binding var text: String

    var keyboard: UIKeyboardType = .default
    var isSecure: Bool = false
    var contentType: UITextContentType? = nil
    var isError: Bool = false

    @State private var isSecured: Bool = true
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundColor(.appPurple)

            if isSecure {
                Group {
                    if isSecured {
                        SecureField(placeholder, text: $text)
                            .textContentType(contentType)
                    } else {
                        TextField(placeholder, text: $text)
                            .textContentType(contentType)
                    }
                }
                .keyboardType(keyboard)
                .focused($focused)

                Button {
                    isSecured.toggle()
                } label: {
                    Image(systemName: isSecured ? "eye.slash" : "eye")
                        .foregroundColor(.secondary)
                }
                .animation(.none, value: isSecured)

            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboard)
                    .textContentType(contentType)
                    .focused($focused)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    // если isError — красная рамка,
                    // иначе, если фокус или есть текст — пурпурная,
                    // иначе прозрачная
                    isError
                      ? Color.red
                      : (focused || !text.isEmpty)
                        ? Color.appPurple
                        : Color.clear,
                    lineWidth: 2
                )
        )
    }
}


