/// Age group classification for Nora's adaptive persona system.
///
/// Each group gets a unique AI personality, UI theme, content strategy,
/// and interaction style. Nora behaves differently for each group.
///
/// NOTE: Child (1-6) is parent-managed. The child never talks to the LLM.
/// The parent controls blocklists, schedules, and content. The child uses
/// pre-authored, human-reviewed content only — no free-form AI generation.
enum AgeGroup {
  /// Babies & Toddlers (0-2) — PARENT-MANAGED MODE
  /// No LLM chat. Parent controls everything. Baby uses pre-authored content.
  /// Large buttons, bright colors, voice-first, minimal text.
  baby,

  /// Children & Toddlers (2-6) — PARENT-MANAGED MODE
  /// No LLM chat. Parent controls everything. Child uses pre-authored content.
  /// Big buttons, bright colors, voice-first, minimal text.
  child,

  /// Kids (6-12)
  /// Nora is a fun, encouraging learning buddy with gamified experiences.
  /// Retrieval-constrained: model selects from pre-authored content library.
  /// No open text input. Parent-linked accounts. Logging for parent review.
  kid,

  /// Teens (12-18)
  /// Nora is a motivational coach with modern, trendy design.
  /// Social features, study tools, goal tracking, dark mode.
  /// Crisis-detection routing to real resources. No clinical advice.
  teen,

  /// Adults (18+)
  /// Nora is a professional productivity assistant.
  /// Clean, minimal, efficient, data-driven insights.
  adult,
}

/// Extension on AgeGroup for computed properties.
extension AgeGroupExtension on AgeGroup {
  /// Display name for the age group.
  String get displayName {
    switch (this) {
      case AgeGroup.baby:
        return 'Baby (Parent-Managed)';
      case AgeGroup.child:
        return 'Child (Parent-Managed)';
      case AgeGroup.kid:
        return 'Kid';
      case AgeGroup.teen:
        return 'Teen';
      case AgeGroup.adult:
        return 'Adult';
    }
  }

  /// Age range description.
  String get ageRange {
    switch (this) {
      case AgeGroup.baby:
        return '0-2 years';
      case AgeGroup.child:
        return '2-6 years';
      case AgeGroup.kid:
        return '6-12 years';
      case AgeGroup.teen:
        return '12-18 years';
      case AgeGroup.adult:
        return '18+ years';
    }
  }

  /// Nora's persona name for this age group.
  String get personaName {
    switch (this) {
      case AgeGroup.baby:
        return 'Nora Tiny';
      case AgeGroup.child:
        return 'Nora Little';
      case AgeGroup.kid:
        return 'Nora Buddy';
      case AgeGroup.teen:
        return 'Nora Coach';
      case AgeGroup.adult:
        return 'Nora';
    }
  }

  /// Description of Nora's role for this age group.
  String get personaDescription {
    switch (this) {
      case AgeGroup.baby:
        return 'Parent-managed early learning';
      case AgeGroup.child:
        return 'Parent-managed learning companion';
      case AgeGroup.kid:
        return 'Your fun growth buddy';
      case AgeGroup.teen:
        return 'Your motivation coach';
      case AgeGroup.adult:
        return 'Your focus assistant';
    }
  }

  /// Greeting style for this age group.
  String get greetingStyle {
    switch (this) {
      case AgeGroup.baby:
        return 'simple';  // "Hi! 🌟"
      case AgeGroup.child:
        return 'simple';  // "Hi! 🌟"
      case AgeGroup.kid:
        return 'playful'; // "Hey there, champion! 🏆"
      case AgeGroup.teen:
        return 'cool';    // "What's up! 💪"
      case AgeGroup.adult:
        return 'formal';  // "Good morning."
    }
  }

  /// Maximum focus session duration in minutes for this age group.
  int get maxFocusMinutes {
    switch (this) {
      case AgeGroup.baby:
        return 2;   // Very short attention span
      case AgeGroup.child:
        return 5;   // Very short attention span
      case AgeGroup.kid:
        return 15;  // Growing attention span
      case AgeGroup.teen:
        return 25;  // Standard pomodoro
      case AgeGroup.adult:
        return 50;  // Deep work sessions
    }
  }

  /// Default focus session duration in minutes for this age group.
  int get defaultFocusMinutes {
    switch (this) {
      case AgeGroup.baby:
        return 2;
      case AgeGroup.child:
        return 3;
      case AgeGroup.kid:
        return 10;
      case AgeGroup.teen:
        return 25;
      case AgeGroup.adult:
        return 25;
    }
  }

  /// Screen time daily limit in minutes (0 = no limit).
  int get screenTimeLimitMinutes {
    switch (this) {
      case AgeGroup.baby:
        return 15;   // 15 min max
      case AgeGroup.child:
        return 30;   // 30 min max
      case AgeGroup.kid:
        return 60;   // 1 hour max
      case AgeGroup.teen:
        return 120;  // 2 hours max
      case AgeGroup.adult:
        return 0;    // No limit
    }
  }

  /// Whether this age group requires parental controls.
  bool get requiresParentalControl {
    return this == AgeGroup.baby || this == AgeGroup.child || this == AgeGroup.kid;
  }

  /// Whether this age group has social features.
  bool get hasSocialFeatures {
    return this == AgeGroup.teen || this == AgeGroup.adult;
  }

  /// Content complexity level (1-5).
  int get contentComplexity {
    switch (this) {
      case AgeGroup.baby:
        return 1;
      case AgeGroup.child:
        return 1;
      case AgeGroup.kid:
        return 2;
      case AgeGroup.teen:
        return 4;
      case AgeGroup.adult:
        return 5;
    }
  }

  /// Points multiplier for focus sessions.
  double get pointsMultiplier {
    switch (this) {
      case AgeGroup.baby:
        return 3.0;   // Extra encouragement
      case AgeGroup.child:
        return 2.0;   // Extra encouragement
      case AgeGroup.kid:
        return 1.5;   // Gamified rewards
      case AgeGroup.teen:
        return 1.0;   // Standard
      case AgeGroup.adult:
        return 1.0;   // Standard
    }
  }

  /// Break duration in minutes after a focus session (short break).
  int get breakMinutes {
    switch (this) {
      case AgeGroup.baby:
        return 2;
      case AgeGroup.child:
        return 2;
      case AgeGroup.kid:
        return 5;
      case AgeGroup.teen:
        return 5;
      case AgeGroup.adult:
        return 5;
    }
  }

  /// Long break duration in minutes (after completing a full Pomodoro cycle).
  int get longBreakMinutes {
    switch (this) {
      case AgeGroup.baby:
        return 5;
      case AgeGroup.child:
        return 5;
      case AgeGroup.kid:
        return 10;
      case AgeGroup.teen:
        return 15;
      case AgeGroup.adult:
        return 15;
    }
  }

  /// Number of focus sessions before a long break.
  int get pomodoroSessionsPerCycle {
    switch (this) {
      case AgeGroup.baby:
        return 1;
      case AgeGroup.child:
        return 2;
      case AgeGroup.kid:
        return 3;
      case AgeGroup.teen:
        return 4;
      case AgeGroup.adult:
        return 4;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // DAILY PLANNING PROPERTIES
  // ═══════════════════════════════════════════════════════════════

  /// Maximum number of daily tasks allowed.
  int get maxDailyTasks {
    switch (this) {
      case AgeGroup.baby:
        return 1;
      case AgeGroup.child:
        return 2;
      case AgeGroup.kid:
        return 3;
      case AgeGroup.teen:
        return 3;
      case AgeGroup.adult:
        return 3;
    }
  }

  /// Title shown on the planning screen.
  String get planTitle {
    switch (this) {
      case AgeGroup.baby:
        return "Baby's Day!";
      case AgeGroup.child:
        return "Today's Fun!";
      case AgeGroup.kid:
        return 'Daily Quests';
      case AgeGroup.teen:
        return 'My Plan';
      case AgeGroup.adult:
        return 'Daily Priorities';
    }
  }

  /// Subtitle/prompt shown during morning planning.
  String get planSubtitle {
    switch (this) {
      case AgeGroup.baby:
        return 'Pick fun activities!';
      case AgeGroup.child:
        return 'Pick your fun activities!';
      case AgeGroup.kid:
        return 'Choose your quests for today!';
      case AgeGroup.teen:
        return 'Set your priorities for the day';
      case AgeGroup.adult:
        return 'What matters most today?';
    }
  }

  /// Label for the evening reflection section.
  String get reflectionLabel {
    switch (this) {
      case AgeGroup.baby:
        return "Baby's Day!";
      case AgeGroup.child:
        return 'How was your day?';
      case AgeGroup.kid:
        return 'Quest Complete!';
      case AgeGroup.teen:
        return 'Reflect on your day';
      case AgeGroup.adult:
        return 'Evening Reflection';
    }
  }

  /// Points awarded per completed task.
  int get pointsPerTask {
    switch (this) {
      case AgeGroup.baby:
        return 25;
      case AgeGroup.child:
        return 20;
      case AgeGroup.kid:
        return 15;
      case AgeGroup.teen:
        return 10;
      case AgeGroup.adult:
        return 10;
    }
  }

  /// Mascot SVG asset for the planning screen.
  String get planMascotAsset {
    switch (this) {
      case AgeGroup.baby:
        return 'assets/images/mascots/baby_star.svg';
      case AgeGroup.child:
        return 'assets/images/mascots/baby_star.svg';
      case AgeGroup.kid:
        return 'assets/images/mascots/kid_fox.svg';
      case AgeGroup.teen:
        return 'assets/images/mascots/teen_bolt.svg';
      case AgeGroup.adult:
        return 'assets/images/mascots/adult_brain.svg';
    }
  }

  /// Icon asset for task input (baby/kid use visual icons).
  String get defaultTaskIcon {
    switch (this) {
      case AgeGroup.baby:
        return 'assets/images/icons/star.svg';
      case AgeGroup.child:
        return 'assets/images/icons/star.svg';
      case AgeGroup.kid:
        return 'assets/images/icons/trophy.svg';
      case AgeGroup.teen:
        return 'assets/images/icons/target.svg';
      case AgeGroup.adult:
        return 'assets/images/icons/target.svg';
    }
  }
}

/// Determines AgeGroup from a birth date.
AgeGroup ageGroupFromBirthDate(DateTime birthDate) {
  final age = DateTime.now().difference(birthDate).inDays ~/ 365;
  if (age < 2) return AgeGroup.baby;
  if (age < 6) return AgeGroup.child;
  if (age < 12) return AgeGroup.kid;
  if (age < 18) return AgeGroup.teen;
  return AgeGroup.adult;
}

/// Determines AgeGroup from a raw age number.
AgeGroup ageGroupFromAge(int age) {
  if (age < 2) return AgeGroup.baby;
  if (age < 6) return AgeGroup.child;
  if (age < 12) return AgeGroup.kid;
  if (age < 18) return AgeGroup.teen;
  return AgeGroup.adult;
}
