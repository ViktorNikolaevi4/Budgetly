import SwiftUI
import SwiftData

struct AccountsScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var accounts: [Account]
    @State private var isShowingAddAccountSheet = false

    var body: some View {
        NavigationStack {
            VStack {
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

                                HStack {
                                    // Название счёта слева
                                    Text(account.name)
                                        .fontWeight(.medium)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .padding(.leading)

                                    Spacer()

                                    // Баланс счёта справа
                                    Text(account.formattedBalance)
                                        .fontWeight(.medium)
                                        .font(.body)
                                        .foregroundStyle(account.balance < 0 ? .red : .primary)
                                        .padding(.trailing)
                                }
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

                    // MARK: - Текст и иконка с глазом
                    HStack(spacing: 8) {
                        Image(systemName: "eye.fill")
                            .foregroundColor(.gray)
                        Text("Показать скрытые счета")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 8)
                }

                // MARK: - Кнопка добавления нового счёта
                Button(action: {
                    isShowingAddAccountSheet = true
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
            }
            .navigationTitle("Счета")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        isShowingAddAccountSheet = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.appPurple)
                    }
                }
            }
            .sheet(isPresented: $isShowingAddAccountSheet) {
                AccountCreationView(modelContext: modelContext)
            }
            .background(Color(.systemGray6).ignoresSafeArea())
        }
    }
}

struct AccountCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var accountName: String = ""
    let modelContext: ModelContext

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField("Название счета", text: $accountName)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.clear, lineWidth: 0)
                    )
                    .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Новый счет")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }.foregroundStyle(.appPurple)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        addAccount()
                        dismiss()
                    }.foregroundStyle(.appPurple)
                    .disabled(accountName.isEmpty)
                }
            }
            .background(Color(.systemGray6).ignoresSafeArea())
        }
    }

    // MARK: - Метод для создания нового счёта
    private func addAccount() {
        let newAccount = Account(name: accountName)
        modelContext.insert(newAccount)
        Category.seedDefaults(for: newAccount, in: modelContext)
    }
}
