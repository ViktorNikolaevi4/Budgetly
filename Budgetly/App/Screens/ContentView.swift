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
}

struct ContentView: View {
    @Query private var transactions: [Transaction]
    @Query private var accounts: [Account]
    @Environment(\.modelContext) private var modelContext
    @State private var selectedView: SelectedView = .contentView
    @State private var isMenuVisible = false
    @State private var isRateAppViewPresented = false // Управление видимостью окна оценки приложения

    var body: some View {
        TabView {
            HomeScreen()
                .tabItem {
                    Label("Главная", systemImage: "house.fill")
                }
            AccountsScreen()
                .tabItem {
                    Label("Счета", systemImage: "creditcard")
                }
            GoldBagView()
                .tabItem {
                    Label("Активы", systemImage: "bag.fill")
                }

            StatsView()
                .tabItem {
                    Label("Статистика", systemImage: "chart.bar.fill")
                }
            SettingsScreen()
                .tabItem {
                    Label("Настройки", systemImage: "gearshape")
                        .symbolRenderingMode(.hierarchical)
                }
        }
        .background(Color(UIColor.systemGray6)) // Фон TabView
        .onAppear {
            createDefaultAccountIfNeeded()
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()

            // Цвет фона Tab Bar (как на макете)
            appearance.backgroundColor = UIColor.systemGray6

            // Настройка цветов иконок и текста
            let selectedColor = UIColor(red: 85/255, green: 80/255, blue: 255/255, alpha: 1)

            appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]

            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.gray]

            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }

    }
    private func createDefaultAccountIfNeeded() {
        guard accounts.isEmpty else { return }

        let defaultAccount = Account(name: "Основной счет")
        modelContext.insert(defaultAccount)

        do {
            try modelContext.save()
        } catch {
            print("Ошибка сохранения Основного счета: \(error.localizedDescription)")
        }
    }

//        ZStack {
//            NavigationStack {
//                VStack {
//                    if selectedView == .contentView {
//                        mainContentView
//                    } else if selectedView == .accounts {
//                        AccountsView()
//                    } else if selectedView == .regularPayments {
//                        RegularPaymentsView()
//                    }
//                    else if selectedView == .reminders {
//                        RemindersView()
//                    }
//                    else if selectedView == .contacTheDeveloper {
//                        ContactDeveloperView()
//                    }
//                    else if selectedView == .registration {
//                        RegistrationView()
//                    }
//                }
//                .navigationTitle("Бюджет")
//                .toolbar {
//                    ToolbarItem(placement: .topBarTrailing) {
//                        Button {
//                            withAnimation {
//                                isMenuVisible.toggle()
//                            }
//                        } label: {
//                            Image(systemName: "gearshape.fill")
//                                .font(.title3)
//                                .foregroundColor(.black)
//                        }
//                    }
//                }
//            }
//
//            if isMenuVisible {
//                SideMenuView(
//                    isMenuVisible: $isMenuVisible,
//                    selectedView: $selectedView,
//                    isRateAppViewPresented: $isRateAppViewPresented
//                )
//            }
//
//            if isRateAppViewPresented {
//                Color.black.opacity(0.4) // Полупрозрачный фон
//                    .ignoresSafeArea()
//                    .onTapGesture {
//                        isRateAppViewPresented = false
//                    }
//
//                RateAppView(isPresented: $isRateAppViewPresented)
//            }
//        }
//        .onAppear {
//            if accounts.isEmpty {
//                let account = Account(name: "Основной Счет")
//                modelContext.insert(account)
//            }
//        }
    }


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
