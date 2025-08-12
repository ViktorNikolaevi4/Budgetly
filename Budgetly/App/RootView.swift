import SwiftUI
import CloudKit

private struct CloudKitServiceKey: EnvironmentKey {
    @MainActor
    static var defaultValue: CloudKitService {
        CloudKitService() // сюда попадём только если забыли .environment(...)
    }
}


extension EnvironmentValues {
    /// Здесь: ключ для вашего сервиса
    var cloudKitService: CloudKitService {
        get { self[CloudKitServiceKey.self] }
        set { self[CloudKitServiceKey.self] = newValue }
    }
}

struct RootView: View {
    @Environment(\.cloudKitService) private var ckService
    @Environment(\.scenePhase) private var scenePhase
    @State private var hideICloudBanner = false   // было @AppStorage

    var body: some View {
        ZStack(alignment: .top) {
            ContentView()

            if ckService.lastStatus != .available && !hideICloudBanner {
                banner
            }
        }
        // каждый раз, когда приложение становится активным — снова показываем
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                hideICloudBanner = false
            }
        }
        .animation(.easeInOut, value: ckService.lastStatus)
    }

    private var banner: some View {
        VStack(spacing: 8) {
            Text(message(for: ckService.lastStatus)).font(.subheadline)

            HStack {
                Button("Повторить") {
                    Task { await ckService.refresh() }   // ← обёртка
                }
                Button("Настройки iCloud") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
            .buttonStyle(.borderedProminent)

            Button("Отмена") { hideICloudBanner = true }
                .buttonStyle(.bordered)
                .tint(.primary)
        }
    }


        private func message(for s: CKAccountStatus) -> String {
            switch s {
            case .noAccount: return "На устройстве не выполнен вход в iCloud."
            case .restricted: return "Доступ к iCloud ограничен (тумблер приложения/ограничения)."
            case .temporarilyUnavailable: return "iCloud временно недоступен. Работаем офлайн."
            case .couldNotDetermine: return "Не удалось определить статус iCloud. Проверьте сеть."
            default: return ""
            }
        }
    }

