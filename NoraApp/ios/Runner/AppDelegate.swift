import Flutter
import FamilyControls
import ManagedSettings
import DeviceActivity
import SwiftUI
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  private let usageChannel = "com.nora.nora_app/usage_tracker"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // ─── Focus Protection Channel ───
    let focusChannel = FlutterMethodChannel(
      name: "com.nora.nora_app/focus_protection",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    focusChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "getStatus":
        result(self.focusProtectionStatus())
      case "requestAuthorization":
        Task {
          do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            result(self.focusProtectionStatus())
          } catch {
            result(FlutterError(
              code: "AUTHORIZATION_FAILED",
              message: error.localizedDescription,
              details: nil
            ))
          }
        }
      case "selectApps":
        guard AuthorizationCenter.shared.authorizationStatus == .approved else {
          result(FlutterError(
            code: "NOT_AUTHORIZED",
            message: "Family Controls authorization is required before selecting apps.",
            details: nil
          ))
          return
        }
        presentFamilyActivityPicker(result: result)
      case "enableBlocking":
        FamilyActivityShieldStore.shared.enable()
        result(self.focusProtectionStatus())
      case "disableBlocking":
        FamilyActivityShieldStore.shared.disable()
        result(self.focusProtectionStatus())
      case "openSettings":
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(settingsUrl)
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    // ─── Usage Tracker Channel ───
    let usageChannel = FlutterMethodChannel(
      name: usageChannel,
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    usageChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "getUsageStats":
        let daysBack = call.arguments as? Int ?? 7
        result(self.getUsageStats(daysBack: daysBack))
      case "getTodayUsage":
        result(self.getTodayUsage())
      case "getWeeklyAppUsage":
        result(self.getWeeklyAppUsage())
      case "getAppUsage":
        guard let args = call.arguments as? [String: Any],
              let packageName = args["packageName"] as? String else {
          result(["success": false, "error": "Package name required"])
          return
        }
        let daysBack = args["daysBack"] as? Int ?? 7
        result(self.getAppUsage(packageName: packageName, daysBack: daysBack))
      case "requestAuthorization":
        Task {
          do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            result(["success": true, "authorized": true])
          } catch {
            result(["success": false, "error": error.localizedDescription])
          }
        }
      case "getAuthorizationStatus":
        let status = AuthorizationCenter.shared.authorizationStatus
        result(["status": String(describing: status)])
      case "startMonitoring":
        Task {
          do {
            try NoraDeviceActivityCenter.shared.startDailyMonitoring()
            result(["success": true])
          } catch {
            result(["success": false, "error": error.localizedDescription])
          }
        }
      case "stopMonitoring":
        NoraDeviceActivityCenter.shared.stopAllMonitoring()
        result(["success": true])
      case "isMonitoring":
        result(["isMonitoring": NoraDeviceActivityCenter.shared.isMonitoring])
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // MARK: - Focus Protection Status

  private func focusProtectionStatus() -> [String: Any] {
    let authorizationStatus = AuthorizationCenter.shared.authorizationStatus
    let authorized = authorizationStatus == .approved
    return [
      "supported": true,
      "authorized": authorized,
      "usageAccessGranted": false,  // iOS doesn't have Usage Access like Android
      "accessibilityGranted": false,  // iOS uses FamilyControls instead
      "blockingEnabled": authorized && FamilyActivityShieldStore.shared.isEnabled,
      "blockedPackages": [],  // iOS uses category tokens, not package names
      "message": authorized
        ? "Family Controls is ready. Selected apps can be shielded during focus sessions."
        : "Family Controls authorization is required before apps can be shielded.",
    ]
  }

  // MARK: - Usage Data

  private func getUsageStats(daysBack: Int) -> [String: Any] {
    let defaults = UserDefaults(suiteName: "group.com.nora.nora_app.screentime")

    guard let data = defaults?.data(forKey: "dailySummary"),
          let summary = try? JSONDecoder().decode(
            DeviceActivityMonitor.DailyUsageSummary.self,
            from: data
          ) else {
      // No real data available yet — return empty, not fake data
      return [
        "success": true,
        "daysBack": daysBack,
        "totalScreenTimeMinutes": 0,
        "socialMediaMinutes": 0,
        "entertainmentMinutes": 0,
        "productivityMinutes": 0,
        "appCount": 0,
        "apps": [] as [[String: Any]],
        "isDemo": true,
      ]
    }

    // Calculate totals from summary
    let totalMinutes = summary.totalMinutes
    let socialMediaMinutes = summary.categoryMinutes["social_media"] ?? 0
    let entertainmentMinutes = summary.categoryMinutes["entertainment"] ?? 0
    let productivityMinutes = summary.categoryMinutes["productivity"] ?? 0

    return [
      "success": true,
      "daysBack": daysBack,
      "totalScreenTimeMinutes": totalMinutes,
      "socialMediaMinutes": socialMediaMinutes,
      "entertainmentMinutes": entertainmentMinutes,
      "productivityMinutes": productivityMinutes,
      "appCount": summary.appSelections.count,
      "apps": getTopAppsFromSummary(summary),
    ]
  }

  private func getTodayUsage() -> [String: Any] {
    let defaults = UserDefaults(suiteName: "group.com.nora.nora_app.screentime")

    guard let data = defaults?.data(forKey: "dailySummary"),
          let summary = try? JSONDecoder().decode(
            DeviceActivityMonitor.DailyUsageSummary.self,
            from: data
          ) else {
      // No real data available yet — return empty, not fake data
      return [
        "success": true,
        "totalScreenTimeMinutes": 0,
        "socialMediaMinutes": 0,
        "appCount": 0,
        "apps": [] as [[String: Any]],
        "isDemo": true,
      ]
    }

    return [
      "success": true,
      "totalScreenTimeMinutes": summary.totalMinutes,
      "socialMediaMinutes": summary.categoryMinutes["social_media"] ?? 0,
      "appCount": summary.appSelections.count,
      "apps": getTopAppsFromSummary(summary),
    ]
  }

  private func getWeeklyAppUsage() -> [String: Any] {
    let defaults = UserDefaults(suiteName: "group.com.nora.nora_app.screentime")

    // Try to load raw usage records (kept for 7 days by DeviceActivityMonitor)
    guard let recordsData = defaults?.data(forKey: "deviceUsage"),
          let records = try? JSONDecoder().decode(
            [DeviceActivityMonitor.UsageRecord].self,
            from: recordsData
          ) else {
      // No real data available yet — return empty, not fake data
      return [
        "success": true,
        "days": [] as [[String: Any]],
        "isDemo": true,
      ]
    }

    let calendar = Calendar.current
    let now = Date()
    let todayWeekday = calendar.component(.weekday, from: now)
    // Convert to 0=Mon … 6=Sun
    let todayIndex = (todayWeekday + 5) % 7

    // Find Monday of this week
    guard let monday = calendar.date(
      byAdding: .day,
      value: -(todayIndex),
      to: calendar.startOfDay(for: now)
    ) else {
      return [
        "success": true,
        "days": [] as [[String: Any]],
        "isDemo": true,
      ]
    }

    // Group records by day index
    var dayBuckets: [[String: Int]] = Array(repeating: [:], count: 7)
    for record in records {
      guard record.timestamp >= monday else { continue }
      let dayOfWeek = calendar.component(.weekday, from: record.timestamp)
      let dayIndex = (dayOfWeek + 5) % 7
      guard dayIndex <= todayIndex else { continue }
      let minutes = Int(record.duration / 60)
      dayBuckets[dayIndex][record.category, default: 0] += minutes
    }

    // Build result: for each day, pick the top category
    var result: [[String: Any]] = []
    for i in 0..<7 {
      if i > todayIndex {
        result.append(["dayIndex": i, "appName": "", "minutes": 0, "category": ""])
        continue
      }
      let bucket = dayBuckets[i]
      if bucket.isEmpty {
        result.append(["dayIndex": i, "appName": "", "minutes": 0, "category": ""])
        continue
      }
      // Find category with most minutes
      if let top = bucket.max(by: { $0.value < $1.value }) {
        result.append([
          "dayIndex": i,
          "appName": top.key.replacingOccurrences(of: "_", with: " ").capitalized,
          "minutes": top.value,
          "category": top.key,
        ])
      } else {
        result.append(["dayIndex": i, "appName": "", "minutes": 0, "category": ""])
      }
    }

    return [
      "success": true,
      "days": result,
    ]
  }

  private func getDemoWeeklyAppUsage() -> [String: Any] {
    let now = Date()
    let calendar = Calendar.current
    let todayWeekday = calendar.component(.weekday, from: now)
    let todayIndex = (todayWeekday + 5) % 7

    let demoApps: [(name: String, category: String)] = [
      ("Instagram", "social_media"),
      ("YouTube", "entertainment"),
      ("WhatsApp", "messaging"),
      ("Chrome", "productivity"),
      ("TikTok", "social_media"),
      ("Spotify", "entertainment"),
      ("Telegram", "messaging"),
    ]

    var days: [[String: Any]] = []
    for i in 0..<7 {
      if i > todayIndex {
        days.append(["dayIndex": i, "appName": "", "minutes": 0, "category": ""])
      } else {
        let app = demoApps[i % demoApps.count]
        let minutes = 30 + (i * 13) % 120
        days.append([
          "dayIndex": i,
          "appName": app.name,
          "minutes": minutes,
          "category": app.category,
        ])
      }
    }

    return [
      "success": true,
      "days": days,
    ]
  }

  private func getAppUsage(packageName: String, daysBack: Int) -> [String: Any] {
    // iOS doesn't expose individual app usage by package name
    // We can only provide category-based data
    return [
      "success": true,
      "packageName": packageName,
      "appName": packageName,
      "totalMinutes": 0,
      "daysBack": daysBack,
      "dailyBreakdown": [],
      "note": "iOS provides category-based usage, not per-app data",
    ]
  }

  // MARK: - Demo Data (for testing/preview)

  private func getDemoUsageStats(daysBack: Int) -> [String: Any] {
    return [
      "success": true,
      "daysBack": daysBack,
      "totalScreenTimeMinutes": 245,
      "socialMediaMinutes": 82,
      "entertainmentMinutes": 45,
      "productivityMinutes": 98,
      "appCount": 12,
      "apps": [
        ["packageName": "com.instagram.ios", "appName": "Instagram", "totalTimeMinutes": 45, "category": "social_media"],
        ["packageName": "com.youtube.ios", "appName": "YouTube", "totalTimeMinutes": 38, "category": "entertainment"],
        ["packageName": "com.spotify.ios", "appName": "Spotify", "totalTimeMinutes": 32, "category": "entertainment"],
        ["packageName": "com.apple.mail", "appName": "Mail", "totalTimeMinutes": 28, "category": "productivity"],
        ["packageName": "com.slack.ios", "appName": "Slack", "totalTimeMinutes": 25, "category": "productivity"],
      ],
    ]
  }

  private func getDemoTodayUsage() -> [String: Any] {
    return [
      "success": true,
      "totalScreenTimeMinutes": 127,
      "socialMediaMinutes": 42,
      "appCount": 8,
      "apps": [
        ["packageName": "com.instagram.ios", "appName": "Instagram", "totalTimeMinutes": 22, "category": "social_media"],
        ["packageName": "com.twitter.ios", "appName": "Twitter", "totalTimeMinutes": 20, "category": "social_media"],
        ["packageName": "com.apple.mail", "appName": "Mail", "totalTimeMinutes": 18, "category": "productivity"],
      ],
    ]
  }

  private func getTopAppsFromSummary(_ summary: DeviceActivityMonitor.DailyUsageSummary) -> [[String: Any]] {
    return summary.appSelections.map { (token, minutes) in
      [
        "packageName": token,
        "appName": token,  // iOS tokens are opaque, can't resolve to names
        "totalTimeMinutes": minutes,
        "category": "unknown",
      ]
    }.sorted { ($0["totalTimeMinutes"] as? Int ?? 0) > ($1["totalTimeMinutes"] as? Int ?? 0) }
  }

  // MARK: - Family Activity Picker

  private func presentFamilyActivityPicker(result: @escaping FlutterResult) {
    guard let presenter = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .flatMap({ $0.windows })
      .first(where: { $0.isKeyWindow })?.rootViewController else {
      result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "No active iOS window is available.", details: nil))
      return
    }

    let picker = FamilyActivityPickerController { [weak presenter] selection in
      FamilyActivityShieldStore.shared.selection = selection
      presenter?.dismiss(animated: true)
      result(self.focusProtectionStatus())
    }
    presenter.present(picker, animated: true)
  }
}

// MARK: - Shield Store

private final class FamilyActivityShieldStore {
  static let shared = FamilyActivityShieldStore()
  var selection = FamilyActivitySelection()
  var isEnabled = false

  private let settingsStore = ManagedSettingsStore()

  func enable() {
    settingsStore.shield.applications = selection.applicationTokens
    settingsStore.shield.webDomains = selection.webDomainTokens
    isEnabled = true
  }

  func disable() {
    settingsStore.clearAllSettings()
    isEnabled = false
  }
}

// MARK: - Family Activity Picker Controller

private final class FamilyActivityPickerController: UIHostingController<FamilyActivityPickerView> {
  init(onDone: @escaping (FamilyActivitySelection) -> Void) {
    super.init(rootView: FamilyActivityPickerView(onDone: onDone))
  }

  @MainActor required dynamic init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

private struct FamilyActivityPickerView: View {
  @State private var selection = FamilyActivitySelection()
  let onDone: (FamilyActivitySelection) -> Void

  var body: some View {
    NavigationStack {
      FamilyActivityPicker(selection: $selection)
        .navigationTitle("Apps to block")
        .toolbar {
          ToolbarItem(placement: .confirmationAction) {
            Button("Done") {
              onDone(selection)
            }
          }
        }
    }
  }
}
