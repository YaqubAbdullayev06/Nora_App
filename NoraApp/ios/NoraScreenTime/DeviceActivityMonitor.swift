import DeviceActivity
import FamilyControls
import ManagedSettings
import Foundation

/// NoraScreenTime DeviceActivityMonitor Extension
///
/// This extension runs in the background and tracks device usage.
/// It stores usage data that can be queried by the main app.
///
/// IMPORTANT: This extension runs in a separate process and has limited
/// access to shared resources. Use App Groups for data sharing.
@available(iOS 16.0, *)
class DeviceActivityMonitor: DeviceActivityMonitor {

  // MARK: - Types

  struct UsageRecord: Codable {
    let timestamp: Date
    let category: String
    let selectionTokens: Data
    let duration: TimeInterval
  }

  struct DailyUsageSummary: Codable {
    let date: Date
    var totalMinutes: Int
    var categoryMinutes: [String: Int]
    var pickUpCount: Int
    var appSelections: [String: Int]  // token hash -> minutes
  }

  // MARK: - Constants

  private let appGroupID = "group.com.nora.nora_app.screentime"
  private let usageKey = "deviceUsage"
  private let summaryKey = "dailySummary"

  // MARK: - Lifecycle

  override func intervalDidStart(for schedule: DeviceActivityName) {
    super.intervalDidStart(for: schedule)
    print("[NoraScreenTime] Interval started: \(schedule.rawValue)")

    // Reset daily summary at start of new interval
    resetDailySummary()
  }

  override func intervalDidEnd(for schedule: DeviceActivityName) {
    super.intervalDidEnd(for: schedule)
    print("[NoraScreenTime] Interval ended: \(schedule.rawValue)")

    // Save final daily summary
    saveDailySummary()
  }

  override func eventDidReachThreshold(
    _ event: DeviceActivityEvent.Name,
    activity: DeviceActivityName
  ) {
    super.eventDidReachThreshold(event, activity: activity)
    print("[NoraScreenTime] Event threshold reached: \(event.rawValue)")

    // Record threshold event
    recordEvent(event)
  }

  override func intervalWillStart(for schedule: DeviceActivityName) {
    super.intervalWillStart(for: schedule)
    print("[NoraScreenTime] Interval will start: \(schedule.rawValue)")
  }

  override func intervalWillEnd(for schedule: DeviceActivityName) {
    super.intervalWillEnd(for: schedule)
    print("[NoraScreenTime] Interval will end: \(schedule.rawValue)")
  }

  // MARK: - Data Management

  private func resetDailySummary() {
    guard let defaults = UserDefaults(suiteName: appGroupID) else { return }

    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())

    // Check if we already have a summary for today
    if let existingData = defaults.data(forKey: summaryKey),
       let existing = try? JSONDecoder().decode(DailyUsageSummary.self, from: existingData),
       calendar.isDate(existing.date, inSameDayAs: today) {
      // Already have today's summary, keep it
      return
    }

    // Create new summary for today
    let summary = DailyUsageSummary(
      date: today,
      totalMinutes: 0,
      categoryMinutes: [:],
      pickUpCount: 0,
      appSelections: [:]
    )

    if let data = try? JSONEncoder().encode(summary) {
      defaults.set(data, forKey: summaryKey)
    }
  }

  private func saveDailySummary() {
    guard let defaults = UserDefaults(suiteName: appGroupID) else { return }

    if let data = defaults.data(forKey: summaryKey),
       var summary = try? JSONDecoder().decode(DailyUsageSummary.self, from: data) {
      // Recalculate from raw usage records
      let records = loadUsageRecords()
      let calendar = Calendar.current
      let todayRecords = records.filter { calendar.isDate($0.timestamp, inSameDayAs: Date()) }

      summary.totalMinutes = Int(todayRecords.reduce(0) { $0 + $1.duration } / 60)

      var categoryMinutes: [String: Int] = [:]
      for record in todayRecords {
        categoryMinutes[record.category, default: 0] += Int(record.duration / 60)
      }
      summary.categoryMinutes = categoryMinutes

      if let data = try? JSONEncoder().encode(summary) {
        defaults.set(data, forKey: summaryKey)
      }
    }
  }

  private func recordEvent(_ event: DeviceActivityEvent.Name) {
    // Record significant events (app opened, threshold reached, etc.)
    guard let defaults = UserDefaults(suiteName: appGroupID) else { return }

    var events = defaults.array(forKey: "events") as? [[String: Any]] ?? []
    events.append([
      "event": event.rawValue,
      "timestamp": Date().timeIntervalSince1970,
    ])

    // Keep last 100 events
    if events.count > 100 {
      events = Array(events.suffix(100))
    }

    defaults.set(events, forKey: "events")
  }

  private func loadUsageRecords() -> [UsageRecord] {
    guard let defaults = UserDefaults(suiteName: appGroupID),
          let data = defaults.data(forKey: usageKey),
          let records = try? JSONDecoder().decode([UsageRecord].self, from: data) else {
      return []
    }
    return records
  }

  private func saveUsageRecords(_ records: [UsageRecord]) {
    guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
    if let data = try? JSONEncoder().encode(records) {
      defaults.set(data, forKey: usageKey)
    }
  }
}

// MARK: - Extension Entry Point

@available(iOS 16.0, *)
extension DeviceActivityMonitor {

  /// Called when the extension needs to record usage data
  func recordUsage(category: String, duration: TimeInterval, tokens: Data) {
    var records = loadUsageRecords()

    let record = UsageRecord(
      timestamp: Date(),
      category: category,
      selectionTokens: tokens,
      duration: duration
    )

    records.append(record)

    // Keep last 7 days of records
    let calendar = Calendar.current
    let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
    records = records.filter { $0.timestamp > weekAgo }

    saveUsageRecords(records)

    // Update daily summary
    if let defaults = UserDefaults(suiteName: appGroupID),
       let data = defaults.data(forKey: summaryKey),
       var summary = try? JSONDecoder().decode(DailyUsageSummary.self, from: data) {
      summary.totalMinutes += Int(duration / 60)
      summary.categoryMinutes[category, default: 0] += Int(duration / 60)
      if let data = try? JSONEncoder().encode(summary) {
        defaults.set(data, forKey: summaryKey)
      }
    }
  }
}
