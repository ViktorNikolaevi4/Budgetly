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
                .task { await trySeed() }
                .onChange(of: ckService.lastStatus) { _, s in
                    if s == .available {
                        Task { await trySeed() }
                    }
                }
        }
    }

    private func trySeed() async {
        await createDefaultAccountIfNeeded(in: modelContainer.mainContext)
    }

    func createDefaultAccountIfNeeded(in context: ModelContext) async {
        // 0) Если локально уже есть счет — ничего не делаем (идемпотентность)
        if (try? context.fetchCount(FetchDescriptor<Account>())) ?? 0 > 0 { return }

        // 1) Ждём доступности iCloud; если его нет — просто выйдем,
        // onChange(ckService.lastStatus) вызовет нас снова
        let status = (try? await CKContainer.default().accountStatus()) ?? .couldNotDetermine
        guard status == .available else { return }

        // 2) Проверяем, нет ли УЖЕ счетов в приватной БД CloudKit
        do {
            let db = CKContainer.default().privateCloudDatabase
            let query = CKQuery(recordType: "Account", predicate: NSPredicate(value: true))
            let (results, _) = try await db.records(matching: query)
            guard results.isEmpty else { return } // в облаке уже есть — не сидируем
        } catch {
            // если тут снова упало (редко), просто выйдем — нас ещё раз дернут при активизации/повторе
            return
        }

        // 3) Создаём локально «Основной счет» и дефолтные категории — это синканется
        let acc = Account(name: "Основной счёт", currency: "RUB", sortOrder: 0)
        context.insert(acc)
        Category.seedDefaults(for: acc, in: context)
        try? context.save()
    }
}

