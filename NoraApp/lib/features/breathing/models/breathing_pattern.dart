import 'package:flutter/material.dart';
import '../../../core/enums/age_group.dart';

/// Represents a single phase in a breathing pattern.
class BreathingPhase {
  final String name;
  final int durationSeconds;
  final String instruction;

  const BreathingPhase({
    required this.name,
    required this.durationSeconds,
    required this.instruction,
  });
}

/// Represents a breathing exercise pattern.
class BreathingPattern {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final List<BreathingPhase> phases;
  final int defaultDurationMinutes;
  final Color color;
  final List<AgeGroup> supportedAgeGroups;

  const BreathingPattern({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.phases,
    required this.defaultDurationMinutes,
    required this.color,
    required this.supportedAgeGroups,
  });

  /// Total cycle duration in seconds.
  int get cycleDurationSeconds =>
      phases.fold(0, (sum, phase) => sum + phase.durationSeconds);

  /// Display-friendly cycle duration (e.g. "16s").
  String get cycleDurationLabel => '${cycleDurationSeconds}s';

  // ─── Static patterns ───

  static const boxBreathing = BreathingPattern(
    id: 'box',
    name: 'Box Breathing',
    description: 'Equal inhale, hold, exhale, hold. Used by Navy SEALs for calm focus.',
    iconPath: 'assets/images/icons/box_breathing.svg',
    phases: [
      BreathingPhase(name: 'Inhale', durationSeconds: 4, instruction: 'Breathe in'),
      BreathingPhase(name: 'Hold', durationSeconds: 4, instruction: 'Hold your breath'),
      BreathingPhase(name: 'Exhale', durationSeconds: 4, instruction: 'Breathe out'),
      BreathingPhase(name: 'Hold', durationSeconds: 4, instruction: 'Hold'),
    ],
    defaultDurationMinutes: 3,
    color: Color(0xFF6C63FF),
    supportedAgeGroups: [AgeGroup.kid, AgeGroup.teen, AgeGroup.adult],
  );

  static const relaxing478 = BreathingPattern(
    id: '478',
    name: '4-7-8 Relaxing',
    description: 'Dr. Weil\'s natural tranquilizer for the nervous system.',
    iconPath: 'assets/images/icons/wave_breathing.svg',
    phases: [
      BreathingPhase(name: 'Inhale', durationSeconds: 4, instruction: 'Breathe in'),
      BreathingPhase(name: 'Hold', durationSeconds: 7, instruction: 'Hold your breath'),
      BreathingPhase(name: 'Exhale', durationSeconds: 8, instruction: 'Breathe out slowly'),
    ],
    defaultDurationMinutes: 3,
    color: Color(0xFF00BFA5),
    supportedAgeGroups: [AgeGroup.teen, AgeGroup.adult],
  );

  static const deepCalm = BreathingPattern(
    id: 'deep_calm',
    name: 'Deep Calm',
    description: 'Simple deep breathing for relaxation and centering.',
    iconPath: 'assets/images/icons/calm_breathing.svg',
    phases: [
      BreathingPhase(name: 'Inhale', durationSeconds: 5, instruction: 'Breathe in deeply'),
      BreathingPhase(name: 'Exhale', durationSeconds: 5, instruction: 'Breathe out slowly'),
    ],
    defaultDurationMinutes: 2,
    color: Color(0xFF7ED6DF),
    supportedAgeGroups: [AgeGroup.baby, AgeGroup.kid, AgeGroup.teen, AgeGroup.adult],
  );

  static const physiologicalSigh = BreathingPattern(
    id: 'sigh',
    name: 'Physiological Sigh',
    description: 'Double inhale through the nose, long exhale through the mouth. Fastest stress relief.',
    iconPath: 'assets/images/icons/sigh_breathing.svg',
    phases: [
      BreathingPhase(name: 'Inhale', durationSeconds: 2, instruction: 'Inhale through nose'),
      BreathingPhase(name: 'Inhale', durationSeconds: 1, instruction: 'Second inhale'),
      BreathingPhase(name: 'Exhale', durationSeconds: 6, instruction: 'Long exhale through mouth'),
    ],
    defaultDurationMinutes: 3,
    color: Color(0xFFFF6D00),
    supportedAgeGroups: [AgeGroup.teen, AgeGroup.adult],
  );

  static const allPatterns = [
    boxBreathing,
    relaxing478,
    deepCalm,
    physiologicalSigh,
  ];

  /// Returns patterns available for a given age group.
  static List<BreathingPattern> forAgeGroup(AgeGroup group) {
    return allPatterns
        .where((p) => p.supportedAgeGroups.contains(group))
        .toList();
  }

  /// Age-appropriate title for the breathing screen.
  static String screenTitle(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
        return 'Belly Breathing';
      case AgeGroup.child:
        return 'Belly Breathing';
      case AgeGroup.kid:
        return 'Dragon Breaths';
      case AgeGroup.teen:
        return 'Breathwork';
      case AgeGroup.adult:
        return 'Breathing Exercises';
    }
  }

  /// Age-appropriate subtitle.
  static String screenSubtitle(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
        return 'Breathe with your tummy!';
      case AgeGroup.child:
        return 'Breathe with your tummy!';
      case AgeGroup.kid:
        return 'Breathe like a dragon!';
      case AgeGroup.teen:
        return 'Calm your mind, one breath at a time';
      case AgeGroup.adult:
        return 'Science-backed techniques for focus and calm';
    }
  }

  /// Max session duration in minutes for the age group.
  static int maxDurationMinutes(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
        return 2;
      case AgeGroup.child:
        return 2;
      case AgeGroup.kid:
        return 3;
      case AgeGroup.teen:
        return 5;
      case AgeGroup.adult:
        return 5;
    }
  }
}

/// Tracks a user's cumulative breathing exercise statistics.
class BreathingStats {
  final int totalSessions;
  final int totalMinutes;
  final int currentStreak;
  final int pointsEarned;
  final DateTime? lastSessionDate;

  const BreathingStats({
    this.totalSessions = 0,
    this.totalMinutes = 0,
    this.currentStreak = 0,
    this.pointsEarned = 0,
    this.lastSessionDate,
  });

  BreathingStats copyWith({
    int? totalSessions,
    int? totalMinutes,
    int? currentStreak,
    int? pointsEarned,
    DateTime? lastSessionDate,
  }) {
    return BreathingStats(
      totalSessions: totalSessions ?? this.totalSessions,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      currentStreak: currentStreak ?? this.currentStreak,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      lastSessionDate: lastSessionDate ?? this.lastSessionDate,
    );
  }
}
