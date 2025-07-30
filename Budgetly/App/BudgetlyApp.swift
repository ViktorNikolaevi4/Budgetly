import SwiftUI
import SwiftData
import UserNotifications

@main
struct BudgetApp: App {
  private let modelContainer: ModelContainer = {
    let config = ModelConfiguration("iCloud.Korolvoff.Budgetly2")
    return try! ModelContainer(
        for: 
            Transaction.self,
        Category.self,
        Account.self,
        RegularPayment.self,
        Reminder.self,
        Asset.self,
        AssetType.self
        ,
      configurations: config 
    )
  }()

    @State private var auth = AuthService()

    init() {
        requestNotificationPermission()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.authService, auth)
        }
        // 2) Передаём тот же контейнер в SwiftData
        .modelContainer(modelContainer)
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                print(error != nil
                      ? "Ошибка при запросе разрешений: \(error!)"
                      : (granted
                         ? "Разрешения для уведомлений предоставлены"
                         : "Разрешения для уведомлений отклонены"))
            }
    }
}



