import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/enums/age_group.dart';
import '../../../providers/persona_provider.dart';
import '../../../providers/focus_provider.dart';
import '../../../widgets/nora_components.dart';

/// Horizontal scrollable stats cards — score, streak, focus time.
class HomeStats extends StatelessWidget {
  final PersonaProvider personaProvider;
  final FocusProvider focusProvider;

  const HomeStats({super.key, required this.personaProvider, required this.focusProvider});

  @override
  Widget build(BuildContext context) {
    final persona = personaProvider.persona;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: "Today",
          icon: Icons.analytics_rounded,
          iconColor: DesignTokens.accent,
        ),
        const SizedBox(height: DesignTokens.spacing12),
        SizedBox(
          height: 130,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                width: 140,
                child: StatCardHorizontal(
                  label: _getScoreLabel(persona.ageGroup),
                  value: '${focusProvider.focusScore}',
                  iconAsset: 'assets/images/icons/star.svg',
                  color: DesignTokens.accent,
                ),
              ),
              const SizedBox(width: DesignTokens.spacing12),
              SizedBox(
                width: 140,
                child: StatCardHorizontal(
                  label: _getStreakLabel(persona.ageGroup),
                  value: '${focusProvider.streakDays}',
                  iconAsset: 'assets/images/icons/fire.svg',
                  color: DesignTokens.warning,
                ),
              ),
              const SizedBox(width: DesignTokens.spacing12),
              SizedBox(
                width: 140,
                child: StatCardHorizontal(
                  label: _getTimeLabel(persona.ageGroup),
                  value: '${focusProvider.totalFocusMinutes}m',
                  iconAsset: 'assets/images/icons/target.svg',
                  color: DesignTokens.accentSecondary,
                ),
              ),
              const SizedBox(width: DesignTokens.spacing12),
              SizedBox(
                width: 140,
                child: StatCardHorizontal(
                  label: _getSessionsLabel(persona.ageGroup),
                  value: '${focusProvider.sessionsCompleted}',
                  iconAsset: 'assets/images/icons/circle-check-big.svg',
                  color: DesignTokens.success,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getScoreLabel(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
        return 'Stars';
      case AgeGroup.child:
        return 'Stars';
      case AgeGroup.kid:
        return 'Points';
      case AgeGroup.teen:
        return 'XP';
      case AgeGroup.adult:
        return 'Score';
    }
  }

  String _getStreakLabel(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
        return 'Days';
      case AgeGroup.child:
        return 'Days';
      case AgeGroup.kid:
        return 'Streak';
      case AgeGroup.teen:
        return 'Streak';
      case AgeGroup.adult:
        return 'Streak';
    }
  }

  String _getTimeLabel(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
        return 'Play Time';
      case AgeGroup.child:
        return 'Play Time';
      case AgeGroup.kid:
        return 'Focus Time';
      case AgeGroup.teen:
        return 'Study Time';
      case AgeGroup.adult:
        return 'Deep Work';
    }
  }

  String _getSessionsLabel(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
        return 'Plays';
      case AgeGroup.child:
        return 'Plays';
      case AgeGroup.kid:
        return 'Quests';
      case AgeGroup.teen:
        return 'Sessions';
      case AgeGroup.adult:
        return 'Sessions';
    }
  }
}
