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

    // 1) Флаг, отвечающий за показ скрытых счетов
    @State private var showHiddenAccounts = false

    private var visibleAccounts: [Account] {
        accounts.filter { !$0.isHidden }
    }
    private var hiddenAccounts: [Account] {
        accounts.filter { $0.isHidden }
    }

    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // 2) Сначала показываем все "видимые" счета
                        ForEach(visibleAccounts) { account in
                            accountRow(for: account)
                        }

                        // 3) Кнопка "Показать скрытые счета"
                        if !hiddenAccounts.isEmpty {
                            Button(action: {
                                withAnimation {
                                    showHiddenAccounts.toggle()
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: showHiddenAccounts ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                    Text(showHiddenAccounts ? "Скрыть скрытые счета" : "Показать скрытые счета")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 8)
                            }
                            .padding(.horizontal)
                        }

                        // 4) Если пользователь нажал "Показать скрытые счета", отображаем их тут
                        if showHiddenAccounts {
                            ForEach(hiddenAccounts) { account in
                                accountRow(for: account, isHidden: true)
                            }
                        }
                    }
                    .padding(.vertical)
                }

                // 5) Кнопка "Добавить новый счет"
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
            // Sheet для создания нового счета
            .sheet(isPresented: $isShowingAddAccountSheet) {
                AccountCreationView(modelContext: modelContext)
            }
            // Sheet для редактирования (item: binding)
            .sheet(item: $accountToEdit) { editingAccount in
                AccountEditView(account: editingAccount) {
                    accountToEdit = nil
                }
                .environment(\.modelContext, modelContext)
            }
            .background(Color(.systemGray6).ignoresSafeArea())
        }
    }

    // Вынесли логику одной строки в отдельную функцию,
    // чтобы DRY (чтобы одинаково рисовать и видимые, и скрытые):
    @ViewBuilder
    private func accountRow(for account: Account, isHidden: Bool = false) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20.0)
                .foregroundColor(.clear)
                .frame(width: 361.0, height: 76.0)
                .background(Color(white: 1.0))
                .cornerRadius(20.0)
                .shadow(color: Color(white: 0.0, opacity: 0.16),
                        radius: 16.0, x: 3.0, y: 6.0)

            HStack(spacing: 12) {
                // ─── Бейдж с символом валюты ───
                ZStack {
                    Circle()
                        .strokeBorder(Color.appPurple, lineWidth: 7)
                        .background(
                            Circle()
                                .foregroundColor(Color.lightPurprApple)
                        )
                        .frame(width: 44, height: 44)

                    Text(currencySymbols[account.currency ?? ""] ?? "")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.leading, 8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(account.name)
                        .fontWeight(.medium)
                        .font(.body)
                        .foregroundColor(isHidden ? .gray : .primary)

                    Text(account.currency ?? "")
                        .font(.subheadline)
                        .foregroundColor(isHidden ? .gray : .secondary)
                }

                Spacer()

                Text(account.formattedBalance)
                    .fontWeight(.medium)
                    .font(.body)
                    // Если это "скрытый" счет, можно сделать баланс чуть бледнее:
                    .foregroundStyle(isHidden ? .gray : (account.balance < 0 ? .red : .primary))
                    .padding(.trailing, 12)
            }
        }
        .padding(.horizontal)
        .contextMenu {
            // Если это видимый счет, даём возможность редактировать и удалять.
            // Можно также запретить редактирование скрытых, если нужно:
            if !isHidden {
                Button {
                    accountToEdit = account
                } label: {
                    Label("Редактировать", systemImage: "pencil")
                }
                Divider()
                Button(role: .destructive) {
                    deleteAccount(account)
                } label: {
                    Label("Удалить", systemImage: "trash")
                }
            } else {
                // Для скрытых счетов можно либо не показывать меню, либо
                // давать только «Редактировать»/«Удалить» — зависит от UX.
                Button {
                    accountToEdit = account
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
    }

    private func deleteAccount(_ account: Account) {
        for tx in account.transactions {
            modelContext.delete(tx)
        }
        for cat in account.categories {
            modelContext.delete(cat)
        }
        modelContext.delete(account)
        do {
            try modelContext.save()
        } catch {
            print("Ошибка при каскадном удалении аккаунта: \(error)")
        }
    }
}


struct AccountCreationView: View {
    @Environment(\.dismiss) private var dismiss

    // MARK: — состояния для формы
    @State private var accountName: String = ""
    @State private var initialBalanceText: String = ""   // строка для ввода
    @State private var selectedCurrency: String = "RUB"

    let modelContext: ModelContext

    var body: some View {
            NavigationStack {
                VStack(spacing: 16) {
                    // ────────────── Бейдж с символом выбранной валюты ──────────────
                    // Этот VStack находится сразу под заголовком "Новый счет"
                    VStack(spacing: 8) {
                        // 64×64 круглая «плашка» с обводкой
                        ZStack {
                            Circle()
                                .strokeBorder(Color.appPurple, lineWidth: 9)     // Обводка
                                .background(Circle().foregroundColor(.lightPurprApple)) // Фон внутри круга
                                .frame(width: 58, height: 58)

                            // Символ валюты (или значок ₽/$/€ и т.д.)
                            Text(currencySymbols[selectedCurrency] ?? "")
                                .font(.system(size: 28, weight: .heavy))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.top, 8)

                    // ────────────── Сам Form (Inset-Grouped) ──────────────
                    Form {
                        Section {
                            // 1) Поле для ввода названия счёта
                            TextField("Название счета", text: $accountName)
                        }

                        Section {
                            // 2) Ряд “Валюта” (заголовок + Picker справа)
                            HStack {
                                Text("Валюта")
                                Spacer()
                                // Показываем текущий код (например “RUB”), по тапу — меню выбора
                                Picker(selection: $selectedCurrency) {
                                    ForEach(supportedCurrencies, id: \.self) { code in
                                        HStack {
                                            // Показываем и символ, и код, чтобы было нагляднее
                                            Text("\(currencySymbols[code] ?? "") \(code)")
                                        }
                                        .tag(code)
                                    }
                                } label: {
                                    // Лейбл пустой, ведь мы рисуем ячейку вручную через HStack
                                    Text("")
                                }
                                .pickerStyle(.menu)
                            }

                            // 3) Ряд “Начальный баланс (опционально)”
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
                    .listStyle(InsetGroupedListStyle()) // для iOS 14+ / iOS 15+ стабильный grouped-вид
                }
                .navigationTitle("Новый счет")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    // Кнопка «Отмена»
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Отмена") {
                            dismiss()
                        }
                        .foregroundColor(.blue)
                    }
                    // Кнопка «Готово»
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Готово") {
                            addAccount()
                            dismiss()
                        }
                        .disabled(accountName.isEmpty)
                    }
                }
            }
        }

        private func addAccount() {
            // 1) Парсим строку initialBalanceText → Double?
            let initialBalanceValue: Double? = {
                let normalized = initialBalanceText.replacingOccurrences(of: ",", with: ".")
                return Double(normalized)
            }()

            // 2) Создаём новый Account с name, currency и initialBalance
            let newAccount = Account(
                name: accountName,
                currency: selectedCurrency,
                initialBalance: initialBalanceValue
            )
            modelContext.insert(newAccount)

            // 3) Заполняем дефолтные категории (если ещё не заполнены)
            Category.seedDefaults(for: newAccount, in: modelContext)

            // 4) Сохраняем контекст (SwiftData автосохраняет на выходе, но на всякий случай)
            do {
                try modelContext.save()
            } catch {
                print("Ошибка при сохранении нового счета: \(error.localizedDescription)")
            }
        }
    }

