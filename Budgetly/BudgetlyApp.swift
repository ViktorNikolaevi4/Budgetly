//
//  BudgetlyApp.swift
//  Budgetly
//
//  Created by Виктор Корольков on 05.11.2024.
//

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

