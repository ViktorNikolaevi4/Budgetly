import SwiftUI
import StoreKit

struct RateAppView: View {
    @Binding var isPresented: Bool // Управление отображением окна
    @Environment(\.colorScheme) private var colorScheme // Определение текущей темы

    var body: some View {
        VStack {

            Text("Мы очень стараемся для вас и каждый день улучшаем наше приложение!")
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .padding(.bottom)

            Text("Пожалуйста, поставьте нам 5 звезд на странице приложения в App Store!")
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .padding(.bottom)

            // Звезды
            HStack(spacing: 5) {
                ForEach(0..<5) { _ in
                    Image(systemName: "star.fill")
                        .foregroundColor(colorScheme == .dark ? .yellow.opacity(0.9) : .yellow) // Лёгкая корректировка для тёмной темы
                        .font(.largeTitle)
                }
            }
            .padding()

            Text("Спасибо вам большое!")
                .font(.footnote)
                .foregroundStyle(.primary)
                .padding(.bottom)

            // Кнопка "5 ЗВЁЗДОЧЕК"
            Button(action: {
                rateApp()
            }) {
                Text("5 ЗВЁЗДОЧЕК")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(colorScheme == .dark ? Color.yellow.opacity(0.9) : Color.yellow) // Адаптация фона кнопки
                    .foregroundColor(.black)
                    .cornerRadius(8)
            }
            .padding(.horizontal)

            // Кнопка "Отмена"
            Button(action: {
                isPresented = false
            }) {
                Text("Отмена")
                    .foregroundColor(colorScheme == .dark ? .red.opacity(0.9) : .red) // Адаптация цвета для тёмной темы
            }
            .padding(.top)
        }
        .padding()
        .background(Color(.systemBackground)) // Исправлено на Color(.systemBackground)
        .cornerRadius(12)
        .shadow(radius: 10)
        .frame(maxWidth: 300) // Размер окна
    }
    private let appStoreID = "6749693267"
    // Функция для перенаправления в App Store
    private func rateApp() {
        // Откроет сразу экран «Написать отзыв» в App Store
        let urlStr = "itms-apps://apps.apple.com/app/id\(appStoreID)?action=write-review"
        if let url = URL(string: urlStr) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
