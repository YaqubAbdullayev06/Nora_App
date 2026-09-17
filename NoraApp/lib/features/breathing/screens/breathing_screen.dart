import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/enums/age_group.dart';
import '../../../core/theme/persona_theme.dart';
import '../../../providers/app_provider.dart';
import '../../../widgets/nora_components.dart';
import '../models/breathing_pattern.dart';
import '../providers/breathing_provider.dart';
import '../widgets/animated_breathing_guide.dart';
import '../widgets/breathing_pattern_card.dart';

/// Breathing Exercises Screen — age-adaptive guided breathing.
///
/// Two views stacked:
/// 1. Selection view — pattern list + stats summary
/// 2. Session view — animated mascot guide + controls (shown when active)
class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen> {
  BreathingPattern? _selectedPattern;
  int _selectedDuration = 3;

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppProvider, BreathingProvider>(
      builder: (context, appProvider, breathingProvider, _) {
        final persona = appProvider.persona;

        return Scaffold(
          backgroundColor: DesignTokens.background,
          body: SafeArea(
            child: breathingProvider.isSessionActive
                ? _buildSessionView(breathingProvider, persona)
                : _buildSelectionView(breathingProvider, persona, appProvider),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════
  // SELECTION VIEW
  // ═══════════════════════════════════════════════

  Widget _buildSelectionView(
    BreathingProvider breathingProvider,
    PersonaTheme persona,
    AppProvider appProvider,
  ) {
    final patterns = BreathingPattern.forAgeGroup(persona.ageGroup);
    final maxDuration = BreathingPattern.maxDurationMinutes(persona.ageGroup);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(persona),
          const SizedBox(height: DesignTokens.spacing20),
          _buildStatsSummary(breathingProvider, persona),
          const SizedBox(height: DesignTokens.spacing24),
          Text(
            'Choose a Pattern',
            style: TextStyle(
              color: DesignTokens.textPrimary,
              fontSize: DesignTokens.fontSizeH3,
              fontWeight: DesignTokens.fontWeightSemiBold,
              fontFamily: DesignTokens.fontFamilyDisplay,
            ),
          ),
          const SizedBox(height: DesignTokens.spacing12),
          ...patterns.map((pattern) => Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.spacing12),
            child: BreathingPatternCard(
              pattern: pattern,
              isSelected: _selectedPattern?.id == pattern.id,
              onTap: () => setState(() {
                _selectedPattern = pattern;
                _selectedDuration = pattern.defaultDurationMinutes
                    .clamp(1, maxDuration);
              }),
            ),
          )),
          if (_selectedPattern != null) ...[
            const SizedBox(height: DesignTokens.spacing16),
            _buildDurationSelector(maxDuration, persona),
            const SizedBox(height: DesignTokens.spacing20),
            NoraButton(
              label: 'Start Breathing',
              icon: Icons.play_arrow_rounded,
              expanded: true,
              onPressed: () {
                breathingProvider.startSession(
                  _selectedPattern!,
                  _selectedDuration,
                );
              },
              height: persona.ageGroup == AgeGroup.baby ? 56 : 48,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(PersonaTheme persona) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                BreathingPattern.screenTitle(persona.ageGroup),
                style: TextStyle(
                  color: DesignTokens.textPrimary,
                  fontSize: DesignTokens.fontSizeH2,
                  fontWeight: DesignTokens.fontWeightBold,
                  fontFamily: DesignTokens.fontFamilyDisplay,
                ),
              ),
              Text(
                BreathingPattern.screenSubtitle(persona.ageGroup),
                style: TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: DesignTokens.fontSizeBodySmall,
                  fontFamily: DesignTokens.fontFamilyPrimary,
                ),
              ),
            ],
          ),
        ),
        NoraMascot(size: 48, showGlow: false),
      ],
    );
  }

  Widget _buildStatsSummary(BreathingProvider provider, PersonaTheme persona) {
    final stats = provider.stats;
    return NoraCard(
      backgroundColor: persona.primary.withValues(alpha: 0.08),
      border: Border.all(
        color: persona.primary.withValues(alpha: 0.2),
        width: 1,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            '${stats.totalSessions}',
            'Sessions',
            Icons.repeat_rounded,
            persona.primary,
          ),
          _buildStatItem(
            '${stats.totalMinutes}',
            'Minutes',
            Icons.schedule_rounded,
            persona.secondary,
          ),
          _buildStatItem(
            '${stats.currentStreak}',
            'Day Streak',
            Icons.local_fire_department_rounded,
            DesignTokens.warning,
          ),
          _buildStatItem(
            '${stats.pointsEarned}',
            'Points',
            Icons.star_rounded,
            DesignTokens.accent,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: DesignTokens.textPrimary,
            fontSize: DesignTokens.fontSizeBody,
            fontWeight: DesignTokens.fontWeightBold,
            fontFamily: DesignTokens.fontFamilyPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: DesignTokens.textMuted,
            fontSize: DesignTokens.fontSizeTiny,
            fontFamily: DesignTokens.fontFamilyPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSelector(int maxDuration, PersonaTheme persona) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Duration',
          style: TextStyle(
            color: DesignTokens.textMuted,
            fontSize: DesignTokens.fontSizeCaption,
            fontWeight: DesignTokens.fontWeightMedium,
            fontFamily: DesignTokens.fontFamilyPrimary,
          ),
        ),
        const SizedBox(height: DesignTokens.spacing8),
        Row(
          children: List.generate(maxDuration, (index) {
            final minutes = index + 1;
            final isSelected = _selectedDuration == minutes;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedDuration = minutes),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(
                    right: index < maxDuration - 1 ? 8 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? persona.primary.withValues(alpha: 0.15)
                        : DesignTokens.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? persona.primary : DesignTokens.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${minutes}m',
                      style: TextStyle(
                        color: isSelected
                            ? persona.primary
                            : DesignTokens.textMuted,
                        fontSize: DesignTokens.fontSizeBody,
                        fontWeight: isSelected
                            ? DesignTokens.fontWeightBold
                            : DesignTokens.fontWeightMedium,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // SESSION VIEW
  // ═══════════════════════════════════════════════

  Widget _buildSessionView(BreathingProvider provider, PersonaTheme persona) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacing20),
      child: Column(
        children: [
          const SizedBox(height: DesignTokens.spacing20),
          // Top bar: pattern name + close
          Row(
            children: [
              Expanded(
                child: Text(
                  provider.selectedPattern?.name ?? '',
                  style: TextStyle(
                    color: DesignTokens.textPrimary,
                    fontSize: DesignTokens.fontSizeH3,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    fontFamily: DesignTokens.fontFamilyDisplay,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _showStopDialog(provider),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: DesignTokens.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: DesignTokens.border),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: DesignTokens.textMuted,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacing16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: provider.sessionProgress,
              backgroundColor: DesignTokens.border,
              valueColor: AlwaysStoppedAnimation<Color>(persona.primary),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: DesignTokens.spacing12),
          // Elapsed time
          Text(
            provider.elapsedDisplay,
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: DesignTokens.fontSizeCaption,
              fontFamily: DesignTokens.fontFamilyPrimary,
            ),
          ),
          const Spacer(),
          // Animated breathing guide
          AnimatedBreathingGuide(
            mascotAssetPath: persona.mascotAssetPath ?? 'assets/images/mascots/adult_brain.svg',
            color: provider.selectedPattern?.color ?? persona.primary,
            phase: provider.currentPhase,
            phaseProgress: provider.phaseProgress,
            isActive: provider.isSessionActive && !provider.isPaused,
          ),
          const Spacer(),
          // Phase countdown
          if (provider.currentPhase != null) ...[
            Text(
              '${provider.phaseCountdown}',
              style: TextStyle(
                color: DesignTokens.textPrimary,
                fontSize: DesignTokens.fontSizeDisplaySmall,
                fontWeight: DesignTokens.fontWeightBold,
                fontFamily: DesignTokens.fontFamilyDisplay,
              ),
            ),
            const SizedBox(height: DesignTokens.spacing8),
          ],
          // Points earned
          if (provider.sessionPointsEarned > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: DesignTokens.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded,
                      color: DesignTokens.success, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '+${provider.sessionPointsEarned} pts',
                    style: TextStyle(
                      color: DesignTokens.success,
                      fontSize: DesignTokens.fontSizeBodySmall,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: DesignTokens.spacing24),
          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pause / Resume
              GestureDetector(
                onTap: provider.isPaused
                    ? provider.resumeSession
                    : provider.pauseSession,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: persona.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: persona.primary.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    provider.isPaused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacing32),
        ],
      ),
    );
  }

  void _showStopDialog(BreathingProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DesignTokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius16),
        ),
        title: Text(
          'End Session?',
          style: TextStyle(
            color: DesignTokens.textPrimary,
            fontWeight: DesignTokens.fontWeightSemiBold,
          ),
        ),
        content: Text(
          provider.sessionElapsedSeconds < 30
              ? 'You haven\'t breathed long enough to earn points. Keep going?'
              : 'You\'ll earn ${provider.sessionPointsEarned} points for this session.',
          style: TextStyle(color: DesignTokens.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Continue',
              style: TextStyle(color: DesignTokens.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.stopSession();
            },
            child: Text(
              'End',
              style: TextStyle(color: DesignTokens.danger),
            ),
          ),
        ],
      ),
    );
  }
}
