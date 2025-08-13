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

    // 0) Уже есть локально? выходим
    if ((try? context.fetchCount(FetchDescriptor<Account>())) ?? 0) > 0 { return }

    // 1) Дадим миррорингу шанс что-то импортировать
    try? await Task.sleep(nanoseconds: 700_000_000)
    if ((try? context.fetchCount(FetchDescriptor<Account>())) ?? 0) > 0 { return }

    let status = try? await CKContainer.default().accountStatus()

    // 2) Если iCloud доступен — сидим ТОЛЬКО если смогли убедиться, что облако пусто
    if status == .available {
        do {
            let db = CKContainer.default().privateCloudDatabase
            let q = CKQuery(recordType: "Account", predicate: NSPredicate(value: true))
            let (results, _) = try await db.records(matching: q)
            guard results.isEmpty else { return }   // в облаке уже есть счета → не сидим
        } catch {
            // Не смогли проверить облако (сеть, схема и т.п.) → чтобы не получить дубликаты, НЕ сидим
            return
        }
    }
    // 3) Если iCloud не доступен — сидим локально (офлайн-first)

    // На всякий случай проверим ещё раз, вдруг что-то успело импортироваться за время запроса
    if ((try? context.fetchCount(FetchDescriptor<Account>())) ?? 0) > 0 { return }

    // 4) Сид локально (однократно)
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

