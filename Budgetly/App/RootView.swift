import SwiftUI
import CloudKit
import SwiftData

private struct CloudKitServiceKey: EnvironmentKey {
    @MainActor
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
    @Environment(\.cloudKitService) private var ckService
    @Environment(\.scenePhase) private var scenePhase
    @State private var hideICloudBanner = false

    var body: some View {
        ZStack(alignment: .top) {
            ContentView() // твой основной контент

            if ckService.lastStatus != .available && !hideICloudBanner {
                banner
                    .padding()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        // авто-проверка при запуске
        .task { await ckService.refresh() }
        // и при возврате в foreground
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                hideICloudBanner = false
                Task { await ckService.refresh() }
            }
        }
        .animation(.easeInOut, value: ckService.lastStatus)
    }

    private var banner: some View {
        VStack(spacing: 8) {
            Text(message(for: ckService.lastStatus))
                .font(.subheadline)

            HStack {
                Button("Повторить") { Task { await ckService.refresh() } }
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
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }

    private func message(for s: CKAccountStatus) -> String {
        switch s {
        case .noAccount:              return "На устройстве не выполнен вход в iCloud."
        case .restricted:             return "Доступ к iCloud ограничен."
        case .temporarilyUnavailable: return "iCloud временно недоступен. Работаем офлайн."
        case .couldNotDetermine:      return "Не удалось определить статус iCloud. Проверьте сеть."
        default:                      return ""
        }
    }
}

enum Bootstrap {
    @AppStorage("didSeed_v1") private static var didSeed = false

    @MainActor
    static func run(in ctx: ModelContext) {
        guard !didSeed else { return }

        do {
            // Уже есть аккаунты? Ничего не делаем
            let hasAny = try ctx.fetchCount(FetchDescriptor<Account>()) > 0
            guard !hasAny else { didSeed = true; return }

            // Создаём "Основной счёт"
            let acc = Account(
                name: "Основной счёт",
                currency: "RUB",
                initialBalance: 0,
                sortOrder: 0
            )
            ctx.insert(acc)

            // Засеваем дефолтные категории для этого счёта
            Category.seedDefaults(for: acc, in: ctx)

            try ctx.save()
            didSeed = true
        } catch {
            print("Bootstrap failed:", error)
        }
    }
}

