/// AppInfo model — represents a scanned app on the device.
class AppInfo {
  final String packageName;
  final String appName;
  final bool isSystemApp;
  final String category;
  final int installTime;
  final int lastUpdateTime;
  final String versionName;
  final int targetSdk;
  final int usageTodayMinutes;
  final int usageWeekMinutes;
  final bool isBlocked;
  final bool aiRecommendedBlock;
  final String? iconBase64;

  const AppInfo({
    required this.packageName,
    required this.appName,
    required this.isSystemApp,
    required this.category,
    this.installTime = 0,
    this.lastUpdateTime = 0,
    this.versionName = '',
    this.targetSdk = 0,
    this.usageTodayMinutes = 0,
    this.usageWeekMinutes = 0,
    this.isBlocked = false,
    this.aiRecommendedBlock = false,
    this.iconBase64,
  });

  factory AppInfo.fromMap(Map<String, dynamic> map) {
    return AppInfo(
      packageName: map['packageName'] ?? '',
      appName: map['appName'] ?? '',
      isSystemApp: map['isSystemApp'] ?? false,
      category: map['category'] ?? 'other',
      installTime: map['installTime'] ?? 0,
      lastUpdateTime: map['lastUpdateTime'] ?? 0,
      versionName: map['versionName'] ?? '',
      targetSdk: map['targetSdk'] ?? 0,
      usageTodayMinutes: map['usageTodayMinutes'] ?? 0,
      usageWeekMinutes: map['usageWeekMinutes'] ?? 0,
      isBlocked: map['isBlocked'] ?? false,
      aiRecommendedBlock: map['aiRecommendedBlock'] ?? false,
      iconBase64: map['iconBase64'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'appName': appName,
      'isSystemApp': isSystemApp,
      'category': category,
      'installTime': installTime,
      'lastUpdateTime': lastUpdateTime,
      'versionName': versionName,
      'targetSdk': targetSdk,
      'usageTodayMinutes': usageTodayMinutes,
      'usageWeekMinutes': usageWeekMinutes,
      'isBlocked': isBlocked,
      'aiRecommendedBlock': aiRecommendedBlock,
    };
  }

  AppInfo copyWith({
    String? packageName,
    String? appName,
    bool? isSystemApp,
    String? category,
    int? installTime,
    int? lastUpdateTime,
    String? versionName,
    int? targetSdk,
    int? usageTodayMinutes,
    int? usageWeekMinutes,
    bool? isBlocked,
    bool? aiRecommendedBlock,
    String? iconBase64,
  }) {
    return AppInfo(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      isSystemApp: isSystemApp ?? this.isSystemApp,
      category: category ?? this.category,
      installTime: installTime ?? this.installTime,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      versionName: versionName ?? this.versionName,
      targetSdk: targetSdk ?? this.targetSdk,
      usageTodayMinutes: usageTodayMinutes ?? this.usageTodayMinutes,
      usageWeekMinutes: usageWeekMinutes ?? this.usageWeekMinutes,
      isBlocked: isBlocked ?? this.isBlocked,
      aiRecommendedBlock: aiRecommendedBlock ?? this.aiRecommendedBlock,
      iconBase64: iconBase64 ?? this.iconBase64,
    );
  }

  /// Human-readable category name.
  String get categoryDisplayName {
    switch (category) {
      case 'social_media':
        return 'Social Media';
      case 'entertainment':
        return 'Entertainment';
      case 'games':
        return 'Games';
      case 'productivity':
        return 'Productivity';
      case 'messaging':
        return 'Messaging';
      case 'education':
        return 'Education';
      case 'news':
        return 'News';
      case 'photography':
        return 'Photography';
      case 'navigation':
        return 'Navigation';
      case 'finance':
        return 'Finance';
      case 'health':
        return 'Health';
      case 'shopping':
        return 'Shopping';
      case 'travel':
        return 'Travel';
      case 'utilities':
        return 'Utilities';
      default:
        return 'Other';
    }
  }

  /// Category icon.
  String get categoryEmoji {
    switch (category) {
      case 'social_media':
        return '📱';
      case 'entertainment':
        return '🎬';
      case 'games':
        return '🎮';
      case 'productivity':
        return '💼';
      case 'messaging':
        return '💬';
      case 'education':
        return '📚';
      case 'news':
        return '📰';
      case 'photography':
        return '📷';
      case 'navigation':
        return '🗺️';
      case 'finance':
        return '💰';
      case 'health':
        return '🏥';
      case 'shopping':
        return '🛒';
      case 'travel':
        return '✈️';
      case 'utilities':
        return '🔧';
      default:
        return '📦';
    }
  }

  /// Whether this app is likely a distraction.
  bool get isLikelyDistraction {
    return category == 'social_media' ||
        category == 'entertainment' ||
        category == 'games';
  }

  /// Whether this app is productive.
  bool get isProductive {
    return category == 'productivity' ||
        category == 'education' ||
        category == 'utilities';
  }
}

/// Usage stats summary for the device.
class UsageStatsSummary {
  final int totalScreenTimeMinutes;
  final int socialMediaMinutes;
  final int entertainmentMinutes;
  final int productivityMinutes;
  final int appCount;
  final List<AppUsageEntry> topApps;

  const UsageStatsSummary({
    required this.totalScreenTimeMinutes,
    required this.socialMediaMinutes,
    required this.entertainmentMinutes,
    required this.productivityMinutes,
    required this.appCount,
    required this.topApps,
  });

  factory UsageStatsSummary.fromMap(Map<String, dynamic> map) {
    return UsageStatsSummary(
      totalScreenTimeMinutes: map['totalScreenTimeMinutes'] ?? 0,
      socialMediaMinutes: map['socialMediaMinutes'] ?? 0,
      entertainmentMinutes: map['entertainmentMinutes'] ?? 0,
      productivityMinutes: map['productivityMinutes'] ?? 0,
      appCount: map['appCount'] ?? 0,
      topApps: (map['apps'] as List<dynamic>? ?? [])
          .map((a) => AppUsageEntry.fromMap(a))
          .toList(),
    );
  }

  String get totalScreenTimeDisplay {
    final hours = totalScreenTimeMinutes ~/ 60;
    final mins = totalScreenTimeMinutes % 60;
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins}m';
  }

  String get socialMediaTimeDisplay {
    final hours = socialMediaMinutes ~/ 60;
    final mins = socialMediaMinutes % 60;
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins}m';
  }

  double get distractionRatio {
    if (totalScreenTimeMinutes == 0) return 0;
    return (socialMediaMinutes + entertainmentMinutes) / totalScreenTimeMinutes;
  }
}

/// A single app usage entry.
class AppUsageEntry {
  final String packageName;
  final String appName;
  final int totalTimeMinutes;
  final int lastTimeUsed;
  final String category;

  const AppUsageEntry({
    required this.packageName,
    required this.appName,
    required this.totalTimeMinutes,
    required this.lastTimeUsed,
    required this.category,
  });

  factory AppUsageEntry.fromMap(Map<String, dynamic> map) {
    return AppUsageEntry(
      packageName: map['packageName'] ?? '',
      appName: map['appName'] ?? '',
      totalTimeMinutes: map['totalTimeMinutes'] ?? 0,
      lastTimeUsed: map['lastTimeUsed'] ?? 0,
      category: map['category'] ?? 'other',
    );
  }

  String get usageDisplay {
    final hours = totalTimeMinutes ~/ 60;
    final mins = totalTimeMinutes % 60;
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins}m';
  }
}
