import SwiftUI
import SwiftData

let supportedCurrencies: [String] = [
    "RUB",
    "USD",
    "EUR",
    "GBP",
    "JPY",
    "CNY"
]

struct AccountsScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var accounts: [Account]

    @State private var isShowingAddAccountSheet = false
    @State private var accountToEdit: Account? = nil

    var body: some View {
        NavigationStack {
            List {
                ForEach(accounts) { account in
                    accountRow(for: account) {
                        // убрали внутреннюю кнопку — редактим через свайп
                    }
                    .frame(height: 76)
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    // ── Свайп для редактирования и удаления ───────────────────
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        // Удалить
                        Button(role: .destructive) {
                            deleteAccount(account)
                        } label: {
                            Label("Удалить", systemImage: "trash")
                        }
                        // Редактировать
                        Button {
                            accountToEdit = account
                        } label: {
                            Label("Изменить", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
                .onDelete { offsets in
                    offsets.map { accounts[$0] }.forEach { deleteAccount($0) }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(.systemGray6))

            Button(action: { isShowingAddAccountSheet = true }) {
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
            .navigationTitle("Счета")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EmptyView()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { isShowingAddAccountSheet = true } label: {
                        Image(systemName: "plus").foregroundColor(.appPurple)
                    }
                }
            }
            .sheet(isPresented: $isShowingAddAccountSheet) {
                AccountCreationView(modelContext: modelContext)
            }
            .sheet(item: $accountToEdit) { editingAccount in
                AccountEditView(account: editingAccount) {
                    accountToEdit = nil
                }
                .environment(\.modelContext, modelContext)
            }
        }
    }

    @ViewBuilder
    private func accountRow(
        for account: Account,
        onEditTap: @escaping () -> Void
    ) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .foregroundColor(.clear)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.16), radius: 16, x: 3, y: 6)
                .frame(height: 76)

            HStack(spacing: 12) {
                // Бейдж валюты
                ZStack {
                    Circle()
                        .strokeBorder(Color.appPurple, lineWidth: 7)
                        .background(Circle().foregroundColor(Color.lightPurprApple))
                        .frame(width: 44, height: 44)
                    Text(currencySymbols[account.currency ?? ""] ?? "")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.leading, 8)

                // Название и код
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.name)
                        .font(.body).fontWeight(.medium)
                        .foregroundColor(.primary)
                    Text(account.currency ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Баланс
                Text(account.formattedBalance)
                    .font(.body).fontWeight(.medium)
                    .foregroundStyle(account.balance < 0 ? .red : .primary)
                    .padding(.trailing, 12)
            }
        }
        .contextMenu {
            Button {
                onEditTap()
            } label: {
                Label("Редактировать", systemImage: "pencil")
            }

            Divider()
            Button(role: .destructive) {
                deleteAccount(account)
            } label: {
                Label("Удалить", systemImage: "trash")
            }
        }
    }

    private func deleteAccount(_ account: Account) {
        for tx in account.transactions { modelContext.delete(tx) }
        for cat in account.categories { modelContext.delete(cat) }
        modelContext.delete(account)
        try? modelContext.save()
    }
}


// MARK: — AccountCreationView (без изменений)
struct AccountCreationView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var accountName: String = ""
    @State private var initialBalanceText: String = ""
    @State private var selectedCurrency: String = "RUB"

    let modelContext: ModelContext

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .strokeBorder(Color.appPurple, lineWidth: 9)
                            .background(Circle().foregroundColor(.lightPurprApple))
                            .frame(width: 58, height: 58)
                        Text(currencySymbols[selectedCurrency] ?? "")
                            .font(.system(size: 28, weight: .heavy))
                            .foregroundColor(.white)
                    }
                }
                .padding(.top, 8)

                Form {
                    Section {
                        TextField("Название счета", text: $accountName)
                    }

                    Section {
                        HStack {
                            Text("Валюта")
                            Spacer()
                            Picker(selection: $selectedCurrency) {
                                ForEach(supportedCurrencies, id: \.self) { code in
                                    HStack {
                                        Text("\(currencySymbols[code] ?? "") \(code)")
                                    }
                                    .tag(code)
                                }
                            } label: { Text("") }
                            .pickerStyle(.menu)
                            .tint(.gray)
                        }

                        HStack {
                            Text("Начальный баланс")
                            Spacer()
                            TextField("0", text: $initialBalanceText)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                                .frame(width: 100)
                            Text(currencySymbols[selectedCurrency] ?? "")
                                .padding(.leading, 4)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Новый счет")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                        .foregroundColor(.appPurple)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        addAccount()
                        dismiss()
                    }
                    .foregroundColor(accountName.isEmpty ? .gray : .appPurple)
                    .disabled(accountName.isEmpty)
                }
            }
        }
    }

    private func addAccount() {
        let initialBalanceValue: Double? = {
            let normalized = initialBalanceText.replacingOccurrences(of: ",", with: ".")
            return Double(normalized)
        }()

        let newAccount = Account(
            name: accountName,
            currency: selectedCurrency,
            initialBalance: initialBalanceValue
        )
        modelContext.insert(newAccount)
        Category.seedDefaults(for: newAccount, in: modelContext)

        do { try modelContext.save() }
        catch { print("Ошибка при сохранении нового счета: \(error.localizedDescription)") }
    }
}
