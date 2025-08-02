import SwiftUI
import SwiftData
import UserNotifications
import Observation

@main
struct BudgetlyApp: App {
    private let modelContainer: ModelContainer = {
        let schema = Schema([
            Transaction.self,
            Category.self,
            Account.self,
            RegularPayment.self,
            Reminder.self,
            Asset.self,
            AssetType.self
        ])

        let config = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .private("iCloud.Korolvoff.Budgetly2")
        )

        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Не удалось создать контейнер: \(error)")
        }
    }()

    @State private var auth = AuthService() // Используем @State вместо @StateObject

    init() {
        requestNotificationPermission()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.authService, auth)
        }
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



