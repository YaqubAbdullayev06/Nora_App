import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../providers/hard_cap_provider.dart';
import '../../../widgets/nora_components.dart';

/// Hard Cap Setup Screen — Configure daily total screen time limit.
///
/// Users set:
/// - Total daily cap (e.g., 2 hours)
/// - Soft warning threshold (e.g., 80%)
/// - Hard warning threshold (e.g., 90%)
/// - Whether PIN is required to bypass at 100%
class HardCapSetupScreen extends StatefulWidget {
  const HardCapSetupScreen({super.key});

  @override
  State<HardCapSetupScreen> createState() => _HardCapSetupScreenState();
}

class _HardCapSetupScreenState extends State<HardCapSetupScreen> {
  int _capHours = 2;
  int _capMinutes = 0;
  int _softWarningPercent = 80;
  int _hardWarningPercent = 90;
  bool _requirePin = false;

  int get _totalMinutes => (_capHours * 60) + _capMinutes;

  @override
  void initState() {
    super.initState();
    // Load existing settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cap = context.read<HardCapProvider>();
      if (cap.isActive) {
        setState(() {
          _capHours = cap.capMinutes ~/ 60;
          _capMinutes = cap.capMinutes % 60;
          _softWarningPercent = cap.softWarningPercent;
          _hardWarningPercent = cap.hardWarningPercent;
          _requirePin = cap.requirePinToOverride;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.background,
      body: SafeArea(
        child: Consumer<HardCapProvider>(
          builder: (context, cap, _) {
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
                                'Daily Hard Cap',
                                style: TextStyle(
                                  color: DesignTokens.textPrimary,
                                  fontSize: DesignTokens.fontSizeH2,
                                  fontWeight: DesignTokens.fontWeightBold,
                                  fontFamily: DesignTokens.fontFamilyDisplay,
                                ),
                              ),
                              Text(
                                'Set a total daily screen time limit',
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

                // Current status
                if (cap.isActive)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.spacing20),
                      child: _buildCurrentStatus(cap),
                    ),
                  ),

                if (cap.isActive)
                  const SliverToBoxAdapter(
                    child: SizedBox(height: DesignTokens.spacing24),
                  ),

                // Cap duration
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacing20),
                    child: _buildCapSection(),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: DesignTokens.spacing24),
                ),

                // Warning thresholds
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacing20),
                    child: _buildThresholdSection(),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: DesignTokens.spacing24),
                ),

                // PIN override option
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacing20),
                    child: _buildPinOverrideSection(),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: DesignTokens.spacing32),
                ),

                // Save button
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacing20),
                    child: _buildSaveButton(cap),
                  ),
                ),

                // Deactivate button
                if (cap.isActive)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(DesignTokens.spacing20),
                      child: _buildDeactivateButton(cap),
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

  Widget _buildCurrentStatus(HardCapProvider cap) {
    final progress = cap.usageProgress.clamp(0.0, 1.0);
    final remaining = cap.remainingMinutes;
    final color = remaining < 0
        ? DesignTokens.danger
        : remaining < 30
            ? DesignTokens.warning
            : DesignTokens.success;

    return NoraCard(
      backgroundColor: color.withValues(alpha: 0.06),
      border: Border.all(color: color.withValues(alpha: 0.2)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Usage',
                style: TextStyle(
                  color: DesignTokens.textPrimary,
                  fontSize: DesignTokens.fontSizeBody,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  fontFamily: DesignTokens.fontFamilyPrimary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                ),
                child: Text(
                  remaining < 0 ? 'OVER' : '${remaining}m left',
                  style: TextStyle(
                    color: color,
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
              value: progress,
              minHeight: 8,
              backgroundColor: DesignTokens.border.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: DesignTokens.spacing8),
          Text(
            '${cap.todayUsageMinutes} / ${cap.capMinutes} minutes',
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: DesignTokens.fontSizeCaption,
              fontFamily: DesignTokens.fontFamilyPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapSection() {
    return NoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Cap',
            style: TextStyle(
              color: DesignTokens.textPrimary,
              fontSize: DesignTokens.fontSizeBody,
              fontWeight: DesignTokens.fontWeightSemiBold,
              fontFamily: DesignTokens.fontFamilyPrimary,
            ),
          ),
          const SizedBox(height: DesignTokens.spacing4),
          Text(
            'Total screen time allowed per day',
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: DesignTokens.fontSizeCaption,
              fontFamily: DesignTokens.fontFamilyPrimary,
            ),
          ),
          const SizedBox(height: DesignTokens.spacing16),
          Row(
            children: [
              // Hours
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Hours',
                      style: TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: DesignTokens.fontSizeCaption,
                        fontFamily: DesignTokens.fontFamilyPrimary,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacing8),
                    Container(
                      decoration: BoxDecoration(
                        color: DesignTokens.background,
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radius8),
                        border: Border.all(color: DesignTokens.border),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove_rounded,
                                color: DesignTokens.textMuted),
                            onPressed: _capHours > 0
                                ? () => setState(() => _capHours--)
                                : null,
                          ),
                          Expanded(
                            child: Text(
                              '$_capHours',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: DesignTokens.textPrimary,
                                fontSize: DesignTokens.fontSizeH2,
                                fontWeight: DesignTokens.fontWeightBold,
                                fontFamily: DesignTokens.fontFamilyDisplay,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add_rounded,
                                color: DesignTokens.accent),
                            onPressed: _capHours < 12
                                ? () => setState(() => _capHours++)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DesignTokens.spacing16),
              // Minutes
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Minutes',
                      style: TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: DesignTokens.fontSizeCaption,
                        fontFamily: DesignTokens.fontFamilyPrimary,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacing8),
                    Container(
                      decoration: BoxDecoration(
                        color: DesignTokens.background,
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radius8),
                        border: Border.all(color: DesignTokens.border),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove_rounded,
                                color: DesignTokens.textMuted),
                            onPressed: _capMinutes > 0
                                ? () => setState(() => _capMinutes -= 15)
                                : null,
                          ),
                          Expanded(
                            child: Text(
                              '$_capMinutes',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: DesignTokens.textPrimary,
                                fontSize: DesignTokens.fontSizeH2,
                                fontWeight: DesignTokens.fontWeightBold,
                                fontFamily: DesignTokens.fontFamilyDisplay,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add_rounded,
                                color: DesignTokens.accent),
                            onPressed: _capMinutes < 45
                                ? () => setState(() => _capMinutes += 15)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacing12),
          Text(
            'Total: $_totalMinutes minutes (${(_totalMinutes / 60).toStringAsFixed(1)} hours)',
            style: TextStyle(
              color: DesignTokens.accent,
              fontSize: DesignTokens.fontSizeCaption,
              fontWeight: DesignTokens.fontWeightSemiBold,
              fontFamily: DesignTokens.fontFamilyPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdSection() {
    return NoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Warning Thresholds',
            style: TextStyle(
              color: DesignTokens.textPrimary,
              fontSize: DesignTokens.fontSizeBody,
              fontWeight: DesignTokens.fontWeightSemiBold,
              fontFamily: DesignTokens.fontFamilyPrimary,
            ),
          ),
          const SizedBox(height: DesignTokens.spacing4),
          Text(
            'When to show friction warnings',
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: DesignTokens.fontSizeCaption,
              fontFamily: DesignTokens.fontFamilyPrimary,
            ),
          ),
          const SizedBox(height: DesignTokens.spacing16),

          // Soft warning
          _buildThresholdRow(
            'Soft Warning',
            'Gentle notification',
            _softWarningPercent,
            DesignTokens.warning,
            (value) => setState(() => _softWarningPercent = value),
          ),
          const SizedBox(height: DesignTokens.spacing16),

          // Hard warning
          _buildThresholdRow(
            'Hard Warning',
            'Modal with reflection prompt',
            _hardWarningPercent,
            DesignTokens.danger,
            (value) => setState(() => _hardWarningPercent = value),
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdRow(
    String title,
    String subtitle,
    int value,
    Color color,
    ValueChanged<int> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: DesignTokens.textPrimary,
                    fontSize: DesignTokens.fontSizeBodySmall,
                    fontWeight: DesignTokens.fontWeightSemiBold,
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(DesignTokens.radius8),
              ),
              child: Text(
                '$value%',
                style: TextStyle(
                  color: color,
                  fontSize: DesignTokens.fontSizeCaption,
                  fontWeight: DesignTokens.fontWeightBold,
                  fontFamily: DesignTokens.fontFamilyPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.spacing8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: color.withValues(alpha: 0.2),
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.1),
          ),
          child: Slider(
            value: value.toDouble(),
            min: 50,
            max: 95,
            divisions: 9,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
      ],
    );
  }

  Widget _buildPinOverrideSection() {
    return NoraCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DesignTokens.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(DesignTokens.radius10),
            ),
            child: Icon(Icons.lock_rounded,
                color: DesignTokens.accent, size: 20),
          ),
          const SizedBox(width: DesignTokens.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Require PIN to Override',
                  style: TextStyle(
                    color: DesignTokens.textPrimary,
                    fontSize: DesignTokens.fontSizeBodySmall,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  ),
                ),
                Text(
                  'Need accountability PIN to bypass at 100%',
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
            value: _requirePin,
            onChanged: (value) => setState(() => _requirePin = value),
            activeThumbColor: DesignTokens.accent,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(HardCapProvider cap) {
    return NoraButton(
      label: cap.isActive ? 'Update Hard Cap' : 'Set Hard Cap',
      icon: Icons.check_rounded,
      onPressed: cap.setupInProgress
          ? null
          : () async {
              final success = await cap.setupCap(
                capMinutes: _totalMinutes,
                softWarningPercent: _softWarningPercent,
                hardWarningPercent: _hardWarningPercent,
                requirePinToOverride: _requirePin,
              );
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Hard cap updated'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              }
            },
    );
  }

  Widget _buildDeactivateButton(HardCapProvider cap) {
    return NoraButton(
      label: 'Remove Hard Cap',
      icon: Icons.close_rounded,
      outlined: true,
      onPressed: () async {
        final success = await cap.deactivateCap();
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hard cap removed'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      },
    );
  }
}
