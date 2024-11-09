//
//  SwiftUIView.swift
//  Budgetly
//
//  Created by Виктор Корольков on 07.11.2024.
//

import SwiftUI

struct SwiftUIView: View {
    @State private var message: String = ""

    var body: some View {
        Text(message)
            .onAppear {
                Task {
                    message = await futchMessage()
                }
            }
    }
}

#Preview {
    SwiftUIView()
}
func futchMessage() async -> String {
     try? await Task.sleep(for: .seconds(2))
    return "Hello World"
}
