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
    @State private var showHiddenAccounts = false

    // Теперь visibleAccounts и hiddenAccounts по-прежнему:
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
                        // ─── ВИДИМЫЕ СЧЕТА ─────────────────────────────────────
                        ForEach(visibleAccounts) { account in
                            // Передаём только account
                            accountRow(
                                for: account,
                                onEditTap: {
                                    accountToEdit = account
                                }
                            )
                            .frame(height: 76)
                            .padding(.horizontal)
                        }

                        // ─── КНОПКА «Показать / Скрыть скрытые счета» ────────────────
                        if !hiddenAccounts.isEmpty {
                            Button(action: {
                                withAnimation { showHiddenAccounts.toggle() }
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

                        // ─── Если показываем скрытые — отображаем их ────────────────
                        if showHiddenAccounts {
                            ForEach(hiddenAccounts) { account in
                                accountRow(
                                    for: account,
                                    onEditTap: {
                                        accountToEdit = account
                                    }
                                )
                                .frame(height: 76)
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }

                // ─── КНОПКА «Добавить новый счёт» ───────────────────────────────
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EmptyView() // убираем «Редактировать»
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isShowingAddAccountSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.appPurple)
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
            .background(Color(.systemGray6).ignoresSafeArea())
        }
    }

    /// Внутри accountRow смотрим на account.isHidden
    @ViewBuilder
    private func accountRow(
        for account: Account,
        onEditTap: @escaping () -> Void
    ) -> some View {
        // Шаблон карточки
        ZStack {
            RoundedRectangle(cornerRadius: 20.0)
                .foregroundColor(.clear)
                .frame(height: 76.0)
                .background(Color(white: 1.0))
                .cornerRadius(20.0)
                .shadow(color: Color(white: 0.0, opacity: 0.16),
                        radius: 16.0, x: 3.0, y: 6.0)

            HStack(spacing: 12) {
                // ─── Бейдж с символом валюты ────────────────────────────
                ZStack {
                    // Обводка круга: смотрим на account.isHidden
                    Circle()
                        .strokeBorder(
                            account.isHidden
                                ? Color.gray.opacity(0.6)
                                : Color.appPurple,
                            lineWidth: 7
                        )
                        .background(
                            Circle()
                                .foregroundColor(
                                    account.isHidden
                                        ? Color.gray.opacity(0.2)
                                        : Color.lightPurprApple
                                )
                        )
                        .frame(width: 44, height: 44)

                    Text(currencySymbols[account.currency ?? ""] ?? "")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(
                            account.isHidden
                                ? Color.gray
                                : Color.white
                        )
                }
                .padding(.leading, 8)

                // ─── Название и код валюты ──────────────────────────────
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.name)
                        .fontWeight(.medium)
                        .font(.body)
                        .foregroundColor(account.isHidden ? .gray : .primary)

                    Text(account.currency ?? "")
                        .font(.subheadline)
                        .foregroundColor(account.isHidden ? .gray : .secondary)
                }

                Spacer()

                // ─── Баланс ────────────────────────────────────────────
                Text(account.formattedBalance)
                    .fontWeight(.medium)
                    .font(.body)
                    .foregroundStyle(
                        account.isHidden
                            ? .gray
                            : (account.balance < 0 ? .red : .primary)
                    )
                    .padding(.trailing, 12)

                // ─── Кнопка «✏️» всегда видна ────────────────────────────
                Button(action: { onEditTap() }) {
                    Image(systemName: "pencil")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .padding(8)
                        .background(Color.blue.opacity(0.8))
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
                .padding(.leading, 8)
                .padding(.trailing, 12)
            }
        }
        .contextMenu {
            Button { onEditTap() } label: {
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
