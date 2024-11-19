import SwiftUI
import Charts
import Observation
import SwiftData

enum SelectedView {
    case registration
    case contentView
    case accounts
    case regularPayments
    case reminders
    case settings
    case shareWithFriends
    case appEvaluation
    case contacTheDeveloper
    // Добавьте другие представления, если нужно
}
//Еnum для периода времени
enum TimePeriod: String, CaseIterable, Identifiable {
    case day = "День"
    case week = "Неделя"
    case month = "Месяц"
    case year = "Год"
    case allTime = "Все время"

    var id: String { self.rawValue }
}

struct ContentView: View {
    @Query private var transactions: [Transaction]
    @Query private var accounts: [Account]
    @Environment(\.modelContext) private var modelContext
    @State private var selectedAccount: Account?
    @State private var isAddTransactionViewPresented = false
    @State private var selectedTransactionType: TransactionType = .income
    @State private var selectedTimePeriod: TimePeriod = .allTime
    @State private var selectedView: SelectedView = .contentView
    @State private var isMenuVisible = false
    @State private var isRateAppViewPresented = false // Управление видимостью окна оценки приложения

    private var saldo: Double {
        guard let account = selectedAccount else { return 0 }
        let income = account.transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let expenses = account.transactions.filter { $0.type == .expenses }.reduce(0) { $0 + $1.amount }
        return income - expenses
    }

    var filteredTransactions: [Transaction] {
        let now = Date()
        let calendar = Calendar.current

        return (selectedAccount?.transactions ?? []).filter { transaction in
            guard transaction.type == selectedTransactionType else { return false }
            switch TimePeriod(rawValue: selectedTimePeriod.rawValue) ?? .allTime {
            case .day:
                return calendar.isDateInToday(transaction.date)
            case .week:
                return calendar.isDate(transaction.date, equalTo: now, toGranularity: .weekOfYear)
            case .month:
                return calendar.isDate(transaction.date, equalTo: now, toGranularity: .month)
            case .year:
                return calendar.isDate(transaction.date, equalTo: now, toGranularity: .year)
            case .allTime:
                return true
            }
        }
    }

    var body: some View {
        ZStack {
            NavigationStack {
                VStack {
                    if selectedView == .contentView {
                        mainContentView
                    } else if selectedView == .accounts {
                        AccountsView()
                    } else if selectedView == .regularPayments {
                        RegularPaymentsView()
                    }
                    else if selectedView == .reminders {
                        RemindersView()
                    }
                    else if selectedView == .contacTheDeveloper {
                        ContactDeveloperView()
                    }
                     else if selectedView == .registration {
                    RegistrationView()
                    }
                }
                .navigationTitle("Бюджет")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            withAnimation {
                                isMenuVisible.toggle()
                            }
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.title3)
                                .foregroundColor(.black)
                        }
                    }
                }
            }

            if isMenuVisible {
                SideMenuView(isMenuVisible: $isMenuVisible,
                             selectedView: $selectedView,
                             isRateAppViewPresented: $isRateAppViewPresented)
            }

            if isRateAppViewPresented {
                Color.black.opacity(0.4) // Полупрозрачный фон
                    .ignoresSafeArea()
                    .onTapGesture {
                        isRateAppViewPresented = false
                    }

                RateAppView(isPresented: $isRateAppViewPresented)
            }
        }
        .onAppear {
            if accounts.isEmpty {
                let account = Account(name: "Основной Счет")
                modelContext.insert(account)
            }
        }
    }

    private var mainContentView: some View {
        VStack {
            Picker("Выберите счет", selection: $selectedAccount) {
                Text("Выберите счет").tag(nil as Account?)
                ForEach(accounts) { account in
                    Text(account.name).tag(account as Account?)
                }
            }
            .padding()
            .onAppear {
                if selectedAccount == nil {
                    selectedAccount = accounts.first
                }
            }

            Text("Сальдо: \(saldo >= 0 ? "+" : "")\(saldo, specifier: "%.2f") ₽")
                .foregroundColor(saldo >= 0 ? .green : .red)
                .font(.title2)
                .padding()

            HStack {
                Button(action: { selectedTransactionType = .expenses }) {
                    Text("Расходы")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedTransactionType == .expenses ? Color.black : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                Button(action: { selectedTransactionType = .income }) {
                    Text("Доходы")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedTransactionType == .income ? Color.black : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 5) {
                    ForEach(TimePeriod.allCases) { period in
                        Button(action: { selectedTimePeriod = period }) {
                            Text(period.rawValue)
                                .font(.caption)
                                .frame(width: 55, height: 5)
                                .padding()
                                .background(selectedTimePeriod == period ? Color.blue : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .padding(.bottom) // Отступ перед графиком

            PieChartView(transactions: filteredTransactions) // Перемещен ниже

            List(filteredTransactions) { transaction in
                HStack {
                    Text(transaction.category)
                    Spacer()
                    Text("\(transaction.amount, specifier: "%.2f") ₽")
                        .foregroundColor(transaction.type == .expenses ? .red : .green)
                }
            }

            Button(action: {
                isAddTransactionViewPresented = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .background(Color.white)
                    .foregroundColor(.black)
                    .font(.largeTitle)
            }
            .padding()
            .sheet(isPresented: $isAddTransactionViewPresented) {
                AddTransactionView(account: selectedAccount)
            }
        }
    }}

#Preview {
    ContentView()
}


struct SideMenuView: View {
    @Binding var isMenuVisible: Bool
    @Binding var selectedView: SelectedView
    @Binding var isRateAppViewPresented: Bool // Управление окном оценки

    var body: some View {
        ZStack(alignment: .leading) {
            // Полупрозрачный фон для скрытия меню при нажатии за его пределами
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        isMenuVisible.toggle()
                    }
                }

            // Само меню
            VStack(alignment: .leading) {
                Button("Регистрация") {
                    withAnimation {
                        selectedView = .registration
                        isMenuVisible = false
                    }
                }
                .padding()

                Button("Главная") {
                    withAnimation {
                        selectedView = .contentView // Устанавливаем главное представление
                        isMenuVisible = false
                    }
                }
                .padding()

                Button("Счета") {
                    withAnimation {
                        selectedView = .accounts // Устанавливаем отображение "Счета"
                        isMenuVisible = false
                    }
                }
                .padding()

                Button("Регулярные платежи") {
                    withAnimation {
                        selectedView = .regularPayments
                        isMenuVisible = false
                    }
                }
                .padding()

                Button("Напоминания") {
                    withAnimation {
                        selectedView = .reminders
                        isMenuVisible = false
                    }
                }
                .padding()

                Button("Настройки") {
                    withAnimation {
                        selectedView = .settings
                        isMenuVisible = false
                    }
                }
                .padding()

                Button("Поделиться с друзьями") {
                    withAnimation {
                        shareWithFriends()
                        isMenuVisible = false
                    }
                }
                .padding()

                Button("Оценить приложение") {
                    withAnimation {
                        isMenuVisible = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isRateAppViewPresented = true
                    }
                }
                .padding()

                Button("Связаться с разработчикамм") {
                    withAnimation {
                        selectedView = .contacTheDeveloper
                        isMenuVisible = false
                    }
                }
                .padding()


                // Добавьте остальные кнопки меню

                Spacer()
            }
            .frame(width: 250) // Ширина меню
            .background(Color.white)
            .offset(x: isMenuVisible ? 0 : -250) // Выдвижение меню
            .animation(.easeInOut(duration: 0.3), value: isMenuVisible)
        }
    }

    // Функция для вызова UIActivityViewController
    private func shareWithFriends() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            print("Ошибка: невозможно получить WindowScene")
            return
        }
        // Текст и ссылка на App Store
        let shareText = """
        Я использую приложение Budgetly для управления своими финансами! Попробуй и ты:
        """
        // Ссылка на App Store
        let appStoreLinkString = "https://apps.apple.com/app/idXXXXXXXXX" // Укажите свою ссылку
        guard let appStoreLink = URL(string: appStoreLinkString) else {
            print("Ошибка: ссылка на App Store недействительна")
            return
        }
        // UIActivityViewController
        let activityVC = UIActivityViewController(activityItems: [shareText, appStoreLink], applicationActivities: nil)
        // Указываем, с какой сцены запустить ActivityViewController
        if let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true, completion: nil)
        }
    }
}
