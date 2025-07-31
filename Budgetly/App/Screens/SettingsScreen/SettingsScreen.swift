import SwiftUI
import SwiftData

struct SettingsScreen: View {
    @Environment(\.authService) private var auth
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
                    if auth.currentEmail == nil {
                        Button {
                            showLogin = false
                            showAuthSheet = true
                        } label: {
                            Label("Войти / Регистрация", systemImage: "person.crop.circle")
                        }
                    } else {
                        NavigationLink(destination: AccountDetailView()) {
                            if let name = auth.currentName, !name.isEmpty {
                                Label(name, systemImage: "person.fill")
                            } else if let email = auth.originalEmail {
                                Label(email, systemImage: "envelope.fill") // Используем originalEmail
                            } else {
                                Label(auth.currentEmail!, systemImage: "envelope.fill") // Резервный вариант
                            }
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
                    if accounts.isEmpty {
                        Text("Сначала создайте счет")
                            .foregroundColor(.secondary)
                    } else {
                        NavigationLink {
                            RegularPaymentsScreen()
                        } label: {
                            Label {
                                Text("Регулярные платежи")
                            } icon: {
                                IconBackground(
                                    systemName: "scroll.fill",
                                    backgroundColor: Color(red: 80/255, green: 127/255, blue: 252/255)
                                )
                            }
                        }
                    }
                }
                if auth.currentEmail != nil {
                    Section {
                        Button("Выйти") {
                            auth.logout()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Настройки")
            .background(GradientView().ignoresSafeArea())
        }
        .foregroundStyle(.black)
        .sheet(isPresented: $showAuthSheet) {
            AuthSheet(showLogin: $showLogin)
        }
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

struct AuthSheet: View {
    @Binding var showLogin: Bool
    var body: some View {
        NavigationStack {
            if showLogin {
                LoginView(onSwitchToRegister: { withAnimation { showLogin = false } })
            } else {
                RegistrationView(onSwitchToLogin: { withAnimation { showLogin = true } })
            }
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

//struct SettingsScreen: View {
//    @Query private var accounts: [Account]
//    @State private var showShareSheet = false
//    @State private var showRateSheet = false
//    @State private var showContactDeveloperSheet = false
//
//    var body: some View {
//        NavigationStack {
//            List {
//                // MARK: — Аккаунт
//                Section {
//                    NavigationLink(destination: RegistrationView()) {
//                        Label {
//                            Text("Вход / Регистрация")
//                        } icon: {
//                            IconBackground(
//                                systemName: "person.crop.circle.fill",
//                                backgroundColor: Color(red: 255/255, green: 45/255, blue: 85/255)
//                            )
//                        }
//                    }
//                }
//
//                // MARK: — О приложении
//                Section {
//                    Button {
//                        showShareSheet = true
//                    } label: {
//                        Label {
//                            Text("Поделиться с друзьями")
//                        } icon: {
//                            IconBackground(
//                                systemName: "square.and.arrow.up",
//                                backgroundColor: Color(red: 194/255, green: 98/255, blue: 228/255)
//                            )
//                        }
//                    }
//
//                    Button {
//                        showRateSheet = true
//                    } label: {
//                        Label {
//                            Text("Оценить приложение")
//                        } icon: {
//                            IconBackground(systemName: "star.fill", backgroundColor: .yellow)
//                        }
//                    }
//
//                    Button {
//                        showContactDeveloperSheet = true
//                    } label: {
//                        Label {
//                            Text("Написать разработчикам")
//                        } icon: {
//                            IconBackground(
//                                systemName: "envelope.fill",
//                                backgroundColor: Color(red: 0/255, green: 184/255, blue: 148/255)
//                            )
//                        }
//                    }
//                }
//              //  "scroll.fill"
//                // MARK: — Дополнительно (только Регулярные платежи)
//                Section {
//                    if accounts.isEmpty {
//                        Text("Сначала создайте счет")
//                            .foregroundColor(.secondary)
//                    } else {
//                        NavigationLink {
//                            RegularPaymentsScreen()
//                        } label: {
//                            Label {
//                                Text("Регулярные платежи")
//                            } icon: {
//                                IconBackground(
//                                    systemName: "scroll.fill",
//                                    backgroundColor: Color(red: 80/255, green: 127/255, blue: 252/255)
//                                )
//                            }
//                        }
//                    }
//                }
//            }
//            .listStyle(InsetGroupedListStyle())
//            .navigationTitle("Настройки")
//            .background(GradientView().ignoresSafeArea())
//        }
//        .foregroundStyle(.black)
//        // Шиты
//        .sheet(isPresented: $showShareSheet) {
//            ShareSheet(items: ["Проверьте наше приложение! https://apps.apple.com/app/idXXXXXXXXX"])
//        }
//        .sheet(isPresented: $showRateSheet) {
//            RateAppView(isPresented: $showRateSheet)
//        }
//        .sheet(isPresented: $showContactDeveloperSheet) {
//            ContactDeveloperView()
//        }
//    }
//}
