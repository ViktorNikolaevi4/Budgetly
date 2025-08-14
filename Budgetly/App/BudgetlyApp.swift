import SwiftUI
import SwiftData
import UserNotifications
import CloudKit
import Observation

@MainActor
private var isSeedingRunning = false

@MainActor
func createDefaultAccountIfNeeded(in ctx: ModelContext) async {
    // уже есть локально? выходим
    if ((try? ctx.fetchCount(FetchDescriptor<Account>())) ?? 0) > 0 { return }

    // ждём импорт из iCloud до ~5 c
    for _ in 0..<15 {
        try? await Task.sleep(nanoseconds: 300_000_000)
        if ((try? ctx.fetchCount(FetchDescriptor<Account>())) ?? 0) > 0 { return }
    }

    // ничего не пришло — сидим офлайн
    let acc = Account(name: "Основной счёт", currency: "RUB", initialBalance: 0, sortOrder: 0)
    ctx.insert(acc)
    Category.seedDefaults(for: acc, in: ctx)
    try? ctx.save()
}

@MainActor
func dedupeAccounts(in ctx: ModelContext) {
    let all = (try? ctx.fetch(FetchDescriptor<Account>())) ?? []
    func key(_ a: Account) -> String {
        let name = a.name.trimmingCharacters(in: .whitespacesAndNewlines)
                          .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                          .lowercased()
        return "\(a.currency ?? "RUB")|\(name)"
    }

    var keeperByKey: [String: Account] = [:]

    for acc in all {
        let k = key(acc)
        if let keep = keeperByKey[k] {
            // переносим детей к «основному»
            for t in acc.allTransactions { t.account = keep }
            for c in acc.allCategories  { c.account = keep }
            // если есть регулярки — тоже перенесите
            // for r in acc.regularPayments { r.account = keep }
            ctx.delete(acc)
        } else {
            keeperByKey[k] = acc
        }
    }
    try? ctx.save()
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
                .task {
                    await createDefaultAccountIfNeeded(in: modelContainer.mainContext)
                    dedupeAccounts(in: modelContainer.mainContext)   // на всякий
                }        }
    }



//    private func trySeed() async {
//        await createDefaultAccountIfNeeded(in: modelContainer.mainContext)
//    }
}

