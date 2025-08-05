import SwiftUI
import SwiftData
import UserNotifications
import CloudKit
import Observation

@main
struct BudgetlyApp: App {
    @State private var ckService = CloudKitService()
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
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                print(granted ? "Уведомления разрешены" : "Уведомления не разрешены")
            }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.cloudKitService, ckService)
                .modelContainer(modelContainer)
                .task {
                    await createDefaultAccountIfNeeded(in: modelContainer.mainContext)
                }
        }
        
    }
    func createDefaultAccountIfNeeded(in context: ModelContext) async {
        // 1) Формируем query ко всем Account-записям в приватной базе
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Account", predicate: predicate)
        let database = CKContainer.default().privateCloudDatabase

        do {
            // 2) Выполняем запрос
            let (matchingResults, _) = try await database.records(matching: query)

            // 3) Считаем сколько реально удалённых записей
            let remoteCount = matchingResults.count

            guard remoteCount == 0 else {
                // в iCloud уже есть счёта — нам ничего не нужно заводить
                return
            }

            // 4) Проверяем, что локально тоже нет дублей
            let desc = FetchDescriptor<Account>(
                predicate: #Predicate {
                    $0.name == "Основной счёт" && ($0.currency ?? "") == "RUB"
                }
            )
            let localCount = try context.fetchCount(desc)
            guard localCount == 0 else { return }

            // 5) Создаём «Основной счёт» и seed‐категории
            let acc = Account(name: "Основной счёт", currency: "RUB", sortOrder: 0)
            context.insert(acc)
            Category.seedDefaults(for: acc, in: context)
            try context.save()

        } catch {
            print("Ошибка при проверке удалённых счётов: \(error)")
        }
    }
}

