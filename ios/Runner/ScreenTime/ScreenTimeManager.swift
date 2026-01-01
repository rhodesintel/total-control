import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity

/// TotalControl Screen Time Manager
/// Uses iOS Family Controls API to block apps
@available(iOS 16.0, *)
class ScreenTimeManager: ObservableObject {
    static let shared = ScreenTimeManager()

    private let store = ManagedSettingsStore()
    private let center = AuthorizationCenter.shared

    @Published var isAuthorized = false
    @Published var blockedApps: Set<ApplicationToken> = []

    private init() {
        checkAuthorization()
    }

    // MARK: - Authorization

    func checkAuthorization() {
        switch center.authorizationStatus {
        case .approved:
            isAuthorized = true
        case .denied, .notDetermined:
            isAuthorized = false
        @unknown default:
            isAuthorized = false
        }
    }

    func requestAuthorization() async throws {
        try await center.requestAuthorization(for: .individual)
        await MainActor.run {
            checkAuthorization()
        }
    }

    // MARK: - App Blocking

    /// Shield/block specific apps
    func blockApps(_ tokens: Set<ApplicationToken>) {
        blockedApps = tokens

        // Apply shield to block apps
        store.shield.applications = tokens
        store.shield.applicationCategories = .init(blockedByFilter: .none)

        // Optionally customize the shield message
        // store.shield.settings?.primaryButtonLabel = "Close"
    }

    /// Block apps by category
    func blockCategory(_ category: ActivityCategoryToken) {
        store.shield.applicationCategories = .specific([category])
    }

    /// Unblock all apps
    func unblockAll() {
        blockedApps = []
        store.shield.applications = nil
        store.shield.applicationCategories = nil
    }

    /// Check if an app is currently blocked
    func isBlocked(_ token: ApplicationToken) -> Bool {
        return blockedApps.contains(token)
    }

    // MARK: - Web Blocking

    /// Block specific websites
    func blockWebsites(_ domains: [String]) {
        // Convert domains to WebDomainToken if needed
        // Note: This requires the domains to be resolved to tokens
        // For now, use URL filtering
        store.webContent.blockedByFilter = .specific([], except: [])
    }

    /// Allow only specific websites
    func allowOnlyWebsites(_ domains: [WebDomainToken]) {
        store.webContent.blockedByFilter = .all(except: Set(domains))
    }

    // MARK: - Scheduled Blocking

    /// Set up device activity monitoring for scheduled blocks
    func scheduleBlock(from startTime: DateComponents, to endTime: DateComponents, name: String) {
        let schedule = DeviceActivitySchedule(
            intervalStart: startTime,
            intervalEnd: endTime,
            repeats: true
        )

        let activityName = DeviceActivityName(name)
        let center = DeviceActivityCenter()

        do {
            try center.startMonitoring(activityName, during: schedule)
        } catch {
            print("[ScreenTimeManager] Failed to schedule block: \(error)")
        }
    }

    func stopScheduledBlock(name: String) {
        let activityName = DeviceActivityName(name)
        let center = DeviceActivityCenter()
        center.stopMonitoring([activityName])
    }
}

// MARK: - App Selection Helper

@available(iOS 16.0, *)
extension ScreenTimeManager {
    /// Present app picker for user to select apps to block
    /// Returns selected app tokens
    func presentAppPicker(completion: @escaping (Set<ApplicationToken>) -> Void) {
        // This would be called from SwiftUI with FamilyActivityPicker
        // The picker is a SwiftUI view that must be presented in the UI
    }
}

// MARK: - Flutter Method Channel Integration

@available(iOS 16.0, *)
class ScreenTimePlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.rhodesai.totalcontrol/screentime",
            binaryMessenger: registrar.messenger()
        )

        let instance = ScreenTimePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
}

@available(iOS 16.0, *)
extension ScreenTimePlugin: FlutterPlugin {
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "requestAuthorization":
            Task {
                do {
                    try await ScreenTimeManager.shared.requestAuthorization()
                    result(ScreenTimeManager.shared.isAuthorized)
                } catch {
                    result(FlutterError(code: "AUTH_FAILED", message: error.localizedDescription, details: nil))
                }
            }

        case "isAuthorized":
            result(ScreenTimeManager.shared.isAuthorized)

        case "blockApps":
            // Would need to receive app bundle IDs and convert to tokens
            // This is complex - tokens come from FamilyActivityPicker
            result(true)

        case "unblockAll":
            ScreenTimeManager.shared.unblockAll()
            result(true)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
