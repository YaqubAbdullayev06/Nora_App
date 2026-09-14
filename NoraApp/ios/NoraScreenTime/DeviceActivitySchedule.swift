import DeviceActivity
import Foundation

/// DeviceActivitySchedule configuration for Nora
///
/// This defines when and how often the DeviceActivityMonitor checks usage.
@available(iOS 16.0, *)
extension DeviceActivityName {
  /// Daily usage tracking schedule
  static let dailyUsage = Self("dailyUsage")

  /// Real-time monitoring during focus sessions
  static let focusSession = Self("focusSession")
}

@available(iOS 16.0, *)
extension DeviceActivitySchedule {

  /// Daily schedule - resets at midnight
  static func dailySchedule() -> DeviceActivitySchedule {
    let calendar = Calendar.current
    let start = calendar.dateComponents([.hour, .minute], from: calendar.startOfDay(for: Date()))
    let end = DateComponents(hour: 23, minute: 59)

    return DeviceActivitySchedule(
      intervalStart: start,
      intervalEnd: end,
      repeats: true
    )
  }

  /// Focus session schedule - immediate, limited duration
  static func focusSessionSchedule(durationMinutes: Int) -> DeviceActivitySchedule {
    let now = Date()
    let calendar = Calendar.current

    let start = calendar.dateComponents([.hour, .minute, .second], from: now)
    let end = calendar.dateComponents(
      [.hour, .minute, .second],
      from: calendar.date(byAdding: .minute, value: durationMinutes, to: now)!
    )

    return DeviceActivitySchedule(
      intervalStart: start,
      intervalEnd: end,
      repeats: false
    )
  }
}

/// DeviceActivity events for Nora
@available(iOS 16.0, *)
extension DeviceActivityEvent.Name {
  /// When an app is opened
  static let appOpened = Self("appOpened")

  /// When usage exceeds daily limit
  static let dailyLimitReached = Self("dailyLimitReached")

  /// When focus session is active
  static let focusSessionActive = Self("focusSessionActive")
}

/// DeviceActivity center for managing monitoring
@available(iOS 16.0, *)
class NoraDeviceActivityCenter {

  static let shared = NoraDeviceActivityCenter()

  private let center = DeviceActivityCenter()

  // MARK: - Public API

  /// Start daily usage monitoring
  func startDailyMonitoring() throws {
    let schedule = DeviceActivitySchedule.dailySchedule()

    // Events to monitor
    let events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [
      .appOpened: DeviceActivityEvent(
        threshold: .init(hour: 0, minute: 0)  // Immediate trigger
      ),
      .dailyLimitReached: DeviceActivityEvent(
        threshold: .init(hour: 8, minute: 0)  // After 8 hours
      ),
    ]

    try center.startMonitoring(
      .dailyUsage,
      during: schedule,
      events: events
    )

    print("[NoraScreenTime] Daily monitoring started")
  }

  /// Stop all monitoring
  func stopAllMonitoring() {
    center.stopMonitoring()
    print("[NoraScreenTime] All monitoring stopped")
  }

  /// Start focus session monitoring
  func startFocusMonitoring(durationMinutes: Int) throws {
    let schedule = DeviceActivitySchedule.focusSessionSchedule(
      durationMinutes: durationMinutes
    )

    let events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [
      .focusSessionActive: DeviceActivityEvent(
        threshold: .init(minute: 1)
      ),
    ]

    try center.startMonitoring(
      .focusSession,
      during: schedule,
      events: events
    )

    print("[NoraScreenTime] Focus monitoring started for \(durationMinutes) minutes")
  }

  /// Stop focus session monitoring
  func stopFocusMonitoring() {
    center.stopMonitoring(.focusSession)
    print("[NoraScreenTime] Focus monitoring stopped")
  }

  // MARK: - Status

  /// Check if monitoring is active
  var isMonitoring: Bool {
    center.isMonitoring(.dailyUsage) || center.isMonitoring(.focusSession)
  }
}
