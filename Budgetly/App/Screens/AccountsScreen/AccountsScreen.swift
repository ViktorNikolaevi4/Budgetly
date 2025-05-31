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

    // MARK: — состояния для формы
    @State private var accountName: String = ""
    @State private var initialBalanceText: String = ""   // строка для ввода
    @State private var selectedCurrency: String = "RUB"

    let modelContext: ModelContext

    var body: some View {
        NavigationStack {
            // ───────────────────────────────
            // Используем Form в стиле insetGrouped
            Form {
                Section {
                    // 1) Ввод названия счета
                    TextField("Название счета", text: $accountName)
                }

                Section {
                    // 2) Ряд “Валюта” (заголовок + Picker справа)
                    HStack {
                        Text("Валюта")
                        Spacer()
                        // Показываем текущий код (например “RUB”), по тапу выпадает меню выбора
                        Picker(selection: $selectedCurrency) {
                            ForEach(supportedCurrencies, id: \.self) { code in
                                HStack {
                                    // Показываем и символ, и код, чтобы было нагляднее
                                    Text("\(currencySymbols[code] ?? "") \(code)")
                                }
                                .tag(code)
                            }
                        } label: {
                            // Пустой label, потому что само содержимое Picker мы рисуем через HStack
                            Text("")
                        }
                        .pickerStyle(.menu)
                        // Чтобы иконка “стрелочка” появилась справа
                    }

                    // 3) Ряд “Начальный баланс”
                    HStack {
                        Text("Начальный баланс")
                        Spacer()
                        // Поле для ввода. При вводе подсвечивается клавиатурой decimalPad
                        TextField("0", text: $initialBalanceText)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                            .frame(width: 100)
                        // После ввода показываем символ валюты
                        Text(currencySymbols[selectedCurrency] ?? "")
                            .padding(.leading, 2)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())      // или .automatic, но insetGrouped ближе к Zeplin
            // ───────────────────────────────

            .navigationTitle("Новый счет")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // “Отмена”
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
                // “Готово”
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

    // MARK: — метод для создания нового Account
    private func addAccount() {
        // 1) Парсим введённую строку в Double, если возможно
        let initialBalanceValue: Double? = {
            // Заменяем запятую на точку, на всякий случай
            let normalized = initialBalanceText.replacingOccurrences(of: ",", with: ".")
            return Double(normalized)
        }()

        // 2) Создаём новый Account с полями name, currency и initialBalance
        let newAccount = Account(
            name: accountName,
            currency: selectedCurrency,
            initialBalance: initialBalanceValue
        )
        modelContext.insert(newAccount)

        // 3) Сразу заполняем стандартные категории (если ещё не были заполнены)
        Category.seedDefaults(for: newAccount, in: modelContext)

        // 4) Сохраняем контекст (хотя SwiftData обычно автосохраняет)
        do {
            try modelContext.save()
        } catch {
            print("Ошибка при сохранении нового счета: \(error.localizedDescription)")
        }
    }
}

