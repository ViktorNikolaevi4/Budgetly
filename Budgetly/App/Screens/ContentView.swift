import SwiftUI
import Charts
import SwiftData
import CloudKit

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
    @Environment(\.authService) private var auth
    @State private var selectedView: SelectedView = .contentView
    @State private var isMenuVisible = false
    @State private var isRateAppViewPresented = false

    var filteredAccounts: [Account] {
        accounts.filter { $0.ownerUserRecordID == auth.cloudUserRecordID }
    }

    var body: some View {
        TabView {
            HomeScreen()
                .tabItem {
                    Label("Главная", systemImage: "house.fill")
                }
            AccountsScreen(userRecordID: auth.cloudUserRecordID)
                .tabItem {
                    Label("Счета", systemImage: "creditcard")
                }
            GoldBagView()
                .tabItem {
                    Label("Инвестиции", systemImage: "bag.fill")
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
        .background(Color(UIColor.systemGray6))
        .onAppear {
            createDefaultAccountIfNeeded()
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemGray6
            let selectedColor = UIColor(.appPurple)
            appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.gray]
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }

    private func createDefaultAccountIfNeeded() {
        guard filteredAccounts.isEmpty, let userRecordID = auth.cloudUserRecordID else { return }
        let defaultAccount = Account(name: "Основной счет", ownerUserRecordID: userRecordID)
        modelContext.insert(defaultAccount)
        Category.seedDefaults(for: defaultAccount, in: modelContext)
        try? modelContext.save()
    }
}

struct SideMenuView: View {
    @Binding var isMenuVisible: Bool
    @Binding var selectedView: SelectedView
    @Binding var isRateAppViewPresented: Bool

    var body: some View {
        ZStack(alignment: .leading) {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation { isMenuVisible.toggle() }
                }
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
                        selectedView = .contentView
                        isMenuVisible = false
                    }
                }
                .padding()
                Button("Счета") {
                    withAnimation {
                        selectedView = .accounts
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
                Button("Связаться с разработчиком") {
                    withAnimation {
                        selectedView = .contacTheDeveloper
                        isMenuVisible = false
                    }
                }
                .padding()
                Spacer()
            }
            .frame(width: 250)
            .background(Color.white)
            .offset(x: isMenuVisible ? 0 : -250)
            .animation(.easeInOut(duration: 0.3), value: isMenuVisible)
        }
    }

    private func shareWithFriends() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            print("Ошибка: невозможно получить WindowScene")
            return
        }
        let shareText = """
        Я использую приложение Budgetly для управления своими финансами! Попробуй и ты:
        """
        let appStoreLinkString = "https://apps.apple.com/app/idXXXXXXXXX"
        guard let appStoreLink = URL(string: appStoreLinkString) else {
            print("Ошибка: ссылка на App Store недействительна")
            return
        }
        let activityVC = UIActivityViewController(activityItems: [shareText, appStoreLink], applicationActivities: nil)
        if let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true, completion: nil)
        }
    }
}
