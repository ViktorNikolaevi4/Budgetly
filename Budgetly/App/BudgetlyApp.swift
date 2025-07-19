import SwiftUI
import SwiftData
import UserNotifications

@main
struct BudgetApp: App {
    @State private var auth = AuthService()
    init() {
        requestNotificationPermission()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.authService, auth)
                .modelContainer(for: [Transaction.self,
                                      Category.self,
                                      Account.self,
                                      RegularPayment.self,
                                      Reminder.self,
                                      Asset.self,
                                      AssetType.self
                                     ])
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Ошибка при запросе разрешений: \(error)")
            } else if granted {
                print("Разрешения для уведомлений предоставлены")
            } else {
                print("Разрешения для уведомлений отклонены")
            }
        }
    }
}

