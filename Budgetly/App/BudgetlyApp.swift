import SwiftUI
import SwiftData
import UserNotifications

@main
struct BudgetApp: App {
    init() {
        requestNotificationPermission()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [Transaction.self,
                                      Category.self,
                                      Account.self,
                                      RegularPayment.self
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

