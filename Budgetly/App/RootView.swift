import SwiftUI
import SwiftData


struct RootView: View {
    @Environment(\.authService) private var auth
    @State private var showLogin = true

    var body: some View {
        Group {
            if auth.cloudUserRecordID != nil || auth.firebaseUserID != nil {
              ContentView()
            } else {
                // Показываем flow логина/регистрации
                AuthFlowView(showLogin: $showLogin)
            }
        }
        .onAppear {
            // Как только запустились — пробуем достать из iCloud свой recordID
            auth.fetchCloudUserRecordID()
        }
    }
}


struct AuthFlowView: View {
    @Binding var showLogin: Bool

    var body: some View {
        NavigationStack {
            if showLogin {
                LoginView(onSwitchToRegister: { showLogin = false })
            } else {
                RegistrationView(onSwitchToLogin: { showLogin = true })
            }
        }
    }
}


