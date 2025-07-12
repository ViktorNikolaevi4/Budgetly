import SwiftUI

struct SettingsScreen: View {
    @State private var showShareSheet = false
    @State private var showRateSheet = false
    @State private var showContactDeveloperSheet = false

    var body: some View {
        NavigationStack {
            List {
                // MARK: — Аккаунт
                Section {
                    NavigationLink(destination: RegistrationView()) {
                        Label {
                            Text("Вход / Регистрация")
                        } icon: {
                            IconBackground(
                                systemName: "person.crop.circle.fill",
                                backgroundColor: Color(red: 255/255, green: 45/255, blue: 85/255)
                            )
                        }
                    }
                }

                // MARK: — О приложении
                Section {
                    Button {
                        showShareSheet = true
                    } label: {
                        Label {
                            Text("Поделиться с друзьями")
                        } icon: {
                            IconBackground(
                                systemName: "square.and.arrow.up",
                                backgroundColor: Color(red: 194/255, green: 98/255, blue: 228/255)
                            )
                        }
                    }

                    Button {
                        showRateSheet = true
                    } label: {
                        Label {
                            Text("Оценить приложение")
                        } icon: {
                            IconBackground(systemName: "star.fill", backgroundColor: .yellow)
                        }
                    }

                    Button {
                        showContactDeveloperSheet = true
                    } label: {
                        Label {
                            Text("Написать разработчикам")
                        } icon: {
                            IconBackground(
                                systemName: "envelope.fill",
                                backgroundColor: Color(red: 0/255, green: 184/255, blue: 148/255)
                            )
                        }
                    }
                }

                // MARK: — Дополнительно (только Регулярные платежи)
                Section {
                    NavigationLink(destination: RegularPaymentsScreen()) {
                        Label {
                            Text("Регулярные платежи")
                        } icon: {
                            IconBackground(systemName: "scroll.fill", backgroundColor: .orange)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Настройки")
            .background(GradientView().ignoresSafeArea())
        }
        .foregroundStyle(.black)
        // Шиты
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
                .foregroundColor(.white)
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

