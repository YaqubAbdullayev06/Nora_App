import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/design_tokens.dart';
import '../models/breathing_pattern.dart';

/// A card displaying a breathing pattern option for selection.
class BreathingPatternCard extends StatelessWidget {
  final BreathingPattern pattern;
  final bool isSelected;
  final VoidCallback onTap;

  const BreathingPatternCard({
    super.key,
    required this.pattern,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(DesignTokens.spacing16),
        decoration: BoxDecoration(
          color: isSelected
              ? pattern.color.withValues(alpha: 0.12)
              : DesignTokens.surface,
          borderRadius: BorderRadius.circular(DesignTokens.radius16),
          border: Border.all(
            color: isSelected ? pattern.color : DesignTokens.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: pattern.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: SvgPicture.asset(
                  pattern.iconPath,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    pattern.color,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(width: DesignTokens.spacing12),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pattern.name,
                    style: TextStyle(
                      color: DesignTokens.textPrimary,
                      fontSize: DesignTokens.fontSizeBody,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      fontFamily: DesignTokens.fontFamilyPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pattern.description,
                    style: TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: DesignTokens.fontSizeCaption,
                      fontFamily: DesignTokens.fontFamilyPrimary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: DesignTokens.spacing8),
            // Duration badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: pattern.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                pattern.cycleDurationLabel,
                style: TextStyle(
                  color: pattern.color,
                  fontSize: DesignTokens.fontSizeCaption,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
