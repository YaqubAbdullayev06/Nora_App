import Flutter
import FamilyControls
import ManagedSettings
import SwiftUI
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "com.nora.nora_app/focus_protection",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
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
        result(focusProtectionStatus())
      case "disableBlocking":
        FamilyActivityShieldStore.shared.disable()
        result(focusProtectionStatus())
      case "openSettings":
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(settingsUrl)
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func focusProtectionStatus() -> [String: Any] {
    let authorizationStatus = AuthorizationCenter.shared.authorizationStatus
    let authorized = authorizationStatus == .approved
    return [
      "supported": true,
      "authorized": authorized,
      "usageAccessGranted": false,
      "accessibilityGranted": false,
      "blockingEnabled": authorized && FamilyActivityShieldStore.shared.isEnabled,
      "blockedPackages": [],
      "message": authorized
        ? "Family Controls is ready. Selected apps can be shielded during focus sessions."
        : "Family Controls authorization is required before apps can be shielded.",
    ]
  }

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

private final class FamilyActivityShieldStore {
  static let shared = FamilyActivityShieldStore()
  var selection = FamilyActivitySelection()
  var isEnabled = false

  private let settingsStore = ManagedSettingsStore()

  func enable() {
    settingsStore.shield.applications = selection.applicationTokens
    isEnabled = true
  }

  func disable() {
    settingsStore.clearAllSettings()
    isEnabled = false
  }
}

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
