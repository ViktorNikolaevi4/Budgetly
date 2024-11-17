//
//  RateAppView.swift
//  Budgetly
//
//  Created by Виктор Корольков on 17.11.2024.
//

import SwiftUI
import StoreKit

struct RateAppView: View {
    @Binding var isPresented: Bool // Управление отображением окна

    var body: some View {
        VStack {
            // Ваш кастомный заголовок
            Text("Регистрация")
                .font(.headline)
                .padding()

            Text("Мы очень стараемся для вас и каждый день улучшаем наше приложение!")
                .multilineTextAlignment(.center)
                .padding()

            Text("Пожалуйста, поставьте нам 5 звезд на странице приложения в App Store!")
                .multilineTextAlignment(.center)
                .padding(.bottom)

            // Звезды
            HStack(spacing: 5) {
                ForEach(0..<5) { _ in
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.largeTitle)
                }
            }
            .padding()

            Text("Спасибо вам большое!")
                .font(.footnote)
                .padding(.bottom)

            // Кнопка "5 ЗВЁЗДОЧЕК"
            Button(action: {
                rateApp()
            }) {
                Text("5 ЗВЁЗДОЧЕК")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.yellow)
                    .foregroundColor(.black)
                    .cornerRadius(8)
            }
            .padding(.horizontal)

            // Кнопка "Отмена"
            Button(action: {
                isPresented = false
            }) {
                Text("Отмена")
                    .foregroundColor(.red)
            }
            .padding(.top)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 10)
        .frame(maxWidth: 300) // Размер окна
    }

    // Функция для перенаправления в App Store
    private func rateApp() {
        let appStoreLink = "https://apps.apple.com/app/idXXXXXXXXX" // Укажите ID приложения
        if let url = URL(string: appStoreLink), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}


