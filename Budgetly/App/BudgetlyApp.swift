import SwiftUI
import SwiftData
import UserNotifications
import Observation

@main
struct BudgetlyApp: App {
    // 1) Держим сервис как StateObject
    @State private var ckService = CloudKitService()

    // 2) Конфигурируем SwiftData с автоматической CloudKit-синхронизацией
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
                cloudKitDatabase: .automatic
            )
            return try! ModelContainer(for: schema, configurations: config)
        }()

        init() {
            // пуши нужны, если вы подписываетесь на silent-notifications
            UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    print(granted
                          ? "Уведомления разрешены"
                          : "Уведомления не разрешены")
                }
        }

        var body: some Scene {
            WindowGroup {
                RootView()
                    // 3) передаём сервис в иерархию
                    .environment(\.cloudKitService, ckService)
            }
            .modelContainer(modelContainer)
        }
    }




