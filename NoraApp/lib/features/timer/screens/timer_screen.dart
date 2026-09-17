import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/enums/age_group.dart';
import '../../../core/router/slide_route.dart';
import '../../../core/theme/persona_theme.dart';
import '../../../providers/persona_provider.dart';
import '../../../providers/timer_provider.dart';
import '../../../providers/pomodoro_provider.dart';
import '../../../services/flow_state_sounds.dart';
import '../../../services/haptic_service.dart';
import '../../../widgets/flow_state_sound_player.dart';
import '../../../widgets/nora_components.dart';
import '../widgets/breathe_tab.dart';
import 'break_screen.dart';

/// Timer Screen — Pomodoro with AI "interrupter" feature.
/// Adapts based on age group:
/// - Baby: Short play sessions (5 min max), colorful, fun sounds
/// - Kid: Medium focus sessions (15 min max), gamified
/// - Teen: Standard Pomodoro (25 min), social features
/// - Adult: Deep work sessions (50 min), productivity focused
class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen>
    with TickerProviderStateMixin {
  bool _showInterrupter = false;
  String? _interrupterMessage;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Flow-state sound player
  bool _isSoundPlaying = false;
  SoundType? _currentSound;

  // Tab selector: 0 = Focus, 1 = Breathe
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleSound(SoundType sound) {
    HapticService.buttonPressed();
    setState(() {
      if (_isSoundPlaying && _currentSound == sound) {
        _isSoundPlaying = false;
        _currentSound = null;
      } else {
        _isSoundPlaying = true;
        _currentSound = sound;
      }
    });
  }

  void _triggerInterrupter() {
    final messages = _getInterrupterMessages(
      context.read<PersonaProvider>().persona.ageGroup,
    );
    final random = Random();
    setState(() {
      _interrupterMessage = messages[random.nextInt(messages.length)];
      _showInterrupter = true;
    });
    // Auto-dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showInterrupter = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PersonaProvider, TimerProvider>(
      builder: (context, personaProvider, timerProvider, _) {
        final persona = personaProvider.persona;
        final progress = timerProvider.timerProgress;

        // Auto-navigate to break screen when break phase starts
        if (timerProvider.isBreakPhase) {
          // Record session in PomodoroProvider
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              final pomodoro = context.read<PomodoroProvider>();
              pomodoro.recordSession(timerProvider.totalTimerSeconds ~/ 60);

              Navigator.of(context).push(
                FadePageRoute(
                  pageBuilder: (_, __, ___) => ChangeNotifierProvider.value(
                    value: timerProvider,
                    child: const BreakScreen(),
                  ),
                ),
              );
            }
          });
        }

        return Scaffold(
          backgroundColor: DesignTokens.background,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(persona, timerProvider),
                _buildTabSelector(persona),
                Expanded(
                  child: _selectedTab == 0
                      ? _buildFocusTab(timerProvider, persona, progress)
                      : _buildBreatheTab(persona),
                ),
                // AI Interrupter overlay
                if (_showInterrupter) _buildInterrupterOverlay(persona),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(PersonaTheme persona, TimerProvider provider) {
    return Consumer<PomodoroProvider>(
      builder: (context, pomodoro, _) {
        return Container(
          padding: const EdgeInsets.all(DesignTokens.spacing20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTitle(persona.ageGroup),
                      style: TextStyle(
                        color: DesignTokens.textPrimary,
                        fontSize: DesignTokens.fontSizeH2,
                        fontWeight: DesignTokens.fontWeightBold,
                        fontFamily: DesignTokens.fontFamilyDisplay,
                      ),
                    ),
                    Text(
                      _getSubtitle(persona.ageGroup),
                      style: TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: DesignTokens.fontSizeBodySmall,
                        fontFamily: DesignTokens.fontFamilyPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              // Cycle progress badge (when auto-cycle is enabled)
              if (pomodoro.autoCycleEnabled) ...[
                GestureDetector(
                  onTap: () =>
                      Navigator.pushNamed(context, '/pomodoro-setup'),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: pomodoro.allCyclesCompleted
                          ? DesignTokens.success.withValues(alpha: 0.15)
                          : DesignTokens.accent.withValues(alpha: 0.15),
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radius20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          pomodoro.allCyclesCompleted
                              ? Icons.check_circle_rounded
                              : Icons.repeat_rounded,
                          color: pomodoro.allCyclesCompleted
                              ? DesignTokens.success
                              : DesignTokens.accent,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${pomodoro.completedCycles}/${pomodoro.targetCycles}',
                          style: TextStyle(
                            color: pomodoro.allCyclesCompleted
                                ? DesignTokens.success
                                : DesignTokens.accent,
                            fontSize: DesignTokens.fontSizeCaption,
                            fontWeight: DesignTokens.fontWeightBold,
                            fontFamily: DesignTokens.fontFamilyPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              // Session counter badge
              if (provider.completedSessionsInCycle > 0) ...[
                const SizedBox(width: DesignTokens.spacing8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              // Screen time indicator (for kids/teens)
              if (persona.ageGroup.screenTimeLimitMinutes > 0) ...[
                if (provider.completedSessionsInCycle > 0)
                  const SizedBox(width: DesignTokens.spacing8),
                _buildScreenTimeBadge(persona),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildScreenTimeBadge(PersonaTheme persona) {
    final provider = context.read<TimerProvider>();
    final exceeded = provider.isScreenTimeExceeded;
    final limit = persona.ageGroup.screenTimeLimitMinutes;
    final current = provider.screenTimeTodayMinutes;

    return NoraCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      backgroundColor:
          exceeded ? DesignTokens.accent.withValues(alpha: 0.1) : null,
      border:
          exceeded ? Border.all(color: DesignTokens.accent.withValues(alpha: 0.3), width: 1) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            exceeded
                ? Icons.hourglass_bottom_rounded
                : Icons.screen_lock_portrait_rounded,
            color: exceeded ? DesignTokens.accent : DesignTokens.textMuted,
            size: 16,
          ),
          const SizedBox(width: DesignTokens.spacing4),
          Text(
            '$current / $limit min',
            style: TextStyle(
              color: exceeded ? DesignTokens.accent : DesignTokens.textMuted,
              fontSize: DesignTokens.fontSizeCaption,
              fontWeight: DesignTokens.fontWeightMedium,
              fontFamily: DesignTokens.fontFamilyPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // TAB SELECTOR
  // ═══════════════════════════════════════════════

  Widget _buildTabSelector(PersonaTheme persona) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacing24, vertical: DesignTokens.spacing8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: DesignTokens.surface,
          borderRadius: BorderRadius.circular(DesignTokens.radius16),
          border: Border.all(color: DesignTokens.border, width: 1),
        ),
        child: Row(
          children: [
            _buildTab(0, Icons.center_focus_strong_rounded, 'Focus', persona),
            _buildTab(1, Icons.air_rounded, 'Breathe', persona),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index, IconData icon, String label, PersonaTheme persona) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? persona.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : DesignTokens.textMuted,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : DesignTokens.textMuted,
                  fontSize: DesignTokens.fontSizeCaption,
                  fontWeight:
                      isSelected ? DesignTokens.fontWeightSemiBold : FontWeight.normal,
                  fontFamily: DesignTokens.fontFamilyPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // FOCUS TAB CONTENT
  // ═══════════════════════════════════════════════

  Widget _buildFocusTab(
      TimerProvider provider, PersonaTheme persona, double progress) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPhaseIndicator(persona, provider),
            const SizedBox(height: DesignTokens.spacing16),
            _buildTimerRing(provider, progress, persona),
            const SizedBox(height: DesignTokens.spacing24),
            _buildSessionDots(provider, persona),
            const SizedBox(height: DesignTokens.spacing24),
            _buildDurationSelector(provider, persona),
            const SizedBox(height: DesignTokens.spacing24),
            _buildControls(provider, persona),
            if (persona.ageGroup != AgeGroup.baby) ...[
              const SizedBox(height: DesignTokens.spacing24),
              _buildInterrupterButton(persona),
            ],
            // Flow-State Sound Player
            const SizedBox(height: DesignTokens.spacing24),
            FlowStateSoundPlayer(
              persona: persona,
              isPlaying: _isSoundPlaying,
              currentSound: _currentSound,
              onPlay: () =>
                  _toggleSound(_currentSound ?? SoundType.brownNoise),
              onStop: () => setState(() {
                _isSoundPlaying = false;
                _currentSound = null;
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // BREATHE TAB CONTENT
  // ═══════════════════════════════════════════════

  Widget _buildBreatheTab(PersonaTheme persona) {
    return BreatheTab(persona: persona);
  }

  Widget _buildTimerRing(
      TimerProvider provider, double progress, PersonaTheme persona) {
    final isRunning = provider.isTimerRunning;
    final size = persona.ageGroup == AgeGroup.baby ? 220.0 : 260.0;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isRunning ? _pulseAnimation.value : 1.0,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background ring
                SizedBox(
                  width: size,
                  height: size,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 16,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      DesignTokens.border,
                    ),
                  ),
                ),
                // Progress ring — Selector rebuilds only on timer tick
                _TimerProgressRing(
                  size: size,
                  persona: persona,
                ),
                // Center content
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TimerCountdownText(persona: persona),
                    const SizedBox(height: DesignTokens.spacing4),
                    Text(
                      _getTimerLabel(persona.ageGroup),
                      style: TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: DesignTokens.fontSizeCaption,
                        fontFamily: DesignTokens.fontFamilyPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhaseIndicator(PersonaTheme persona, TimerProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: DesignTokens.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radius20),
        border: Border.all(color: DesignTokens.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.center_focus_strong_rounded,
            color: persona.primary,
            size: 16,
          ),
          const SizedBox(width: DesignTokens.spacing8),
          Text(
            'Focus Session',
            style: TextStyle(
              color: DesignTokens.textPrimary,
              fontSize: DesignTokens.fontSizeCaption,
              fontWeight: DesignTokens.fontWeightSemiBold,
              fontFamily: DesignTokens.fontFamilyPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionDots(TimerProvider provider, PersonaTheme persona) {
    final total = persona.ageGroup.pomodoroSessionsPerCycle;
    final completed = provider.completedSessionsInCycle;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final isCompleted = index < completed;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isCompleted ? 24 : 10,
            height: 10,
            decoration: BoxDecoration(
              color: isCompleted
                  ? persona.primary
                  : DesignTokens.border,
              borderRadius: BorderRadius.circular(DesignTokens.radiusRound),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDurationSelector(TimerProvider provider, PersonaTheme persona) {
    final durations = _getDurationsForAgeGroup(persona.ageGroup);
    final currentMinutes = provider.totalTimerSeconds ~/ 60;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: durations.map((minutes) {
        final isSelected = currentMinutes == minutes;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GestureDetector(
            onTap: provider.isTimerRunning
                ? null
                : () => provider.setTimerDuration(minutes),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? persona.primary : DesignTokens.surface,
                borderRadius: BorderRadius.circular(DesignTokens.radius20),
                border: Border.all(
                  color: isSelected ? persona.primary : DesignTokens.border,
                  width: 1,
                ),
              ),
              child: Text(
                '$minutes min',
                style: TextStyle(
                  color: isSelected
                      ? (persona.isDark
                          ? DesignTokens.background
                          : Colors.white)
                      : DesignTokens.textMuted,
                  fontSize: DesignTokens.fontSizeCaption,
                  fontWeight: DesignTokens.fontWeightMedium,
                  fontFamily: DesignTokens.fontFamilyPrimary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildControls(TimerProvider provider, PersonaTheme persona) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reset button
        _buildTimerIconButton(
          onTap: provider.resetTimer,
          icon: Icons.refresh_rounded,
          color: DesignTokens.textMuted,
        ),
        const SizedBox(width: DesignTokens.spacing24),
        // Play/Pause button
        GestureDetector(
          onTap: () {
            if (provider.isTimerRunning) {
              HapticService.timerPaused();
              provider.pauseTimer();
            } else {
              HapticService.timerStarted();
              provider.startTimer();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [persona.primary, persona.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
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
              provider.isTimerRunning
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
        const SizedBox(width: DesignTokens.spacing24),
        // Skip button
        _buildTimerIconButton(
          onTap: provider.completeTimer,
          icon: Icons.skip_next_rounded,
          color: DesignTokens.textMuted,
        ),
      ],
    );
  }

  Widget _buildTimerIconButton(
      {required VoidCallback onTap,
      required IconData icon,
      required Color color}) {
    return _PressedTimerIconButton(
      onTap: onTap,
      icon: icon,
      color: color,
    );
  }

  Widget _buildInterrupterButton(PersonaTheme persona) {
    return GestureDetector(
      onTap: _triggerInterrupter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: DesignTokens.surface,
          borderRadius: BorderRadius.circular(DesignTokens.radius20),
          border: Border.all(color: DesignTokens.border, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              color: persona.primary,
              size: 18,
            ),
            const SizedBox(width: DesignTokens.spacing8),
            Text(
              _getInterrupterButtonLabel(persona.ageGroup),
              style: TextStyle(
                color: DesignTokens.textMuted,
                fontSize: DesignTokens.fontSizeCaption,
                fontFamily: DesignTokens.fontFamilyPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterrupterOverlay(PersonaTheme persona) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      bottom: _showInterrupter ? 0 : -100,
      left: DesignTokens.spacing20,
      right: DesignTokens.spacing20,
      child: NoraCard(
        backgroundColor: persona.primary,
        child: Row(
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: SvgPicture.asset(
                persona.mascotAssetPath,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: DesignTokens.spacing12),
            Expanded(
              child: Text(
                _interrupterMessage ?? '',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: DesignTokens.fontSizeBodySmall,
                  fontFamily: DesignTokens.fontFamilyPrimary,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _showInterrupter = false),
              child: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Age-specific data ───

  String _getTitle(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
      case AgeGroup.child:
        return 'Play Time';
      case AgeGroup.kid:
        return 'Focus Quest';
      case AgeGroup.teen:
        return 'Deep Work';
      case AgeGroup.adult:
        return 'Focus Session';
    }
  }

  String _getSubtitle(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
      case AgeGroup.child:
        return 'Let\'s play and learn!';
      case AgeGroup.kid:
        return 'Complete your mission!';
      case AgeGroup.teen:
        return 'Enter the zone';
      case AgeGroup.adult:
        return 'Minimize distractions';
    }
  }

  String _getTimerLabel(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
      case AgeGroup.child:
        return 'minutes of play';
      case AgeGroup.kid:
        return 'minutes to focus';
      case AgeGroup.teen:
        return 'minutes remaining';
      case AgeGroup.adult:
        return 'remaining';
    }
  }

  List<int> _getDurationsForAgeGroup(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
      case AgeGroup.child:
        return [3, 5, 10];
      case AgeGroup.kid:
        return [10, 15, 20];
      case AgeGroup.teen:
        return [15, 25, 35];
      case AgeGroup.adult:
        return [25, 45, 60];
    }
  }

  String _getInterrupterButtonLabel(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
      case AgeGroup.child:
        return 'Nora says hi!';
      case AgeGroup.kid:
        return 'Ask Nora for help';
      case AgeGroup.teen:
        return 'Need a break?';
      case AgeGroup.adult:
        return 'AI Check-in';
    }
  }

  List<String> _getInterrupterMessages(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
      case AgeGroup.child:
        return [
          'You\'re doing amazing!',
          'Time for a stretching break!',
          'Let\'s sing a song!',
          'Great job playing!',
        ];
      case AgeGroup.kid:
        return [
          'You\'re on fire! Keep going!',
          'Try taking 3 deep breaths!',
          'What\'s your favorite subject?',
          'You\'re almost at your goal!',
        ];
      case AgeGroup.teen:
        return [
          'Remember: progress, not perfection.',
          'Try the Pomodoro technique: 25/5!',
          'Active recall: close your notes and test yourself!',
          'You\'re building great habits!',
        ];
      case AgeGroup.adult:
        return [
          'Check your posture. Sit up straight!',
          'Have you hydrated recently?',
          'Review your top 3 priorities for today.',
          'You\'re making excellent progress!',
        ];
    }
  }
}

class _PressedTimerIconButton extends StatefulWidget {
  const _PressedTimerIconButton({
    required this.onTap,
    required this.icon,
    required this.color,
  });

  final VoidCallback onTap;
  final IconData icon;
  final Color color;

  @override
  State<_PressedTimerIconButton> createState() =>
      _PressedTimerIconButtonState();
}

class _PressedTimerIconButtonState extends State<_PressedTimerIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: DesignTokens.surface,
            shape: BoxShape.circle,
            border: Border.all(color: DesignTokens.border, width: 1),
            boxShadow: DesignTokens.shadowRaised,
          ),
          child: Icon(widget.icon, color: widget.color, size: 24),
        ),
      ),
    );
  }
}

/// Only rebuilds the progress ring on timer ticks, not the entire screen.
class _TimerProgressRing extends StatelessWidget {
  const _TimerProgressRing({required this.size, required this.persona});

  final double size;
  final PersonaTheme persona;

  @override
  Widget build(BuildContext context) {
    return Selector<TimerProvider, double>(
      selector: (_, p) => p.timerProgress,
      builder: (context, progress, _) {
        return SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 16,
            valueColor: AlwaysStoppedAnimation<Color>(persona.primary),
            strokeCap: StrokeCap.round,
          ),
        );
      },
    );
  }
}

/// Only rebuilds the countdown text on timer ticks, not the entire screen.
class _TimerCountdownText extends StatelessWidget {
  const _TimerCountdownText({required this.persona});

  final PersonaTheme persona;

  @override
  Widget build(BuildContext context) {
    return Selector<TimerProvider, String>(
      selector: (_, p) => p.timerDisplay,
      builder: (context, display, _) {
        return Text(
          display,
          style: TextStyle(
            color: DesignTokens.textPrimary,
            fontSize: DesignTokens.fontSizeTimer,
            fontWeight: DesignTokens.fontWeightBold,
            fontFamily: DesignTokens.fontFamilyDisplay,
            height: 1,
          ),
        );
      },
    );
  }
}
