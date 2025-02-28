//
//  GradientView.swift
//  Budgetly
//
//  Created by Виктор Корольков on 04.02.2025.
//

import SwiftUI

struct GradientView: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 230/255, green: 230/255, blue: 235/255),
                Color(red: 241/255, green: 242/255, blue: 244/255)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

#Preview {
    GradientView()
}

