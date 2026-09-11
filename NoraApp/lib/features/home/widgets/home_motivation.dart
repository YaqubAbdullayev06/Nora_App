import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/enums/age_group.dart';
import '../../../providers/app_provider.dart';
import '../../../widgets/nora_components.dart';

/// Compact motivation strip — SVG icon + motivational text.
class HomeMotivation extends StatelessWidget {
  final AppProvider provider;

  const HomeMotivation({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final persona = provider.persona;
    final message = _getMotivationalMessage(persona.ageGroup);

    return NoraCard(
      backgroundColor: persona.primary.withValues(alpha: 0.08),
      border: Border.all(
        color: persona.primary.withValues(alpha: 0.2),
        width: 1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          NoraIcon(
            assetPath: 'assets/images/icons/brain.svg',
            size: 22,
            color: persona.primary,
            backgroundColor: persona.primary.withValues(alpha: 0.15),
            bgSize: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: DesignTokens.textPrimary,
                fontSize: DesignTokens.fontSizeBodySmall,
                fontFamily: DesignTokens.fontFamilyPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMotivationalMessage(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
        return "You're doing great! Every little bit counts!";
      case AgeGroup.kid:
        return "Keep going! You're on a streak!";
      case AgeGroup.teen:
        return "Consistency beats intensity. Keep showing up.";
      case AgeGroup.adult:
        return "The secret of getting ahead is getting started.";
    }
  }
}
