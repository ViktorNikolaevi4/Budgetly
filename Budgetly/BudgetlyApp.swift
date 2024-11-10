import SwiftUI
import SwiftData

@main
struct BudgetApp: App {
    @State var budgetViewModel = BudgetViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(budgetViewModel)
        }
    }
}

