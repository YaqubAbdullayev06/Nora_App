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

  /// Create a User from JSON.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      ageGroup: AgeGroup.values.firstWhere(
        (g) => g.name == json['ageGroup'],
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

  /// Convert User to JSON.
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

  /// Create a copy with updated fields.
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

  /// Whether this user requires parental controls.
  bool get requiresParentalControl => ageGroup.requiresParentalControl;

  /// Max focus session duration for this user.
  int get maxFocusMinutes => ageGroup.maxFocusMinutes;

  /// Default focus session duration for this user.
  int get defaultFocusMinutes => ageGroup.defaultFocusMinutes;

  /// Screen time daily limit for this user.
  int get screenTimeLimitMinutes => ageGroup.screenTimeLimitMinutes;
}

/// Content item model for feed and content management.
class ContentItem {
  final String id;
  final String title;
  final String description;
  final String category;
  final String contentType;
  final int durationMinutes;
  final int points;
  final List<String> tags;
  final String? imageUrl;
  final String? author;
  final String? takeaway;
  final List<String> keyPoints;

  const ContentItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.contentType,
    required this.durationMinutes,
    required this.points,
    this.tags = const [],
    this.imageUrl,
    this.author,
    this.takeaway,
    this.keyPoints = const [],
  });

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    return ContentItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      contentType: json['content_type'] ?? json['contentType'] ?? 'article',
      durationMinutes: json['duration_minutes'] ?? json['durationMinutes'] ?? 0,
      points: json['points'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      imageUrl: json['imageUrl'] ?? json['image_url'],
      author: json['author'],
      takeaway: json['takeaway'],
      keyPoints: List<String>.from(json['keyPoints'] ?? json['key_points'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'contentType': contentType,
      'durationMinutes': durationMinutes,
      'points': points,
      'tags': tags,
      'imageUrl': imageUrl,
      'author': author,
      'takeaway': takeaway,
      'keyPoints': keyPoints,
    };
  }
}

/// Focus session model for tracking work sessions.
class FocusSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final int pointsEarned;
  final bool completed;

  const FocusSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.durationMinutes,
    required this.pointsEarned,
    required this.completed,
  });

  factory FocusSession.fromJson(Map<String, dynamic> json) {
    return FocusSession(
      id: json['id']?.toString() ?? '',
      startTime: DateTime.parse(json['started_at'] ?? json['startTime'] ?? DateTime.now().toIso8601String()),
      endTime: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'])
          : json['endTime'] != null
              ? DateTime.parse(json['endTime'])
              : null,
      durationMinutes: json['duration_minutes'] ?? json['durationMinutes'] ?? 0,
      pointsEarned: json['points_earned'] ?? json['pointsEarned'] ?? 0,
      completed: json['completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'durationMinutes': durationMinutes,
      'pointsEarned': pointsEarned,
      'completed': completed,
    };
  }
}

/// AI recommendation model.
class AIRecommendation {
  final String id;
  final String title;
  final String description;
  final String type;
  final double confidence;

  const AIRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.confidence,
  });

  factory AIRecommendation.fromJson(Map<String, dynamic> json) {
    return AIRecommendation(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? '',
      confidence: (json['confidence'] ?? 0).toDouble(),
    );
  }
}

/// Focus score model.
class FocusScore {
  final int score;
  final int totalMinutes;
  final int sessions;

  const FocusScore({
    required this.score,
    required this.totalMinutes,
    required this.sessions,
  });

  factory FocusScore.fromJson(Map<String, dynamic> json) {
    return FocusScore(
      score: json['score'] ?? 0,
      totalMinutes: json['totalMinutes'] ?? 0,
      sessions: json['sessions'] ?? 0,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// WEEKLY REVIEW MODELS
// ═══════════════════════════════════════════════════════════════

/// Mood options for weekly review.
enum WeeklyMood {
  amazing,
  good,
  okay,
  tough,
  rough;

  /// Asset path for mood SVG illustration.
  String get assetPath {
    switch (this) {
      case WeeklyMood.amazing:
        return 'assets/images/moods/mood_amazing.svg';
      case WeeklyMood.good:
        return 'assets/images/moods/mood_good.svg';
      case WeeklyMood.okay:
        return 'assets/images/moods/mood_okay.svg';
      case WeeklyMood.tough:
        return 'assets/images/moods/mood_tough.svg';
      case WeeklyMood.rough:
        return 'assets/images/moods/mood_rough.svg';
    }
  }

  /// Display label for the mood.
  String get label {
    switch (this) {
      case WeeklyMood.amazing:
        return 'Amazing';
      case WeeklyMood.good:
        return 'Good';
      case WeeklyMood.okay:
        return 'Okay';
      case WeeklyMood.tough:
        return 'Tough';
      case WeeklyMood.rough:
        return 'Rough';
    }
  }

  /// Primary color for the mood.
  int get colorValue {
    switch (this) {
      case WeeklyMood.amazing:
        return 0xFFFFD93D; // Gold/Yellow
      case WeeklyMood.good:
        return 0xFF60A5FA; // Blue
      case WeeklyMood.okay:
        return 0xFFA78BFA; // Purple
      case WeeklyMood.tough:
        return 0xFF93C5FD; // Light Blue
      case WeeklyMood.rough:
        return 0xFF6B8DB5; // Muted Blue
    }
  }
}

/// A reflection entry for weekly review.
class WeeklyReflection {
  final String id;
  final String question;
  final String answer;
  final DateTime createdAt;

  const WeeklyReflection({
    required this.id,
    required this.question,
    required this.answer,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory WeeklyReflection.fromJson(Map<String, dynamic> json) {
    return WeeklyReflection(
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

/// A weekly goal.
class WeeklyGoal {
  final String id;
  final String title;
  final int targetMinutes;
  final int completedMinutes;
  final bool isCompleted;
  final DateTime createdAt;

  const WeeklyGoal({
    required this.id,
    required this.title,
    required this.targetMinutes,
    this.completedMinutes = 0,
    this.isCompleted = false,
    required this.createdAt,
  });

  double get progress =>
      targetMinutes > 0 ? (completedMinutes / targetMinutes).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'targetMinutes': targetMinutes,
      'completedMinutes': completedMinutes,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory WeeklyGoal.fromJson(Map<String, dynamic> json) {
    return WeeklyGoal(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      targetMinutes: json['targetMinutes'] ?? 0,
      completedMinutes: json['completedMinutes'] ?? 0,
      isCompleted: json['isCompleted'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  WeeklyGoal copyWith({
    String? id,
    String? title,
    int? targetMinutes,
    int? completedMinutes,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return WeeklyGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      completedMinutes: completedMinutes ?? this.completedMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Complete weekly review summary.
class WeeklyReview {
  final String id;
  final DateTime weekStart;
  final DateTime weekEnd;
  final WeeklyMood? mood;
  final List<WeeklyReflection> reflections;
  final List<WeeklyGoal> goals;
  final int totalFocusMinutes;
  final int totalSessions;
  final int totalPointsEarned;
  final int streakDays;
  final String? aiInsight;
  final DateTime createdAt;

  const WeeklyReview({
    required this.id,
    required this.weekStart,
    required this.weekEnd,
    this.mood,
    this.reflections = const [],
    this.goals = const [],
    this.totalFocusMinutes = 0,
    this.totalSessions = 0,
    this.totalPointsEarned = 0,
    this.streakDays = 0,
    this.aiInsight,
    required this.createdAt,
  });

  /// Get age-appropriate reflection prompts.
  static List<String> getReflectionPrompts(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.baby:
        return [
          'What made you happy this week?',
          'What was your favorite thing to learn?',
          'What do you want to learn next week?',
        ];
      case AgeGroup.child:
        return [
          'What made you smile this week?',
          'What was fun to learn about?',
          'What do you want to try next week?',
        ];
      case AgeGroup.kid:
        return [
          'What was the coolest thing you learned this week?',
          'What was challenging and how did you handle it?',
          'What are you most proud of this week?',
          'What do you want to get better at next week?',
        ];
      case AgeGroup.teen:
        return [
          'What went well this week with your focus?',
          'What distracted you the most?',
          'How did you handle stress or pressure?',
          'What would you do differently next week?',
          'What habit do you want to build or break?',
        ];
      case AgeGroup.adult:
        return [
          'What were your biggest wins this week?',
          'What tasks did you procrastinate on?',
          'How was your work-life balance?',
          'What energy management strategies worked?',
          'What will you commit to improving next week?',
          'Rate your overall productivity (1-10).',
        ];
    }
  }

  /// Get default weekly goals based on age group.
  static List<WeeklyGoal> getDefaultGoals(AgeGroup ageGroup) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    switch (ageGroup) {
      case AgeGroup.baby:
        return [
          WeeklyGoal(
            id: 'goal_1',
            title: 'Learning Time',
            targetMinutes: 15,
            createdAt: startOfWeek,
          ),
          WeeklyGoal(
            id: 'goal_2',
            title: 'Play & Explore',
            targetMinutes: 20,
            createdAt: startOfWeek,
          ),
        ];
      case AgeGroup.child:
        return [
          WeeklyGoal(
            id: 'goal_1',
            title: 'Fun Learning',
            targetMinutes: 20,
            createdAt: startOfWeek,
          ),
          WeeklyGoal(
            id: 'goal_2',
            title: 'Creative Play',
            targetMinutes: 25,
            createdAt: startOfWeek,
          ),
        ];
      case AgeGroup.kid:
        return [
          WeeklyGoal(
            id: 'goal_1',
            title: 'Study Focus',
            targetMinutes: 60,
            createdAt: startOfWeek,
          ),
          WeeklyGoal(
            id: 'goal_2',
            title: 'Reading Time',
            targetMinutes: 30,
            createdAt: startOfWeek,
          ),
          WeeklyGoal(
            id: 'goal_3',
            title: 'Creative Activities',
            targetMinutes: 20,
            createdAt: startOfWeek,
          ),
        ];
      case AgeGroup.teen:
        return [
          WeeklyGoal(
            id: 'goal_1',
            title: 'Deep Study Sessions',
            targetMinutes: 120,
            createdAt: startOfWeek,
          ),
          WeeklyGoal(
            id: 'goal_2',
            title: 'Skill Practice',
            targetMinutes: 60,
            createdAt: startOfWeek,
          ),
          WeeklyGoal(
            id: 'goal_3',
            title: 'Mindfulness',
            targetMinutes: 30,
            createdAt: startOfWeek,
          ),
        ];
      case AgeGroup.adult:
        return [
          WeeklyGoal(
            id: 'goal_1',
            title: 'Deep Work Hours',
            targetMinutes: 300,
            createdAt: startOfWeek,
          ),
          WeeklyGoal(
            id: 'goal_2',
            title: 'Learning & Growth',
            targetMinutes: 120,
            createdAt: startOfWeek,
          ),
          WeeklyGoal(
            id: 'goal_3',
            title: 'Exercise & Wellness',
            targetMinutes: 150,
            createdAt: startOfWeek,
          ),
          WeeklyGoal(
            id: 'goal_4',
            title: 'Side Projects',
            targetMinutes: 60,
            createdAt: startOfWeek,
          ),
        ];
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'weekStart': weekStart.toIso8601String(),
      'weekEnd': weekEnd.toIso8601String(),
      'mood': mood?.index,
      'reflections': reflections.map((r) => r.toJson()).toList(),
      'goals': goals.map((g) => g.toJson()).toList(),
      'totalFocusMinutes': totalFocusMinutes,
      'totalSessions': totalSessions,
      'totalPointsEarned': totalPointsEarned,
      'streakDays': streakDays,
      'aiInsight': aiInsight,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory WeeklyReview.fromJson(Map<String, dynamic> json) {
    return WeeklyReview(
      id: json['id'] ?? '',
      weekStart: DateTime.parse(json['weekStart'] ?? DateTime.now().toIso8601String()),
      weekEnd: DateTime.parse(json['weekEnd'] ?? DateTime.now().toIso8601String()),
      mood: json['mood'] != null
          ? WeeklyMood.values[json['mood']]
          : null,
      reflections: (json['reflections'] as List?)
              ?.map((r) => WeeklyReflection.fromJson(r))
              .toList() ??
          [],
      goals: (json['goals'] as List?)
              ?.map((g) => WeeklyGoal.fromJson(g))
              .toList() ??
          [],
      totalFocusMinutes: json['totalFocusMinutes'] ?? 0,
      totalSessions: json['totalSessions'] ?? 0,
      totalPointsEarned: json['totalPointsEarned'] ?? 0,
      streakDays: json['streakDays'] ?? 0,
      aiInsight: json['aiInsight'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// DAILY PLANNING MODELS
// ═══════════════════════════════════════════════════════════════

/// A single task within a daily plan.
class PlanTask {
  final String id;
  final String title;
  final int priority; // 1, 2, or 3
  final bool completed;
  final String? iconAsset; // SVG asset path for baby/kid visual tasks
  final DateTime? completedAt;

  const PlanTask({
    required this.id,
    required this.title,
    required this.priority,
    this.completed = false,
    this.iconAsset,
    this.completedAt,
  });

  factory PlanTask.fromJson(Map<String, dynamic> json) {
    return PlanTask(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      priority: json['priority'] ?? 1,
      completed: json['completed'] ?? false,
      iconAsset: json['iconAsset'],
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'priority': priority,
      'completed': completed,
      'iconAsset': iconAsset,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  PlanTask copyWith({
    String? id,
    String? title,
    int? priority,
    bool? completed,
    String? iconAsset,
    DateTime? completedAt,
  }) {
    return PlanTask(
      id: id ?? this.id,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      completed: completed ?? this.completed,
      iconAsset: iconAsset ?? this.iconAsset,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  String get priorityLabel {
    switch (priority) {
      case 1:
        return 'Must do';
      case 2:
        return 'Should do';
      case 3:
        return 'Nice to do';
      default:
        return 'Task';
    }
  }
}

/// A daily plan containing up to 3 prioritized tasks.
class DailyPlan {
  final String id;
  final String userId;
  final DateTime date;
  final List<PlanTask> tasks;
  final bool morningPlanned;
  final bool eveningReflected;
  final String? reflectionNote;
  final int pointsEarned;

  const DailyPlan({
    required this.id,
    required this.userId,
    required this.date,
    required this.tasks,
    this.morningPlanned = false,
    this.eveningReflected = false,
    this.reflectionNote,
    this.pointsEarned = 0,
  });

  factory DailyPlan.fromJson(Map<String, dynamic> json) {
    return DailyPlan(
      id: json['id']?.toString() ?? '',
      userId: json['userId'] ?? '',
      date: DateTime.parse(
          json['date'] ?? DateTime.now().toIso8601String()),
      tasks: (json['tasks'] as List?)
              ?.map((t) => PlanTask.fromJson(t))
              .toList() ??
          [],
      morningPlanned: json['morningPlanned'] ?? false,
      eveningReflected: json['eveningReflected'] ?? false,
      reflectionNote: json['reflectionNote'],
      pointsEarned: json['pointsEarned'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'morningPlanned': morningPlanned,
      'eveningReflected': eveningReflected,
      'reflectionNote': reflectionNote,
      'pointsEarned': pointsEarned,
    };
  }

  DailyPlan copyWith({
    String? id,
    String? userId,
    DateTime? date,
    List<PlanTask>? tasks,
    bool? morningPlanned,
    bool? eveningReflected,
    String? reflectionNote,
    int? pointsEarned,
  }) {
    return DailyPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      tasks: tasks ?? this.tasks,
      morningPlanned: morningPlanned ?? this.morningPlanned,
      eveningReflected: eveningReflected ?? this.eveningReflected,
      reflectionNote: reflectionNote ?? this.reflectionNote,
      pointsEarned: pointsEarned ?? this.pointsEarned,
    );
  }

  int get completedCount => tasks.where((t) => t.completed).length;
  bool get allCompleted => tasks.isNotEmpty && tasks.every((t) => t.completed);
  double get progress =>
      tasks.isEmpty ? 0.0 : completedCount / tasks.length;
}

/// Weekly app usage entry — the most used app for a single day.
class WeeklyAppUsage {
  final int dayIndex; // 0=Mon, 6=Sun
  final String appName;
  final int minutes;
  final String category;
  final String iconPath;

  const WeeklyAppUsage({
    required this.dayIndex,
    required this.appName,
    required this.minutes,
    required this.category,
    required this.iconPath,
  });

  String get displayTime {
    if (minutes == 0) return '';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins}m';
  }
}
