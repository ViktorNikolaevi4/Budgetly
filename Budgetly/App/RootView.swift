import SwiftUI

private struct CloudKitServiceKey: EnvironmentKey {
    static let defaultValue: CloudKitService = CloudKitService()
}

extension EnvironmentValues {
    /// Здесь: ключ для вашего сервиса
    var cloudKitService: CloudKitService {
        get { self[CloudKitServiceKey.self] }
        set { self[CloudKitServiceKey.self] = newValue }
    }
}

struct RootView: View {
    // Берём ваш CloudKitService из environmentObject
    @Environment(\.cloudKitService) private var ckService: CloudKitService

    init() {}


    var body: some View {
        Group {
            if ckService.iCloudAvailable {
                // Если iCloud доступен — основной TabView
                ContentView()
            } else {
                // Иначе просим включить iCloud
                VStack(spacing: 16) {
                    Image(systemName: "icloud.slash")
                        .font(.system(size: 64))
                        .foregroundColor(.red)
                    Text("Пожалуйста, войдите в iCloud\nв настройках системы")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGray6).ignoresSafeArea())
            }
        }
        .animation(.easeInOut, value: ckService.iCloudAvailable)
    }
}

