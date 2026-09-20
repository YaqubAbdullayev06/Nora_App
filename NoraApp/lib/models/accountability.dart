/// Represents a guardian-set accountability lock.
class AccountabilityLock {
  final bool isActive;
  final String? guardianName;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final bool isExpired;

  const AccountabilityLock({
    required this.isActive,
    this.guardianName,
    this.createdAt,
    this.expiresAt,
    this.isExpired = false,
  });

  factory AccountabilityLock.fromJson(Map<String, dynamic> json) {
    return AccountabilityLock(
      isActive: json['is_active'] ?? false,
      guardianName: json['guardian_name'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      isExpired: json['is_expired'] ?? false,
    );
  }

  bool get hasExpiry => expiresAt != null;

  Duration? get remainingTime {
    if (expiresAt == null) return null;
    final now = DateTime.now();
    if (now.isAfter(expiresAt!)) return Duration.zero;
    return expiresAt!.difference(now);
  }

  String get remainingTimeString {
    if (expiresAt == null) return 'Indefinite';
    final remaining = remainingTime;
    if (remaining == null || remaining == Duration.zero) return 'Expired';
    if (remaining.inDays > 0) return '${remaining.inDays}d remaining';
    if (remaining.inHours > 0) return '${remaining.inHours}h remaining';
    return '${remaining.inMinutes}m remaining';
  }
}
