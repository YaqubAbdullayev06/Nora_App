import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../providers/pomodoro_provider.dart';
import '../../../widgets/nora_components.dart';

/// Pomodoro Setup Screen — Configure automatic multi-cycle Pomodoro settings.
///
/// Users can:
/// - Enable/disable auto-cycle
/// - Set target number of cycles
/// - View today's progress
class PomodoroSetupScreen extends StatefulWidget {
  const PomodoroSetupScreen({super.key});

  @override
  State<PomodoroSetupScreen> createState() => _PomodoroSetupScreenState();
}

class _PomodoroSetupScreenState extends State<PomodoroSetupScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.background,
      body: SafeArea(
        child: Consumer<PomodoroProvider>(
          builder: (context, pomodoro, _) {
            return CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(DesignTokens.spacing20),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: DesignTokens.surface,
                              borderRadius:
                                  BorderRadius.circular(DesignTokens.radius12),
                              border: Border.all(color: DesignTokens.border),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_rounded,
                              color: DesignTokens.textPrimary,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: DesignTokens.spacing12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pomodoro Cycles',
                                style: TextStyle(
                                  color: DesignTokens.textPrimary,
                                  fontSize: DesignTokens.fontSizeH2,
                                  fontWeight: DesignTokens.fontWeightBold,
                                  fontFamily: DesignTokens.fontFamilyDisplay,
                                ),
                              ),
                              Text(
                                'Automatically chain focus sessions',
                                style: TextStyle(
                                  color: DesignTokens.textMuted,
                                  fontSize: DesignTokens.fontSizeBodySmall,
                                  fontFamily: DesignTokens.fontFamilyPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Today's progress
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacing20),
                    child: _buildTodayProgress(pomodoro),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: DesignTokens.spacing24),
                ),

                // Auto-cycle toggle
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacing20),
                    child: _buildAutoCycleToggle(pomodoro),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: DesignTokens.spacing24),
                ),

                // Target cycles selector
                if (pomodoro.autoCycleEnabled)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.spacing20),
                      child: _buildTargetCyclesSelector(pomodoro),
                    ),
                  ),

                if (pomodoro.autoCycleEnabled)
                  const SliverToBoxAdapter(
                    child: SizedBox(height: DesignTokens.spacing24),
                  ),

                // Info card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacing20),
                    child: _buildInfoCard(),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: DesignTokens.spacing40),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTodayProgress(PomodoroProvider pomodoro) {
    return NoraCard(
      backgroundColor: DesignTokens.accent.withValues(alpha: 0.06),
      border: Border.all(color: DesignTokens.accent.withValues(alpha: 0.2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Progress',
                style: TextStyle(
                  color: DesignTokens.textPrimary,
                  fontSize: DesignTokens.fontSizeBody,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  fontFamily: DesignTokens.fontFamilyPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: DesignTokens.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                ),
                child: Text(
                  '${pomodoro.completedCycles}/${pomodoro.targetCycles} cycles',
                  style: TextStyle(
                    color: DesignTokens.accent,
                    fontSize: DesignTokens.fontSizeCaption,
                    fontWeight: DesignTokens.fontWeightBold,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacing12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pomodoro.cycleProgress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: DesignTokens.border.withValues(alpha: 0.3),
              valueColor:
                  AlwaysStoppedAnimation<Color>(DesignTokens.accent),
            ),
          ),
          const SizedBox(height: DesignTokens.spacing8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${pomodoro.totalSessionsToday} sessions • ${pomodoro.totalFocusMinutesToday} min focused',
                style: TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: DesignTokens.fontSizeCaption,
                  fontFamily: DesignTokens.fontFamilyPrimary,
                ),
              ),
              if (pomodoro.allCyclesCompleted)
                Text(
                  'Complete!',
                  style: TextStyle(
                    color: DesignTokens.success,
                    fontSize: DesignTokens.fontSizeCaption,
                    fontWeight: DesignTokens.fontWeightBold,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAutoCycleToggle(PomodoroProvider pomodoro) {
    return NoraCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DesignTokens.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(DesignTokens.radius10),
            ),
            child: Icon(Icons.repeat_rounded,
                color: DesignTokens.accent, size: 20),
          ),
          const SizedBox(width: DesignTokens.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto-Cycle',
                  style: TextStyle(
                    color: DesignTokens.textPrimary,
                    fontSize: DesignTokens.fontSizeBodySmall,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  ),
                ),
                Text(
                  'Automatically start next focus session after break',
                  style: TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: DesignTokens.fontSizeCaption,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: pomodoro.autoCycleEnabled,
            onChanged: (_) => pomodoro.toggleAutoCycle(),
            activeThumbColor: DesignTokens.accent,
          ),
        ],
      ),
    );
  }

  Widget _buildTargetCyclesSelector(PomodoroProvider pomodoro) {
    return NoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Target Cycles',
            style: TextStyle(
              color: DesignTokens.textPrimary,
              fontSize: DesignTokens.fontSizeBody,
              fontWeight: DesignTokens.fontWeightSemiBold,
              fontFamily: DesignTokens.fontFamilyPrimary,
            ),
          ),
          const SizedBox(height: DesignTokens.spacing4),
          Text(
            'How many full pomodoro cycles to complete today',
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: DesignTokens.fontSizeCaption,
              fontFamily: DesignTokens.fontFamilyPrimary,
            ),
          ),
          const SizedBox(height: DesignTokens.spacing16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Decrease button
              _buildCycleButton(
                icon: Icons.remove_rounded,
                onPressed: pomodoro.targetCycles > 1
                    ? () =>
                        pomodoro.setTargetCycles(pomodoro.targetCycles - 1)
                    : null,
              ),
              const SizedBox(width: DesignTokens.spacing24),
              // Current value
              Column(
                children: [
                  Text(
                    '${pomodoro.targetCycles}',
                    style: TextStyle(
                      color: DesignTokens.textPrimary,
                      fontSize: 48,
                      fontWeight: DesignTokens.fontWeightBold,
                      fontFamily: DesignTokens.fontFamilyDisplay,
                    ),
                  ),
                  Text(
                    pomodoro.targetCycles == 1 ? 'cycle' : 'cycles',
                    style: TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: DesignTokens.fontSizeCaption,
                      fontFamily: DesignTokens.fontFamilyPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: DesignTokens.spacing24),
              // Increase button
              _buildCycleButton(
                icon: Icons.add_rounded,
                onPressed: pomodoro.targetCycles < 10
                    ? () =>
                        pomodoro.setTargetCycles(pomodoro.targetCycles + 1)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacing12),
          // Quick select chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [2, 3, 4, 6].map((cycles) {
              final isSelected = pomodoro.targetCycles == cycles;
              return GestureDetector(
                onTap: () => pomodoro.setTargetCycles(cycles),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? DesignTokens.accent
                        : DesignTokens.surface,
                    borderRadius: BorderRadius.circular(DesignTokens.radius20),
                    border: Border.all(
                      color: isSelected
                          ? DesignTokens.accent
                          : DesignTokens.border,
                    ),
                  ),
                  child: Text(
                    '$cycles cycles',
                    style: TextStyle(
                      color: isSelected ? Colors.white : DesignTokens.textMuted,
                      fontSize: DesignTokens.fontSizeCaption,
                      fontWeight: DesignTokens.fontWeightMedium,
                      fontFamily: DesignTokens.fontFamilyPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleButton({
    required IconData icon,
    VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: onPressed != null
              ? DesignTokens.accent.withValues(alpha: 0.15)
              : DesignTokens.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: onPressed != null
                ? DesignTokens.accent.withValues(alpha: 0.3)
                : DesignTokens.border,
          ),
        ),
        child: Icon(
          icon,
          color: onPressed != null ? DesignTokens.accent : DesignTokens.textMuted,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return NoraCard(
      backgroundColor: DesignTokens.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: DesignTokens.accent, size: 20),
              const SizedBox(width: DesignTokens.spacing8),
              Text(
                'How it works',
                style: TextStyle(
                  color: DesignTokens.textPrimary,
                  fontSize: DesignTokens.fontSizeBodySmall,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  fontFamily: DesignTokens.fontFamilyPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacing12),
          _buildInfoRow(
            '1. Focus session completes',
            'Timer reaches zero',
          ),
          const SizedBox(height: DesignTokens.spacing8),
          _buildInfoRow(
            '2. Break starts automatically',
            'Short or long break based on cycle',
          ),
          const SizedBox(height: DesignTokens.spacing8),
          _buildInfoRow(
            '3. Next focus auto-starts',
            'When auto-cycle is enabled',
          ),
          const SizedBox(height: DesignTokens.spacing8),
          _buildInfoRow(
            '4. Cycle repeats',
            'Until target cycles reached',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: DesignTokens.accent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: DesignTokens.spacing8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: DesignTokens.textPrimary,
                  fontSize: DesignTokens.fontSizeCaption,
                  fontWeight: DesignTokens.fontWeightMedium,
                  fontFamily: DesignTokens.fontFamilyPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: DesignTokens.fontSizeTiny,
                  fontFamily: DesignTokens.fontFamilyPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
