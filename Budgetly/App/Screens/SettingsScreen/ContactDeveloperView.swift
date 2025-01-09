import SwiftUI
import MessageUI

struct ContactDeveloperView: View {
    @State private var subject: String = ""
    @State private var email: String = ""
    @State private var message: String = ""
    @State private var showMailComposer = false
    @State private var showMailErrorAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField("Тема сообщения", text: $subject)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                TextField("Электронная почта", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)

                TextField("Текст сообщения", text: $message, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minHeight: 100) // Увеличиваем высоту
                    .padding()

                HStack {
                    Button("Очистить") {
                        subject = ""
                        email = ""
                        message = ""
                    }
                    .foregroundColor(.red)
                    .padding()

                    Button(action: {
                        if MFMailComposeViewController.canSendMail() {
                            showMailComposer = true
                        } else {
                            showMailErrorAlert = true
                        }
                    }) {
                        Text("Отправить")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(!subject.isEmpty && !email.isEmpty && !message.isEmpty ? Color.yellow : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(subject.isEmpty || email.isEmpty || message.isEmpty || !isValidEmail(email))
                    .padding()
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Связаться с разработчиком")
            .sheet(isPresented: $showMailComposer) {
                MailComposerView(
                    subject: subject,
                    recipient: "87v87@mail.ru", // Ваша почта
                    messageBody: message,
                    senderEmail: email
                )
            }
            .alert("Ошибка", isPresented: $showMailErrorAlert) {
                Button("Копировать адрес") {
                    UIPasteboard.general.string = "87v87@mail.ru" // Замените на ваш email
                }
                Button("Закрыть", role: .cancel) {}
            } message: {
                Text("Убедитесь, что на устройстве настроен почтовый клиент.")
            }

        }
    }

    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}
