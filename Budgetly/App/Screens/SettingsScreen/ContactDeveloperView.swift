import SwiftUI
import MessageUI

struct ContactDeveloperView: View {
    // MARK: – State
    @State private var subject: String = ""
    @State private var email: String = ""
    @State private var message: String = ""
    @State private var showMailComposer = false
    @State private var showMailErrorAlert = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Общий светло-серый фон
            Color("BackgroundLightGray")
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Заголовок
                Text("Связаться с разработчиком")
                    .font(.title2).bold()
                    .padding(.top, 8)

                // Поля ввода
                VStack(spacing: 16) {
                    StyledTextField(placeholder: "Тема сообщения", text: $subject)
                    StyledTextField(placeholder: "Электронная почта", text: $email, keyboard: .emailAddress)
                    StyledTextEditor(placeholder: "Текст сообщения", text: $message)
                        .frame(minHeight: 120)
                }
                .padding(.horizontal)

                Spacer()

                // Кнопки Очистить / Отправить
                HStack(spacing: 16) {
                    Button("Очистить") {
                        subject = ""; email = ""; message = ""
                    }
                    .font(.body.bold())
                    .foregroundColor(.red)

                    Button("Отправить") {
                        if MFMailComposeViewController.canSendMail() {
                            showMailComposer = true
                        } else {
                            showMailErrorAlert = true
                        }
                    }
                    .font(.body.bold())
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background((!subject.isEmpty && isValidEmail(email) && !message.isEmpty)
                                ? Color.appPurple
                                : Color.gray.opacity(0.5))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(subject.isEmpty || !isValidEmail(email) || message.isEmpty)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showMailComposer) {
            MailComposerView(
                subject: subject,
                recipient: "87v87@mail.ru",
                messageBody: message,
                senderEmail: email
            )
        }
        .alert("Ошибка", isPresented: $showMailErrorAlert) {
            Button("Копировать адрес") {
                UIPasteboard.general.string = "87v87@mail.ru"
            }
            Button("Закрыть", role: .cancel) {}
        } message: {
            Text("Ваше устройство не настроено для отправки почты. Можно скопировать адрес и отправить вручную.")
        }
    }

    // Простая валидация e-mail
    private func isValidEmail(_ email: String) -> Bool {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: email)
    }
}

// MARK: – Стили для TextField / TextEditor

struct StyledTextField: View {
    var placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboard)
            .autocapitalization(keyboard == .emailAddress ? .none : .sentences)
            .padding(14)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct StyledTextEditor: View {
    var placeholder: String
    @Binding var text: String

    // Показывать плейсхолдер, когда текст пуст
    @State private var showPlaceholder = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.gray.opacity(0.6))
                    .padding(18)
            }
            TextEditor(text: $text)
                .padding(12)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}
