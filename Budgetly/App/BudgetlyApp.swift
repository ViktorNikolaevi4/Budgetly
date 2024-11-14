import SwiftUI
import SwiftData

@main
struct BudgetApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [Transaction.self, Category.self, Account.self])
        }
    }
}

