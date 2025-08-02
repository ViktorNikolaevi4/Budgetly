import SwiftUI
import SwiftData
import UserNotifications
import Observation
import CloudKit

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
            AssetType.self,
            User.self
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

    @State var auth = AuthService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.authService, auth)
                .modelContainer(modelContainer)
                .task {
                    await initializeApp()
                }
        }
    }

    private func initializeApp() async {
        do {
            let status = try await CKContainer.default().accountStatus()
            if status == .available {
                auth.fetchCloudUserRecordID()
            } else {
                print("iCloud недоступен: \(status) в \(Date())")
            }
        } catch {
            print("Ошибка проверки статуса iCloud: \(error.localizedDescription) в \(Date())")
        }

        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if let error = error {
                print("Ошибка при запросе разрешений: \(error.localizedDescription) в \(Date())")
            } else {
                print(granted
                      ? "Разрешения для уведомлений предоставлены в \(Date())"
                      : "Разрешения для уведомлений отклонены в \(Date())")
            }
        }
    }
}

// Определение кастомного ключа для authService
private struct AuthServiceKey: EnvironmentKey {
    static let defaultValue: AuthService = AuthService()
}

extension EnvironmentValues {
    var authService: AuthService {
        get { self[AuthServiceKey.self] }
        set { self[AuthServiceKey.self] = newValue }
    }
}
