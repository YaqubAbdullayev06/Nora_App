import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/enums/age_group.dart';
import '../../../providers/app_provider.dart';
import '../../../widgets/nora_components.dart';

/// 2×2 quick action grid — AI Assistant, App Scanner, Weekly Review, Daily Plan.
class HomeActions extends StatelessWidget {
  final AppProvider provider;
  final VoidCallback? onPlanTap;

  const HomeActions({
    super.key,
    required this.provider,
    this.onPlanTap,
  });

  @override
  Widget build(BuildContext context) {
    final persona = provider.persona;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: "Quick Actions",
          icon: Icons.bolt_rounded,
          iconColor: DesignTokens.warning,
        ),
        const SizedBox(height: DesignTokens.spacing12),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                iconAsset: 'assets/images/icons/ai_brain.svg',
                title: 'AI Assistant',
                subtitle: _getAssistantSubtitle(persona.ageGroup),
                gradient: [persona.primary, persona.secondary],
                onTap: () => Navigator.pushNamed(context, '/assistant'),
              ),
            ),
            const SizedBox(width: DesignTokens.spacing12),
            Expanded(
              child: _ActionCard(
                iconAsset: 'assets/images/icons/lock.svg',
                title: 'App Scanner',
                subtitle: 'Block distractions',
                gradient: [DesignTokens.warning, DesignTokens.danger],
                onTap: () => Navigator.pushNamed(context, '/app-scan'),
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.spacing12),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                iconAsset: 'assets/images/icons/calendar.svg',
                title: _getWeeklyReviewTitle(persona.ageGroup),
                subtitle: _getWeeklyReviewSubtitle(persona.ageGroup),
                gradient: [DesignTokens.accentSecondary, DesignTokens.accent],
                onTap: () => Navigator.pushNamed(context, '/weekly-review'),
              ),
            ),
            const SizedBox(width: DesignTokens.spacing12),
            Expanded(
              child: _ActionCard(
                iconAsset: 'assets/images/icons/clipboard-list.svg',
                title: 'Daily Plan',
                subtitle: _getPlanSubtitle(persona.ageGroup),
                gradient: [DesignTokens.success, DesignTokens.accentSecondary],
                onTap: onPlanTap ?? () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getAssistantSubtitle(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
        return 'Your playful helper';
      case AgeGroup.kid:
        return 'Scan and block apps';
      case AgeGroup.teen:
        return 'Block distractions';
      case AgeGroup.adult:
        return 'Scan apps, track usage';
    }
  }

  String _getWeeklyReviewTitle(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
        return 'My Happy Week';
      case AgeGroup.kid:
        return 'Weekly Review';
      case AgeGroup.teen:
        return 'Weekly Review';
      case AgeGroup.adult:
        return 'Weekly Review';
    }
  }

  String _getWeeklyReviewSubtitle(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
        return 'See your fun activities';
      case AgeGroup.kid:
        return 'Check your progress';
      case AgeGroup.teen:
        return 'Reflect on your week';
      case AgeGroup.adult:
        return 'Reflect and set goals';
    }
  }

  String _getPlanSubtitle(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
        return 'Fun things today!';
      case AgeGroup.kid:
        return 'What\'s the mission?';
      case AgeGroup.teen:
        return 'Plan your day';
      case AgeGroup.adult:
        return 'Structure your day';
    }
  }
}

/// Internal action card widget with gradient icon and labels.
class _ActionCard extends StatefulWidget {
  final String iconAsset;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ActionCard({
    required this.iconAsset,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: NoraCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gradient icon circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: NoraIcon(
                    assetPath: widget.iconAsset,
                    size: 22,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Title
              Text(
                widget.title,
                style: TextStyle(
                  color: DesignTokens.textPrimary,
                  fontSize: DesignTokens.fontSizeBodySmall,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  fontFamily: DesignTokens.fontFamilyPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              // Subtitle
              Text(
                widget.subtitle,
                style: TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: DesignTokens.fontSizeCaption,
                  fontFamily: DesignTokens.fontFamilyPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
