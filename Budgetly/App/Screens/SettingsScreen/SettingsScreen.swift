import SwiftUI

struct SettingsScreen: View {
    @State private var showShareSheet = false
    @State private var showRateSheet = false
    @State private var showContactDeveloperSheet = false

    var body: some View {
            NavigationStack {
                       List {
                           // Раздел для аккаунта
                           Section(header: Text("Аккаунт")) {
                               NavigationLink(destination: RegistrationView()) {
                                   Label("Регистрация", systemImage: "person.crop.circle.badge.plus")
                               }
                           }

                           // Раздел для работы с приложением
                           Section(header: Text("О приложении")) {
                               Button {
                                   showShareSheet = true
                               } label: {
                                   Label("Поделиться с друзьями", systemImage: "square.and.arrow.up")
                               }

                               Button {
                                   showRateSheet = true
                               } label: {
                                   Label("Оценить приложение", systemImage: "star.fill")
                               }

                               Button {
                                   showContactDeveloperSheet = true
                               } label: {
                                   Label("Написать разработчикам", systemImage: "envelope")
                               }
                           }
                           // Новый раздел "Дополнительно" — или как вы хотите назвать
                           Section("Дополнительно") {
                               NavigationLink(destination: RegularPaymentsScreen()) {
                                   Label("Регулярные платежи", systemImage: "scroll")
                               }
                               NavigationLink(destination: RemindersScreen()) {
                                   Label("Напоминания", systemImage: "bell")
                               }
                           }
                       }
                       .listStyle(InsetGroupedListStyle())
                       .navigationTitle("Настройки")
                       .background(GradientView().ignoresSafeArea())
                       // Открываем ShareSheet
                       .sheet(isPresented: $showShareSheet) {
                           ShareSheet(items: ["Проверьте наше приложение! https://apps.apple.com/app/idXXXXXXXXX"])
                       }
                       // Открываем окно оценки (RateAppView должен принимать привязку для закрытия окна)
                       .sheet(isPresented: $showRateSheet) {
                           RateAppView(isPresented: $showRateSheet)
                       }
                       // Открываем окно связи с разработчиками
                       .sheet(isPresented: $showContactDeveloperSheet) {
                           ContactDeveloperView()
                       }
                   }
            .foregroundStyle(.black)
               }
        }

// MARK: - Обёртка для UIActivityViewController (ShareSheet)
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    var excludedActivityTypes: [UIActivity.ActivityType]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.excludedActivityTypes = excludedActivityTypes
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Не требуется обновление.
    }
}
