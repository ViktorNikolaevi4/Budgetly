import SwiftUI

struct RootView: View {
    @Environment(\.authService) private var auth
    @State private var showLogin = false   // переключатель между регистрацией и входом

    var body: some View {
        Group {
            if auth.currentEmail != nil {
                ContentView()
            } else {
                AuthFlowView(showLogin: $showLogin)
            }
        }
        .animation(.easeInOut, value: auth.currentEmail)
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


