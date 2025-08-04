import SwiftUI
import SwiftData

struct SettingsScreen: View {
    @Environment(\.cloudKitService) private var ckService: CloudKitService
    @Environment(\.modelContext) private var modelContext

    @State private var showClearAlert = false
    @State private var isClearing = false
    @State private var clearError: Error?

    init() {}

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
                    } else {
                        Text("Пожалуйста, включите iCloud в настройках системы")
                            .foregroundColor(.red)
                    }
                }

                // MARK: — Профиль iCloud
                if let name = ckService.displayName, !name.isEmpty {
                    Section("Профиль iCloud") {
                        Label(name, systemImage: "person.fill")
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
                Section {
                    Button(role: .destructive) {
                        showClearAlert = true
                    } label: {
                        Label("Удалить все данные", systemImage: "trash")
                    }
                    .disabled(isClearing)
                }

            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Настройки")
            .background(GradientView().ignoresSafeArea())
            .alert("Удалить все данные?", isPresented: $showClearAlert) {
                            Button("Удалить", role: .destructive) {
                                performFullReset()
                            }
                            Button("Отмена", role: .cancel) {}
                        } message: {
                            Text("Будут удалены все записи локально и в iCloud.")
                        }
                        .alert("Ошибка", isPresented: Binding(
                            get: { clearError != nil },
                            set: { if !$0 { clearError = nil } }
                        )) {
                            Button("OK", role: .cancel) {}
                        } message: {
                            Text(clearError?.localizedDescription ?? "")
                        }
                    }
        .foregroundStyle(.black)
//        .sheet(isPresented: $showAuthSheet) {
//            AuthSheet(showLogin: $showLogin)
//        }
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
    private func performFullReset() {
           isClearing = true

           // 1) удалить локально
           do {
               try clearLocalData(in: modelContext)
           } catch {
               clearError = error
               isClearing = false
               return
           }

           // 2) удалить из iCloud
           ckService.clearCloudKitData { result in
               DispatchQueue.main.async {
                   isClearing = false
                   switch result {
                   case .success:
                       // возможно, сбросить какие-то флаги в UserDefaults
                       break
                   case .failure(let err):
                       clearError = err
                   }
               }
           }
       }
}

//struct AuthSheet: View {
//    @Binding var showLogin: Bool
//    var body: some View {
//        NavigationStack {
//            if showLogin {
//                LoginView(onSwitchToRegister: { withAnimation { showLogin = false } })
//            } else {
//                RegistrationView(onSwitchToLogin: { withAnimation { showLogin = true } })
//            }
//        }
//    }
//}

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

