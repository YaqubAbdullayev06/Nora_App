import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/enums/age_group.dart';
import '../../../providers/persona_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/nora_components.dart';

/// Home header — mascot with glow, greeting, name, tagline, and age badge.
class HomeHeader extends StatelessWidget {
  final PersonaProvider personaProvider;
  final AuthProvider authProvider;

  const HomeHeader({super.key, required this.personaProvider, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    final persona = personaProvider.persona;
    final userName = authProvider.currentUser?.name ?? 'Explorer';

    return Row(
      children: [
        // Mascot with glow
        NoraMascot(size: 64, showGlow: true),
        const SizedBox(width: DesignTokens.spacing16),
        // Greeting + Name + Tagline
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(persona.ageGroup),
                style: TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: DesignTokens.fontSizeCaption,
                  fontFamily: DesignTokens.fontFamilyPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                userName,
                style: TextStyle(
                  color: DesignTokens.textPrimary,
                  fontSize: DesignTokens.fontSizeH2,
                  fontWeight: DesignTokens.fontWeightBold,
                  fontFamily: DesignTokens.fontFamilyDisplay,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                persona.tagline,
                style: TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: DesignTokens.fontSizeCaption,
                  fontFamily: DesignTokens.fontFamilyPrimary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        // Age badge
        AgeGroupBadge(),
      ],
    );
  }

  String _getGreeting(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
        return 'Hi there, little one!';
      case AgeGroup.child:
        return 'Hi there, little one!';
      case AgeGroup.kid:
        return 'Hey, adventurer!';
      case AgeGroup.teen:
        return "What's up!";
      case AgeGroup.adult:
        return 'Good to see you';
    }
  }
}
