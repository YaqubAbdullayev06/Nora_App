import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/router/slide_route.dart';
import '../../../providers/setup_provider.dart';
import '../../../main.dart';

/// Post-onboarding setup wizard.
/// Guides user through Accountability Lock, Hard Cap, Pomodoro, Earn Screen Time.
/// Every step is skippable. Permissions are requested at the end.
class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _animController;
  int _currentStep = 0;
  static const _totalSteps = 6; // intro + 4 features + permissions

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _animController.reset();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
      _animController.forward();
    } else {
      _finish();
    }
  }

  void _skipStep() {
    _nextStep();
  }

  Future<void> _finish() async {
    final setup = context.read<SetupProvider>();
    await setup.complete();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      FadePageRoute(pageBuilder: (_, __, ___) => const MainScreen()),
      (_) => false,
    );
  }

  void _skipAll() async {
    final setup = context.read<SetupProvider>();
    await setup.complete();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      FadePageRoute(pageBuilder: (_, __, ___) => const MainScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: DesignTokens.background,
        body: SafeArea(
          child: Column(
            children: [
              // Top bar with skip-all
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Progress dots
                    _buildProgressDots(),
                    // Skip all
                    if (_currentStep > 0 && _currentStep < _totalSteps - 1)
                      TextButton(
                        onPressed: _skipAll,
                        child: Text(
                          'Skip All',
                          style: TextStyle(
                            color: DesignTokens.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Page content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentStep = i),
                  children: [
                    _buildIntroStep(),
                    _buildAccountabilityStep(),
                    _buildHardCapStep(),
                    _buildPomodoroStep(),
                    _buildEarnScreenTimeStep(),
                    _buildPermissionsStep(),
                  ],
                ),
              ),

              // Bottom buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Row(
                  children: [
                    if (_currentStep > 0 && _currentStep < _totalSteps - 1)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _skipStep,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: DesignTokens.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(DesignTokens.radius14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Skip',
                            style: TextStyle(color: DesignTokens.textSecondary),
                          ),
                        ),
                      ),
                    if (_currentStep > 0 && _currentStep < _totalSteps - 1)
                      const SizedBox(width: 12),
                    Expanded(
                      flex: _currentStep == 0 ? 1 : 1,
                      child: ElevatedButton(
                        onPressed: _nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DesignTokens.primary,
                          foregroundColor: DesignTokens.background,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(DesignTokens.radius14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                        child: Text(
                          _currentStep == 0
                              ? "Let's Go"
                              : _currentStep == _totalSteps - 1
                                  ? 'Finish'
                                  : 'Next',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressDots() {
    return Row(
      children: List.generate(_totalSteps, (i) {
        final isActive = i == _currentStep;
        final isDone = i < _currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isDone
                ? DesignTokens.primary
                : isActive
                    ? DesignTokens.primary
                    : DesignTokens.textMuted.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  // ── STEP 0: Intro ──

  Widget _buildIntroStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: DesignTokens.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.rocket_launch_rounded,
              color: DesignTokens.primary,
              size: 48,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Almost There!',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamilyDisplay,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: DesignTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Let\'s set up a few powerful features\nto help you stay focused.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: DesignTokens.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          _buildFeaturePreview(
            icon: Icons.lock_outline,
            title: 'Accountability Lock',
            color: DesignTokens.primary,
          ),
          const SizedBox(height: 12),
          _buildFeaturePreview(
            icon: Icons.timer_outlined,
            title: 'Daily Hard Cap',
            color: DesignTokens.warning,
          ),
          const SizedBox(height: 12),
          _buildFeaturePreview(
            icon: Icons.local_fire_department_outlined,
            title: 'Pomodoro Cycles',
            color: DesignTokens.accentSecondary,
          ),
          const SizedBox(height: 12),
          _buildFeaturePreview(
            icon: Icons.emoji_events_outlined,
            title: 'Earn Screen Time',
            color: DesignTokens.success,
          ),
          const SizedBox(height: 24),
          Text(
            'Everything is optional — you can skip any step.',
            style: TextStyle(
              fontSize: 13,
              color: DesignTokens.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePreview({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: DesignTokens.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              color: DesignTokens.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Icon(Icons.chevron_right, color: DesignTokens.textMuted, size: 18),
        ],
      ),
    );
  }

  // ── STEP 1: Accountability Lock ──

  Widget _buildAccountabilityStep() {
    final setup = context.watch<SetupProvider>();
    return _FeatureStep(
      icon: Icons.lock_outline,
      iconColor: DesignTokens.primary,
      title: 'Accountability Lock',
      subtitle: 'Guardian PIN lock for focus sessions',
      description: 'Set a PIN that a trusted person holds. '
          'When you\'re in a focus session, you\'ll need their PIN to skip or exit early.',
      features: [
        'Prevents impulsive session exits',
        'Choose a guardian you trust',
        'Set lock duration (7–90 days)',
      ],
      child: _buildAccountabilityPreview(setup),
    );
  }

  Widget _buildAccountabilityPreview(SetupProvider setup) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radius14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: DesignTokens.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Enable Accountability Lock?',
                        style: TextStyle(
                          color: DesignTokens.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        )),
                    Text('You can set this up later in Settings',
                        style: TextStyle(
                          color: DesignTokens.textMuted,
                          fontSize: 12,
                        )),
                  ],
                ),
              ),
              Switch(
                value: setup.accountabilityEnabled,
                onChanged: setup.setAccountability,
                activeThumbColor: DesignTokens.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── STEP 2: Daily Hard Cap ──

  Widget _buildHardCapStep() {
    final setup = context.watch<SetupProvider>();
    return _FeatureStep(
      icon: Icons.timer_outlined,
      iconColor: DesignTokens.warning,
      title: 'Daily Hard Cap',
      subtitle: 'Set a total daily screen time limit',
      description: 'Define the maximum screen time you want per day. '
          'When you approach the limit, Nora will gently warn you. '
          'At 100%, you\'ll be blocked (with optional PIN override).',
      features: [
        'Soft warning at 80% usage',
        'Hard warning at 90% usage',
        'Full block at 100% (optional PIN)',
      ],
      child: _buildHardCapPreview(setup),
    );
  }

  Widget _buildHardCapPreview(SetupProvider setup) {
    final hours = setup.hardCapMinutes ~/ 60;
    final minutes = setup.hardCapMinutes % 60;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radius14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.hourglass_bottom_rounded,
                  color: DesignTokens.warning, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Enable Daily Hard Cap?',
                        style: TextStyle(
                          color: DesignTokens.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        )),
                    Text('Currently: ${hours}h ${minutes}m per day',
                        style: TextStyle(
                          color: DesignTokens.textMuted,
                          fontSize: 12,
                        )),
                  ],
                ),
              ),
              Switch(
                value: setup.hardCapEnabled,
                onChanged: (v) => setup.setHardCap(v),
                activeThumbColor: DesignTokens.warning,
              ),
            ],
          ),
          if (setup.hardCapEnabled) ...[
            const SizedBox(height: 12),
            // Quick select chips
            Row(
              children: [
                _buildCapChip(setup, 60, '1h'),
                const SizedBox(width: 8),
                _buildCapChip(setup, 90, '1h 30m'),
                const SizedBox(width: 8),
                _buildCapChip(setup, 120, '2h'),
                const SizedBox(width: 8),
                _buildCapChip(setup, 180, '3h'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCapChip(SetupProvider setup, int minutes, String label) {
    final isSelected = setup.hardCapMinutes == minutes;
    return Expanded(
      child: GestureDetector(
        onTap: () => setup.setHardCapMinutes(minutes),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? DesignTokens.warning.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? DesignTokens.warning
                  : DesignTokens.border,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? DesignTokens.warning : DesignTokens.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  // ── STEP 3: Pomodoro Cycles ──

  Widget _buildPomodoroStep() {
    final setup = context.watch<SetupProvider>();
    return _FeatureStep(
      icon: Icons.local_fire_department_outlined,
      iconColor: DesignTokens.accentSecondary,
      title: 'Pomodoro Cycles',
      subtitle: 'Chain focus sessions automatically',
      description: 'Set up Pomodoro cycles: focus for 25 minutes, '
          'then take a 5-minute break. Nora can automatically chain '
          'multiple cycles together.',
      features: [
        '25 min focus → 5 min break',
        'Auto-chain multiple cycles',
        'Track sessions & focus time',
      ],
      child: _buildPomodoroPreview(setup),
    );
  }

  Widget _buildPomodoroPreview(SetupProvider setup) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radius14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.local_fire_department_outlined,
                  color: DesignTokens.accentSecondary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Enable Pomodoro Cycles?',
                        style: TextStyle(
                          color: DesignTokens.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        )),
                    Text('Chain focus sessions with breaks',
                        style: TextStyle(
                          color: DesignTokens.textMuted,
                          fontSize: 12,
                        )),
                  ],
                ),
              ),
              Switch(
                value: setup.pomodoroEnabled,
                onChanged: (v) => setup.setPomodoro(v),
                activeThumbColor: DesignTokens.accentSecondary,
              ),
            ],
          ),
          if (setup.pomodoroEnabled) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Target cycles:',
                    style: TextStyle(
                      color: DesignTokens.textSecondary,
                      fontSize: 13,
                    )),
                const Spacer(),
                _buildCycleButton(setup, -1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '${setup.pomodoroCycles}',
                    style: TextStyle(
                      color: DesignTokens.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _buildCycleButton(setup, 1),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [2, 3, 4, 6].map((c) {
                final isSelected = setup.pomodoroCycles == c;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setup.setPomodoroCycles(c),
                    child: Container(
                      width: 40,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? DesignTokens.accentSecondary.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? DesignTokens.accentSecondary
                              : DesignTokens.border,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$c',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? DesignTokens.accentSecondary
                                : DesignTokens.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCycleButton(SetupProvider setup, int delta) {
    return GestureDetector(
      onTap: () {
        final newCycles = setup.pomodoroCycles + delta;
        if (newCycles >= 1 && newCycles <= 10) {
          setup.setPomodoroCycles(newCycles);
        }
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: DesignTokens.surfaceRaised,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(
            delta > 0 ? Icons.add : Icons.remove,
            color: DesignTokens.textSecondary,
            size: 16,
          ),
        ),
      ),
    );
  }

  // ── STEP 4: Earn Screen Time ──

  Widget _buildEarnScreenTimeStep() {
    final setup = context.watch<SetupProvider>();
    return _FeatureStep(
      icon: Icons.emoji_events_outlined,
      iconColor: DesignTokens.success,
      title: 'Earn Screen Time',
      subtitle: 'Complete habits to earn bonus minutes',
      description: 'Define real-world habits like "Meditate 5 min" or '
          '"Read 15 min". When you complete them, Nora adds bonus screen '
          'time to your daily cap.',
      features: [
        'Create custom habits',
        'Earn bonus minutes per completion',
        'Build positive routines',
      ],
      child: _buildEarnPreview(setup),
    );
  }

  Widget _buildEarnPreview(SetupProvider setup) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radius14),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events_outlined,
              color: DesignTokens.success, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Enable Earn Screen Time?',
                    style: TextStyle(
                      color: DesignTokens.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    )),
                Text('Set up habits that earn bonus minutes',
                    style: TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: 12,
                    )),
              ],
            ),
          ),
          Switch(
            value: setup.earnScreenTimeEnabled,
            onChanged: setup.setEarnScreenTime,
            activeThumbColor: DesignTokens.success,
          ),
        ],
      ),
    );
  }

  // ── STEP 5: Permissions ──

  Widget _buildPermissionsStep() {
    final setup = context.watch<SetupProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: DesignTokens.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.security_rounded,
              color: DesignTokens.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Permissions',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamilyDisplay,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: DesignTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Nora needs a few permissions to\nprotect your focus time.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: DesignTokens.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),

          // Permission cards
          _buildPermissionCard(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            description: 'Focus reminders & daily digest',
            required: true,
          ),
          const SizedBox(height: 10),
          _buildPermissionCard(
            icon: Icons.phonelink_lock,
            title: 'Usage Access',
            description: 'Track screen time & block apps',
            required: setup.hardCapEnabled || setup.accountabilityEnabled,
          ),
          const SizedBox(height: 10),
          _buildPermissionCard(
            icon: Icons.accessibility_new_rounded,
            title: 'Accessibility',
            description: 'Enable focus mode overlay',
            required: setup.accountabilityEnabled,
          ),

          const SizedBox(height: 24),
          Text(
            'You can grant or revoke these anytime in Settings.',
            style: TextStyle(
              fontSize: 12,
              color: DesignTokens.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required bool required,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DesignTokens.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(color: DesignTokens.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: DesignTokens.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: DesignTokens.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title,
                        style: TextStyle(
                          color: DesignTokens.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        )),
                    if (required) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: DesignTokens.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Required',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: DesignTokens.warning,
                            )),
                      ),
                    ],
                  ],
                ),
                Text(description,
                    style: TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: 12,
                    )),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: DesignTokens.textMuted, size: 18),
        ],
      ),
    );
  }
}

// ─── Reusable Feature Step Layout ───

class _FeatureStep extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String description;
  final List<String> features;
  final Widget child;

  const _FeatureStep({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.features,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Icon + title
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 36),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: DesignTokens.fontFamilyDisplay,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: DesignTokens.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: DesignTokens.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Description
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: DesignTokens.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          // Feature bullets
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline,
                    color: iconColor, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    f,
                    style: TextStyle(
                      fontSize: 14,
                      color: DesignTokens.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 20),
          // Interactive child
          child,
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
