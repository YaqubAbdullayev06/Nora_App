import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/enums/age_group.dart';
import '../../../core/theme/persona_theme.dart';
import '../../../providers/app_provider.dart';

/// Break Screen — calming interlude between Pomodoro focus sessions.
/// Shows a Lottie breathing animation, countdown timer, and session progress.
class BreakScreen extends StatefulWidget {
  const BreakScreen({super.key});

  @override
  State<BreakScreen> createState() => _BreakScreenState();
}

class _BreakScreenState extends State<BreakScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _breatheTextController;
  late Animation<double> _breatheTextOpacity;
  bool _showBreatheIn = true;

  @override
  void initState() {
    super.initState();
    _breatheTextController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _showBreatheIn = !_showBreatheIn);
          _breatheTextController
            ..reset()
            ..forward();
        }
      });
    _breatheTextOpacity = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _breatheTextController, curve: Curves.easeInOut),
    );
    _breatheTextController.forward();
  }

  @override
  void dispose() {
    _breatheTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final persona = provider.persona;
        final isLongBreak = provider.isLongBreak;
        final minutes = provider.timerSeconds ~/ 60;
        final seconds = provider.timerSeconds % 60;
        final totalSeconds = provider.breakDurationSeconds;
        final progress = totalSeconds > 0
            ? 1.0 - (provider.timerSeconds / totalSeconds)
            : 0.0;

        return Scaffold(
          backgroundColor: DesignTokens.background,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(persona, isLongBreak, provider),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(DesignTokens.spacing24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLottieAnimation(persona),
                          const SizedBox(height: DesignTokens.spacing32),
                          _buildBreatheText(persona),
                          const SizedBox(height: DesignTokens.spacing24),
                          _buildCountdown(minutes, seconds, progress, persona),
                          const SizedBox(height: DesignTokens.spacing32),
                          _buildSessionDots(provider, persona),
                          const SizedBox(height: DesignTokens.spacing40),
                          _buildSkipButton(provider, persona),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(PersonaTheme persona, bool isLongBreak, AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacing20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLongBreak ? 'Long Break' : 'Short Break',
                  style: TextStyle(
                    color: DesignTokens.textPrimary,
                    fontSize: DesignTokens.fontSizeH2,
                    fontWeight: DesignTokens.fontWeightBold,
                    fontFamily: DesignTokens.fontFamilyDisplay,
                  ),
                ),
                Text(
                  isLongBreak
                      ? 'You earned a longer rest!'
                      : 'Take a moment to breathe',
                  style: TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: DesignTokens.fontSizeBodySmall,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Session counter badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: persona.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(DesignTokens.radius20),
            ),
            child: Text(
              '${provider.completedSessionsInCycle}/${persona.ageGroup.pomodoroSessionsPerCycle}',
              style: TextStyle(
                color: persona.primary,
                fontSize: DesignTokens.fontSizeCaption,
                fontWeight: DesignTokens.fontWeightBold,
                fontFamily: DesignTokens.fontFamilyPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLottieAnimation(PersonaTheme persona) {
    return SizedBox(
      width: 240,
      height: 240,
      child: Lottie.asset(
        'assets/animations/breathing_meditation.json',
        fit: BoxFit.contain,
        repeat: true,
        errorBuilder: (context, error, stackTrace) {
          // Fallback: pulsing circle if Lottie fails to load
          return _buildFallbackAnimation(persona);
        },
      ),
    );
  }

  Widget _buildFallbackAnimation(PersonaTheme persona) {
    return AnimatedBuilder(
      animation: _breatheTextController,
      builder: (context, child) {
        final scale = 0.8 + (_breatheTextController.value * 0.4);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  persona.primary.withValues(alpha: 0.3),
                  persona.primary.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
            child: Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: persona.primary.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBreatheText(PersonaTheme persona) {
    return FadeTransition(
      opacity: _breatheTextOpacity,
      child: Text(
        _showBreatheIn ? 'Breathe in...' : 'Breathe out...',
        style: TextStyle(
          color: persona.primary,
          fontSize: DesignTokens.fontSizeH3,
          fontWeight: DesignTokens.fontWeightMedium,
          fontFamily: DesignTokens.fontFamilyDisplay,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCountdown(
      int minutes, int seconds, double progress, PersonaTheme persona) {
    return Column(
      children: [
        // Timer display
        Text(
          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
          style: TextStyle(
            color: DesignTokens.textPrimary,
            fontSize: 56,
            fontWeight: DesignTokens.fontWeightBold,
            fontFamily: DesignTokens.fontFamilyDisplay,
            height: 1,
          ),
        ),
        const SizedBox(height: DesignTokens.spacing8),
        // Progress bar
        SizedBox(
          width: 200,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusRound),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: DesignTokens.border,
              valueColor: AlwaysStoppedAnimation<Color>(persona.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionDots(AppProvider provider, PersonaTheme persona) {
    final total = provider.persona.ageGroup.pomodoroSessionsPerCycle;
    final completed = provider.completedSessionsInCycle;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final isCompleted = index < completed;
        final isCurrent = index == completed;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isCurrent ? 24 : 10,
            height: 10,
            decoration: BoxDecoration(
              color: isCompleted
                  ? persona.primary
                  : isCurrent
                      ? persona.primary.withValues(alpha: 0.5)
                      : DesignTokens.border,
              borderRadius: BorderRadius.circular(DesignTokens.radiusRound),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSkipButton(AppProvider provider, PersonaTheme persona) {
    return GestureDetector(
      onTap: provider.skipBreak,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          color: DesignTokens.surface,
          borderRadius: BorderRadius.circular(DesignTokens.radius20),
          border: Border.all(color: DesignTokens.border, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.skip_next_rounded,
              color: DesignTokens.textMuted,
              size: 20,
            ),
            const SizedBox(width: DesignTokens.spacing8),
            Text(
              'Skip Break',
              style: TextStyle(
                color: DesignTokens.textMuted,
                fontSize: DesignTokens.fontSizeBodySmall,
                fontWeight: DesignTokens.fontWeightMedium,
                fontFamily: DesignTokens.fontFamilyPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
