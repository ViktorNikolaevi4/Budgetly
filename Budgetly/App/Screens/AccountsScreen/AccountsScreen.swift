import SwiftUI
import SwiftData

struct AccountsScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var accounts: [Account]

    @State private var accountName: String = ""
    @State private var isShowingAlert = false

    var body: some View {
        VStack {
            Text("Счета")
                .font(.headline)
                .padding(.top)

            // MARK: - Список счетов в виде карточек с прокруткой
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(accounts) { account in
                        ZStack {
                            RoundedRectangle(cornerRadius: 20.0)
                                .foregroundColor(.clear)
                                .frame(width: 361.0, height: 76.0)
                                .background(Color(white: 1.0))
                                .cornerRadius(20.0)
                                .shadow(color: Color(white: 0.0, opacity: 0.16), radius: 16.0, x: 3.0, y: 6.0)

                            Text(account.name)
                                .font(.body)
                                .foregroundColor(.primary)
                                .padding()
                        }
                        .padding(.horizontal)
                        .contextMenu {
                            Button(role: .destructive) {
                                modelContext.delete(account)
                            } label: {
                                Label("Удалить", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.vertical)
            }

            // MARK: - Кнопка добавления нового счёта
            Button(action: {
                isShowingAlert = true
            }) {
                Text("Добавить новый счет")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.appPurple)
                    .foregroundColor(.white)
                    .cornerRadius(16)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
            .alert("Новый счет", isPresented: $isShowingAlert) {
                TextField("Введите название счета", text: $accountName)
                Button("Создать", action: addAccount)
                Button("Отмена", role: .cancel, action: { accountName = "" })
            }
        }
        .background(Color(.systemGray6).ignoresSafeArea())
    }

    private func addAccount() {
        guard !accountName.isEmpty else { return }
        let newAccount = Account(name: accountName)
        modelContext.insert(newAccount)
        Category.seedDefaults(for: newAccount, in: modelContext)
        accountName = ""
    }
}
