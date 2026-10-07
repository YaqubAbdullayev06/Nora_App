import '../core/enums/age_group.dart';

/// User model for Nora app.
/// Supports age group classification for adaptive behavior.
class User {
  final String id;
  final String email;
  final String name;
  final AgeGroup ageGroup;
  final DateTime? birthDate;
  final int? age;
  final String? avatarUrl;
  final DateTime createdAt;
  final Map<String, dynamic>? settings;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.ageGroup,
    this.birthDate,
    this.age,
    this.avatarUrl,
    required this.createdAt,
    this.settings,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // M38: defensive — malformed dates / non-string urls / num ages must
    // not throw inside login or profile refresh.
    DateTime? tryParse(dynamic v) => v is String ? DateTime.tryParse(v) : null;
    final settings = json['settings'];
    final avatar = json['avatarUrl'] ?? json['avatar_url'];
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email'] is String ? json['email'] as String : '',
      name: json['name'] is String ? json['name'] as String : '',
      ageGroup: AgeGroup.values.firstWhere(
        (g) => g.name == (json['ageGroup'] ?? json['age_group']),
        orElse: () => AgeGroup.adult,
      ),
      birthDate: tryParse(json['birthDate'] ?? json['birth_date']),
      age: (json['age'] as num?)?.toInt(),
      avatarUrl: avatar is String ? avatar : null,
      createdAt: tryParse(json['created_at']) ??
          tryParse(json['createdAt']) ??
          DateTime.now(),
      settings: settings is Map
          ? Map<String, dynamic>.from(settings)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'ageGroup': ageGroup.name,
      'birthDate': birthDate?.toIso8601String(),
      'age': age,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
      'settings': settings,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    AgeGroup? ageGroup,
    DateTime? birthDate,
    int? age,
    String? avatarUrl,
    DateTime? createdAt,
    Map<String, dynamic>? settings,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      ageGroup: ageGroup ?? this.ageGroup,
      birthDate: birthDate ?? this.birthDate,
      age: age ?? this.age,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      settings: settings ?? this.settings,
    );
  }

  bool get requiresParentalControl => ageGroup.requiresParentalControl;
  int get maxFocusMinutes => ageGroup.maxFocusMinutes;
  int get defaultFocusMinutes => ageGroup.defaultFocusMinutes;
  int get screenTimeLimitMinutes => ageGroup.screenTimeLimitMinutes;
}
