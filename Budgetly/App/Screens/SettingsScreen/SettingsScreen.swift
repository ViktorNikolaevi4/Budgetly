import SwiftUI
import SwiftData

struct SettingsScreen: View {
    @Environment(\.cloudKitService) private var ckService: CloudKitService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme // Для определения текущей темы

    @State private var showClearAlert = false
    @State private var isClearing = false
    @State private var clearError: Error?
    @State private var showClearError = false

    @Query private var accounts: [Account]

    @State private var showAuthSheet = false
    @State private var showLogin = false

    @State private var showShareSheet = false
    @State private var showRateSheet = false
    @State private var showContactDeveloperSheet = false

    var body: some View {
        NavigationStack {
            List {
                // MARK: — Аккаунт
                Section {
                    if ckService.iCloudAvailable {
                        Label("iCloud доступен", systemImage: "icloud.fill")
                            .foregroundStyle(.primary) // Адаптивный цвет текста и иконки
                    } else {
                        Text("Пожалуйста, включите iCloud в настройках системы")
                            .foregroundStyle(.red) // Красный цвет для ошибки остаётся, но можно заменить на пользовательский
                    }
                }

                // MARK: — Профиль iCloud
                if let name = ckService.displayName, !name.isEmpty {
                    Section("Профиль iCloud") {
                        Label(name, systemImage: "person.fill")
                            .foregroundStyle(.primary) // Адаптивный цвет
                    }
                }

                // MARK: — О приложении
                Section {
                    Button {
                        showShareSheet = true
                    } label: {
                        Label {
                            Text("Поделиться с друзьями")
                                .foregroundStyle(.primary)
                        } icon: {
                            IconBackground(
                                systemName: "square.and.arrow.up",
                                backgroundColor: Color("purpurApple", bundle: nil) // Пользовательский цвет из Asset Catalog
                            )
                        }
                    }

                    Button {
                        showRateSheet = true
                    } label: {
                        Label {
                            Text("Оценить приложение")
                                .foregroundStyle(.primary)
                        } icon: {
                            IconBackground(
                                systemName: "star.fill",
                                backgroundColor: Color("yel3", bundle: nil) // Пользовательский цвет для жёлтого
                            )
                        }
                    }

                    Button {
                        showContactDeveloperSheet = true
                    } label: {
                        Label {
                            Text("Написать разработчикам")
                                .foregroundStyle(.primary)
                        } icon: {
                            IconBackground(
                                systemName: "envelope.fill",
                                backgroundColor: Color("boloto2", bundle: nil) // Пользовательский цвет для зелёного
                            )
                        }
                    }
                }

                // MARK: — Дополнительно (только Регулярные платежи)
                Section {
                    if accounts.isEmpty {
                        Text("Сначала создайте счет")
                            .foregroundStyle(.secondary) // Вторичный цвет для текста
                    } else {
                        NavigationLink {
                            RegularPaymentsScreen()
                        } label: {
                            Label {
                                Text("Регулярные платежи")
                                    .foregroundStyle(.primary)
                            } icon: {
                                IconBackground(
                                    systemName: "scroll.fill",
                                    backgroundColor: Color("redApple", bundle: nil) // Пользовательский цвет для синего
                                )
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Настройки")
            .background(
                GradientView()
                    .ignoresSafeArea()
                    .opacity(colorScheme == .dark ? 0.8 : 1.0) // Лёгкая корректировка прозрачности для тёмной темы
            )
            .alert("Ошибка при выходе", isPresented: $showClearError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(clearError?.localizedDescription ?? "Неизвестная ошибка")
            }
        }
        .foregroundStyle(.primary) // Основной цвет для всей вью
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: ["Проверьте наше приложение! https://apps.apple.com/app/idXXXXXXXXX"])
        }
        .sheet(isPresented: $showRateSheet) {
            RateAppView(isPresented: $showRateSheet)
        }
        .sheet(isPresented: $showContactDeveloperSheet) {
            ContactDeveloperView()
        }
    }
}

/// Вспомогательный view для цветного квадратика под SF Symbol
struct IconBackground: View {
    let systemName: String
    let backgroundColor: Color
    let cornerRadius: CGFloat = 8

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(backgroundColor)
                .frame(width: 32, height: 32)
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white) // Белый цвет иконки для контраста с цветным фоном
        }
    }
}

// Обёртка для UIActivityViewController (ShareSheet)
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    var excludedActivityTypes: [UIActivity.ActivityType]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.excludedActivityTypes = excludedActivityTypes
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}

