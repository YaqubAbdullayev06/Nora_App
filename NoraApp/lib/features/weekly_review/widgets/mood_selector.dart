import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../models/models.dart';

/// Mood Selector widget for Weekly Review.
/// Displays mood options as tappable SVG illustrations.
class MoodSelector extends StatelessWidget {
  final WeeklyMood? selectedMood;
  final ValueChanged<WeeklyMood> onMoodSelected;

  const MoodSelector({
    super.key,
    this.selectedMood,
    required this.onMoodSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How was your week?',
          style: TextStyle(
            color: DesignTokens.textPrimary,
            fontSize: DesignTokens.fontSizeH3,
            fontWeight: DesignTokens.fontWeightSemiBold,
            fontFamily: DesignTokens.fontFamilyDisplay,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Select the mood that best describes your week',
          style: TextStyle(
            color: DesignTokens.textMuted,
            fontSize: DesignTokens.fontSizeCaption,
            fontFamily: DesignTokens.fontFamilyPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: WeeklyMood.values.map((mood) {
            final isSelected = selectedMood == mood;
            return GestureDetector(
              onTap: () => onMoodSelected(mood),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Color(mood.colorValue).withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(DesignTokens.radius16),
                  border: Border.all(
                    color: isSelected
                        ? Color(mood.colorValue)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: SvgPicture.asset(
                        mood.assetPath,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      mood.label,
                      style: TextStyle(
                        color: isSelected
                            ? Color(mood.colorValue)
                            : DesignTokens.textMuted,
                        fontSize: DesignTokens.fontSizeCaption,
                        fontWeight: isSelected
                            ? DesignTokens.fontWeightBold
                            : DesignTokens.fontWeightRegular,
                        fontFamily: DesignTokens.fontFamilyPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}