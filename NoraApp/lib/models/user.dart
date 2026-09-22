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
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      ageGroup: AgeGroup.values.firstWhere(
        (g) =>
            g.name == (json['ageGroup'] ?? json['age_group']),
        orElse: () => AgeGroup.adult,
      ),
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'])
          : null,
      age: json['age'],
      avatarUrl: json['avatarUrl'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      settings: json['settings'],
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
