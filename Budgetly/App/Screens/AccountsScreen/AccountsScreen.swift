import SwiftUI
import SwiftData

// MARK: — константы для валют
let supportedCurrencies: [String] = ["RUB","USD","EUR","GBP","JPY","CNY"]


struct AccountsScreen: View {
    @Environment(\.modelContext) private var modelContext

    // Режим редактирования списка
    @State private var editMode: EditMode = .inactive
    // Для показа sheet
    @State private var isShowingAddAccountSheet = false
    // Для отложенного удаления
    @State private var pendingDeleteOffsets: IndexSet = []
    @State private var showDeleteAlert = false

    // Сортируем по sortOrder
    @Query(sort: \Account.sortOrder, order: .forward)
    private var accounts: [Account]

    var body: some View {
        NavigationStack {
            List {
                ForEach(accounts) { account in
                    NavigationLink {
                        AccountEditView(account: account) { }
                            .environment(\.modelContext, modelContext)
                    } label: {
                        accountRow(for: account)
                            .frame(height: 76)
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                    }
                }
                // вернули минусы
                .onDelete { offsets in
                    pendingDeleteOffsets = offsets
                    showDeleteAlert = true
                }
                // хваталки для перетаскивания
                .onMove { indices, newOffset in
                    var reordered = accounts
                    reordered.move(fromOffsets: indices, toOffset: newOffset)
                    for (i, acc) in reordered.enumerated() {
                        acc.sortOrder = i
                    }
                    try? modelContext.save()
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(.systemGray6))
            // прокидываем режим редактирования, чтобы List знал о нем
            .environment(\.editMode, $editMode)

            // кнопка «Добавить»
            Button("Добавить новый счет") {
                isShowingAddAccountSheet = true
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.appPurple)
            .foregroundColor(.white)
            .cornerRadius(16)
            .padding(.horizontal)
            .padding(.bottom, 20)

            .navigationTitle("Счета")
            .toolbar {
                // левая кнопка: Править<->Готово
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(editMode.isEditing ? "Готово" : "Править") {
                        withAnimation {
                            editMode = editMode.isEditing ? .inactive : .active
                        }
                    }
                    .foregroundColor(.appPurple)
                }
                // правая кнопка: +
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { isShowingAddAccountSheet = true } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.appPurple)
                    }
                }
            }
            .sheet(isPresented: $isShowingAddAccountSheet) {
                AccountCreationView(modelContext: modelContext)
            }
            // алерт подтверждения удаления
            .alert("Удалить выбранный счет?", isPresented: $showDeleteAlert) {
                Button("Удалить", role: .destructive) {
                    performPendingDelete()
                }
                Button("Отмена", role: .cancel) {
                    pendingDeleteOffsets = []
                }
            } message: {
                Text("Все связанные транзакции и категории будут удалены без возможности восстановления.")
            }
        }
    }

    private func performPendingDelete() {
        for idx in pendingDeleteOffsets {
            let account = accounts[idx]
            // удаляем связанные транзакции и категории
            for tx in account.transactions { modelContext.delete(tx) }
            for cat in account.categories  { modelContext.delete(cat) }
            modelContext.delete(account)
        }
        pendingDeleteOffsets = []
        try? modelContext.save()
    }

    @ViewBuilder
    private func accountRow(for account: Account) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .foregroundColor(.clear)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.16), radius: 16, x: 3, y: 6)

            HStack(spacing: 12) {
                // бейдж валюты
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

                // название и код
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.name)
                        .font(.body).fontWeight(.medium)
                        .foregroundColor(.primary)
                    Text(account.currency ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // баланс
                Text(account.formattedBalance)
                    .font(.body).fontWeight(.medium)
                    .foregroundStyle(account.balance < 0 ? .red : .primary)
                    .padding(.trailing, 12)
            }
        }
    }
}

// MARK: — экран создания (тот же, что у вас был)
struct AccountCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var accountName = ""
    @State private var initialBalanceText = ""
    @State private var selectedCurrency = "RUB"
    let modelContext: ModelContext

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // бейдж валюты
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
                            Text("Валюта"); Spacer()
                            Picker("", selection: $selectedCurrency) {
                                ForEach(supportedCurrencies, id: \.self) { code in
                                    Text("\(currencySymbols[code]!) \(code)")
                                        .tag(code)
                                }
                            }
                            .pickerStyle(.menu).tint(.gray)
                        }
                        HStack {
                            Text("Начальный баланс"); Spacer()
                            TextField("0", text: $initialBalanceText)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                                .frame(width: 100)
                            Text(currencySymbols[selectedCurrency]!)
                                .padding(.leading, 4)
                        }
                    }
                }
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
                    .disabled(accountName.isEmpty)
                    .foregroundColor(accountName.isEmpty ? .gray : .appPurple)
                }
            }
        }
    }

    private func addAccount() {
        let bal: Double? = {
            let norm = initialBalanceText.replacingOccurrences(of: ",", with: ".")
            return Double(norm)
        }()
        // вставляем новый со вторым параметром sortOrder = текущий count
        let newAcc = Account(
            name: accountName,
            currency: selectedCurrency,
            initialBalance: bal,
            sortOrder: accountsCount()
        )
        modelContext.insert(newAcc)
        Category.seedDefaults(for: newAcc, in: modelContext)
        try? modelContext.save()
    }

    // helper
    private func accountsCount() -> Int {
        // Query недоступен здесь, но можно сделать fetch:
        let fetch = FetchDescriptor<Account>(sortBy: [])
        let all = (try? modelContext.fetch(fetch)) ?? []
        return all.count
    }
}

