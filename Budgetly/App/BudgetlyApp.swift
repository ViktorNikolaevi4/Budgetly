import SwiftUI
import SwiftData
import UserNotifications
import CloudKit
import Observation

@MainActor
private var isSeedingRunning = false

@MainActor
func createDefaultAccountIfNeeded(in context: ModelContext) async {
    guard !isSeedingRunning else { return }
    isSeedingRunning = true
    defer { isSeedingRunning = false }

    // уже есть счета?
    if (try? context.fetchCount(FetchDescriptor<Account>())) ?? 0 > 0 { return }

    // (опционально) проверка облака, как у вас
    if (try? await CKContainer.default().accountStatus()) == .available {
        do {
            let db = CKContainer.default().privateCloudDatabase
            let q = CKQuery(recordType: "Account", predicate: NSPredicate(value: true))
            let (results, _) = try await db.records(matching: q)
            if !results.isEmpty { return } // ждём синк, локально не сидим
        } catch { /* игнорируем и сидим локально */ }
    }

    // сид локально
    let acc = Account(name: "Основной счёт", currency: "RUB", sortOrder: 0)
    context.insert(acc)
    Category.seedDefaults(for: acc, in: context)
    try? context.save()
    UserDefaults.standard.set(acc.id.uuidString, forKey: "selectedAccountID")
}



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
            // 👇 единственная точка входа
                .task { await createDefaultAccountIfNeeded(in: modelContainer.mainContext) }
        }
    }



//    private func trySeed() async {
//        await createDefaultAccountIfNeeded(in: modelContainer.mainContext)
//    }
}

