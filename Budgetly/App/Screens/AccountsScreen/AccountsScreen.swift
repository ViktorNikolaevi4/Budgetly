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
                                    Text(account.name)
                                        .fontWeight(.medium)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .padding(.leading)

                                    Spacer()

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
                                    deleteAccount(account)
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
    private func deleteAccount(_ account: Account) {
        // 1) Удалим все транзакции, связанные с этим аккаунтом
        let relatedTransactions = account.transactions
        for tx in relatedTransactions {
            modelContext.delete(tx)
        }

        // 2) Удалим все категории, связанные с этим аккаунтом
        let relatedCategories = account.categories
        for cat in relatedCategories {
            modelContext.delete(cat)
        }

        // 3) Наконец, удалим сам аккаунт
        modelContext.delete(account)

        // 4) Сохраним изменения
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

