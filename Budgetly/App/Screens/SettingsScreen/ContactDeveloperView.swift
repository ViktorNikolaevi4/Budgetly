import SwiftUI
import MessageUI

struct ContactDeveloperView: View {
    @State private var subject = ""
    @State private var email = ""
    @State private var message = ""
    @State private var showMailComposer = false
    @State private var showMailErrorAlert = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme // Определение текущей темы

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground) // Адаптивный фон (белый для светлой, тёмный для тёмной)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Заголовок
                    Text("Связаться с разработчиком")
                        .font(.title2).bold()
                        .foregroundStyle(.primary) // Адаптивный цвет текста
                        .padding(.top, 8)

                    // Поля
                    VStack(spacing: 16) {
                        StyledTextField(
                            placeholder: "Тема сообщения",
                            text: $subject
                        )
                        StyledTextField(
                            placeholder: "Электронная почта",
                            text: $email,
                            keyboard: .emailAddress
                        )
                        StyledTextEditor(
                            placeholder: "Текст сообщения",
                            text: $message
                        )
                        .frame(minHeight: 120)
                    }
                    .padding(.horizontal)

                    Spacer()

                    // Кнопки
                    HStack(spacing: 16) {
                        Button("Очистить") {
                            subject = ""
                            email = ""
                            message = ""
                        }
                        .font(.body.bold())
                        .foregroundColor(.red) // Красный цвет остаётся, но можно адаптировать

                        Button("Отправить") {
                            if MFMailComposeViewController.canSendMail() {
                                showMailComposer = true
                            } else {
                                showMailErrorAlert = true
                            }
                        }
                        .font(.body.bold())
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(
                            (!subject.isEmpty && isValidEmail(email) && !message.isEmpty)
                            ? Color("AppPurple", bundle: nil) // Адаптивный цвет из Asset Catalog
                            : Color.gray.opacity(colorScheme == .dark ? 0.7 : 0.5) // Адаптация серого для тёмной темы
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .disabled(subject.isEmpty || !isValidEmail(email) || message.isEmpty)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            // крестик в навигейшн баре
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(Color("AppPurple", bundle: nil)) // Адаптивный цвет
                    }
                }
            }
            // mail composer sheet с onDismiss
            .sheet(
                isPresented: $showMailComposer,
                onDismiss: {
                    // очищаем поля после закрытия шита
                    subject = ""
                    email = ""
                    message = ""
                }
            ) {
                MailComposerView(
                    isPresented: $showMailComposer,
                    subject: subject,
                    recipient: "87v87@mail.ru",
                    messageBody: message,
                    senderEmail: email
                )
            }
            // алерт, если почта не настроена
            .alert("Ошибка", isPresented: $showMailErrorAlert) {
                Button("Копировать адрес") {
                    UIPasteboard.general.string = "87v87@mail.ru"
                }
                Button("Закрыть", role: .cancel) {}
            } message: {
                Text("Настройте почту на устройстве или скопируйте адрес вручную.")
            }
        } // NavigationStack
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", pattern)
            .evaluate(with: email)
    }
}

// MARK: – Стили для TextField / TextEditor

struct StyledTextField: View {
    var placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    @Environment(\.colorScheme) private var colorScheme // Определение текущей темы

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboard)
            .autocapitalization(keyboard == .emailAddress ? .none : .sentences)
            .padding(14)
            .background(Color(.systemBackground)) // Адаптивный фон полей
            .foregroundStyle(.primary) // Адаптивный цвет текста
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2), lineWidth: 1) // Граница для видимости
            )
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.1 : 0.05), radius: 4, x: 0, y: 2) // Лёгкая адаптация тени
    }
}

struct StyledTextEditor: View {
    var placeholder: String
    @Binding var text: String
    @Environment(\.colorScheme) private var colorScheme // Определение текущей темы

    // Показывать плейсхолдер, когда текст пуст
    @State private var showPlaceholder = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.gray.opacity(colorScheme == .dark ? 0.5 : 0.6)) // Адаптация цвета плейсхолдера
                    .padding(18)
            }
            TextEditor(text: $text)
                .padding(12)
                .background(Color(.systemBackground)) // Адаптивный фон
                .foregroundStyle(.primary) // Адаптивный цвет текста
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2), lineWidth: 1) // Граница для видимости
                )
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.1 : 0.05), radius: 4, x: 0, y: 2) // Лёгкая адаптация тени
        }
    }
}
