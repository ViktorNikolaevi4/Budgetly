//
//  GradientView.swift
//  Budgetly
//
//  Created by Виктор Корольков on 04.02.2025.
//

import SwiftUI

struct GradientView: View {
    var body: some View {
        RadialGradient(
            gradient: Gradient(colors: [
                Color(red: 60/255, green: 77/255, blue: 90/255),
                Color(red: 30/255, green: 45/255, blue: 55/255)
            ]),
            center: .center,
            startRadius: 20,
            endRadius: 400
        )
        .ignoresSafeArea()
    }
}

#Preview {
    GradientView()
}
