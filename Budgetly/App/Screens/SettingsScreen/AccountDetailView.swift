import SwiftUI
import SwiftData

struct AccountDetailView: View {
    @Environment(\.authService)    private var auth
    @Environment(\.modelContext)   private var context
    @Environment(\.dismiss)        private var dismiss

    // Подхватываем все модели, чтобы при удалении чистить их
    @Query private var accountsList:   [Account]
    @Query private var transactions:   [Transaction]
    @Query private var assets:         [Asset]

    var body: some View {
        List {
            Section {
                HStack {
                    Text("Имя / никнейм")
                    Spacer()
                    Text(auth.currentName ?? "-")
                        .foregroundColor(.secondary)
                }
            }

            Section {
                HStack {
                    Text("E-mail")
                    Spacer()
                    Text(auth.currentEmail ?? "-")
                        .foregroundColor(.secondary)
                }
            }

            Section {
                NavigationLink("Изменить пароль") {
                    ForgotPasswordView()
                }
            }

            Section {
                Button(role: .destructive, action: deleteAccount) {
                    Text("Удалить аккаунт")
                }
                Text("Если вы решите удалить аккаунт, все ваши операции, счета и активы будут удалены без возможности восстановления.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }
        }
        .navigationTitle("Аккаунт и вход")
        .listStyle(.insetGrouped)
    }

    private func deleteAccount() {
        // 1) Логаут и очистка ключей
        auth.logout()

        // 2) Удаляем все записи SwiftData
        for acc in accountsList   { context.delete(acc) }
        for tx  in transactions   { context.delete(tx)  }
        for asset in assets       { context.delete(asset) }

        // 3) Сохраняем контекст (необязательно, т.к. SwiftData auto-commit)
        // try? context.save()

        // 4) Возвращаемся назад
        dismiss()
    }
}
