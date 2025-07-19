import SwiftUI

struct PasswordResetSentView: View {
    let email: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()

            VStack(spacing: 28) {
                // Иконка с галочкой
                ZStack {
                    Circle()
                        .fill(Color.appPurple.opacity(0.12))
                        .frame(width: 120, height: 120)
                    Image(systemName: "envelope.badge.checkmark.fill")
                        .symbolRenderingMode(.hierarchical)
                        .font(.system(size: 56))
                        .foregroundColor(.appPurple)
                }
                .padding(.top, 40)

                VStack(spacing: 8) {
                    Text("Ссылка отправлена!")
                        .font(.title2.bold())
                        .foregroundColor(.primary)

                    Text("Мы отправили письмо на ваш e-mail.\nПерейдите по ссылке, чтобы сбросить пароль.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }

                // Кнопка «Открыть почту»
                Button(action: openMailApp) {
                    Text("Открыть почту")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.appPurple)
                        .foregroundColor(.white)
                        .font(.headline)
                        .cornerRadius(16)
                }
                .padding(.top, 8)

                VStack(spacing: 4) {
                    Text("Не нашли письмо?")
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    Text("Проверьте папку «Спам» или подождите пару минут.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.top, 4)

                Spacer()

                // Можно дать кнопку «Вернуться» (опционально)
                Button(role: .cancel) {
                    // Закроем стек до корня (если нужно несколько раз dismiss)
                    dismiss()
                } label: {
                    Text("Готово")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
        }
        .navigationBarBackButtonHidden(true)
    }

    private func openMailApp() {
        // Пытаемся открыть стандартное приложение «Почта»
        // scheme "message:" не даёт просто открыть инбокс — используем "mailto:"
        if let url = URL(string: "message://") , UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let mailto = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(mailto)
        }
    }
}
