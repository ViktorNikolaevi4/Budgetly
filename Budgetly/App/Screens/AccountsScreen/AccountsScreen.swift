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

    // MARK: — новые состояния
    @State private var accountName: String = ""
    @State private var initialBalanceText: String = ""   // строка для ввода
    @State private var selectedCurrency: String = "RUB"

    let modelContext: ModelContext

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 1) Поле для названия счёта
                TextField("Название счета", text: $accountName)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.clear, lineWidth: 0)
                    )
                    .padding(.horizontal)

                // 2) Поле для «Начального баланса (опционально)»
                //    Пользователь может ввести, например, "1000" или "12345.67"
                TextField("Начальный баланс (опционально)", text: $initialBalanceText)
                    .keyboardType(.decimalPad)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.clear, lineWidth: 0)
                    )
                    .padding(.horizontal)

                // 3) Picker для выбора валюты
                VStack(alignment: .leading, spacing: 6) {
                    Text("Валюта")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 16)

                    Picker(selection: $selectedCurrency) {
                        ForEach(supportedCurrencies, id: \.self) { currency in
                            Text(currency).tag(currency)
                        }
                    } label: {
                        Text("") // Лейбл оставляем пустым
                    }
                    .pickerStyle(.menu)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                }

                Spacer()
            }
            .navigationTitle("Новый счет")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Кнопка «Отмена»
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                    .foregroundStyle(.appPurple)
                }
                // Кнопка «Готово»
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        addAccount()
                        dismiss()
                    }
                    // Блокируем, если имя счета пустое
                    .disabled(accountName.isEmpty)
                }
            }
            .background(Color(.systemGray6).ignoresSafeArea())
        }
    }

    // MARK: — Метод для создания нового счёта
    private func addAccount() {
        // 1) Парсим initialBalanceText в Double (если не получится — будет nil)
        let initialBalanceValue: Double? = {
            // Заменим запятую на точку, чтобы пользователь мог вводить «1 234,56» или «1234.56»
            let normalized = initialBalanceText.replacingOccurrences(of: ",", with: ".")
            return Double(normalized)
        }()

        // 2) Создаём новый объект Account
        let newAccount = Account(
            name: accountName,
            currency: selectedCurrency,
            initialBalance: initialBalanceValue
        )
        modelContext.insert(newAccount)

        // 3) Заполняем стандартные категории (если нужно)
        Category.seedDefaults(for: newAccount, in: modelContext)

        // 4) Сохраняем контекст вручную (на всякий случай)
        do {
            try modelContext.save()
        } catch {
            print("Ошибка при сохранении нового счета: \(error.localizedDescription)")
        }
    }
}


