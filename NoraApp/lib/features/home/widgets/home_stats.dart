import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../features/profile/utils/age_group_helpers.dart';
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
    final ageGroup = persona.ageGroup;

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
                  label: ageGroup.scoreLabel,
                  value: '${focusProvider.focusScore}',
                  iconAsset: 'assets/images/icons/star.svg',
                  color: DesignTokens.accent,
                ),
              ),
              const SizedBox(width: DesignTokens.spacing12),
              SizedBox(
                width: 140,
                child: StatCardHorizontal(
                  label: ageGroup.streakLabel,
                  value: '${focusProvider.streakDays}',
                  iconAsset: 'assets/images/icons/fire.svg',
                  color: DesignTokens.warning,
                ),
              ),
              const SizedBox(width: DesignTokens.spacing12),
              SizedBox(
                width: 140,
                child: StatCardHorizontal(
                  label: ageGroup.timeLabel,
                  value: '${focusProvider.totalFocusMinutes}m',
                  iconAsset: 'assets/images/icons/target.svg',
                  color: DesignTokens.accentSecondary,
                ),
              ),
              const SizedBox(width: DesignTokens.spacing12),
              SizedBox(
                width: 140,
                child: StatCardHorizontal(
                  label: ageGroup.sessionsLabel,
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
}
