import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../providers/hard_cap_provider.dart';
import '../../../providers/accountability_provider.dart';
import '../../../widgets/nora_components.dart';

/// HardCapOverlay — Progressive friction overlay for daily screen time limits.
///
/// Shows different UI based on friction level:
/// - Soft: subtle banner notification
/// - Hard: modal with reflection prompt
/// - Blocked: full-screen overlay with PIN override
class HardCapOverlay extends StatefulWidget {
  final Widget child;

  const HardCapOverlay({super.key, required this.child});

  @override
  State<HardCapOverlay> createState() => _HardCapOverlayState();
}

class _HardCapOverlayState extends State<HardCapOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HardCapProvider>(
      builder: (context, cap, _) {
        final level = cap.frictionLevel;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (level != FrictionLevel.none && !_controller.isAnimating) {
            _controller.forward();
          } else if (level == FrictionLevel.none && !_controller.isAnimating) {
            _controller.reverse();
          }
        });

        return Stack(
          children: [
            widget.child,
            if (level != FrictionLevel.none)
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildOverlay(level, cap),
              ),
          ],
        );
      },
    );
  }

  Widget _buildOverlay(FrictionLevel level, HardCapProvider cap) {
    switch (level) {
      case FrictionLevel.soft:
        return _buildSoftWarning(cap);
      case FrictionLevel.hard:
        return _buildHardWarning(cap);
      case FrictionLevel.blocked:
        return _buildBlockedOverlay(cap);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSoftWarning(HardCapProvider cap) {
    if (cap.softWarningShown) return const SizedBox.shrink();

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () => cap.markSoftWarningShown(),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DesignTokens.accent.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
              boxShadow: [
                BoxShadow(
                  color: DesignTokens.accent.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Screen time check-in',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: DesignTokens.fontSizeBodySmall,
                          fontWeight: DesignTokens.fontWeightSemiBold,
                          fontFamily: DesignTokens.fontFamilyPrimary,
                        ),
                      ),
                      Text(
                        'You\'ve spent ${cap.todayUsageMinutes} of ${cap.capMinutes} minutes on screens today',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: DesignTokens.fontSizeCaption,
                          fontFamily: DesignTokens.fontFamilyPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHardWarning(HardCapProvider cap) {
    if (cap.hardWarningShown) return const SizedBox.shrink();

    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: NoraCard(
            backgroundColor: DesignTokens.surface,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DesignTokens.accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.hourglass_bottom_rounded,
                    color: DesignTokens.accent,
                    size: 48,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacing20),
                Text(
                  'Time for a break?',
                  style: TextStyle(
                    color: DesignTokens.textPrimary,
                    fontSize: DesignTokens.fontSizeH2,
                    fontWeight: DesignTokens.fontWeightBold,
                    fontFamily: DesignTokens.fontFamilyDisplay,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacing8),
                Text(
                  'You\'ve been on screens for a while. A short break might feel good.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: DesignTokens.fontSizeBody,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacing8),
                Text(
                  '${cap.todayUsageMinutes} of ${cap.capMinutes} minutes used',
                  style: TextStyle(
                    color: DesignTokens.accent,
                    fontSize: DesignTokens.fontSizeBody,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacing4),
                Text(
                  'How are you feeling about your screen time today?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: DesignTokens.fontSizeCaption,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacing24),
                NoraButton(
                  label: 'Continue Mindfully',
                  icon: Icons.check_rounded,
                  onPressed: () => cap.markHardWarningShown(),
                ),
                const SizedBox(height: DesignTokens.spacing8),
                TextButton(
                  onPressed: () => cap.markHardWarningShown(),
                  child: Text(
                    'Dismiss',
                    style: TextStyle(
                      color: DesignTokens.textMuted,
                      fontFamily: DesignTokens.fontFamilyPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlockedOverlay(HardCapProvider cap) {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: NoraCard(
            backgroundColor: DesignTokens.surface,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DesignTokens.accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.nightlight_round,
                    color: DesignTokens.accent,
                    size: 48,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacing20),
                Text(
                  'Time for today',
                  style: TextStyle(
                    color: DesignTokens.textPrimary,
                    fontSize: DesignTokens.fontSizeH2,
                    fontWeight: DesignTokens.fontWeightBold,
                    fontFamily: DesignTokens.fontFamilyDisplay,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacing8),
                Text(
                  'You\'ve spent ${cap.capMinutes} minutes on screens today. A good time to unwind!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: DesignTokens.fontSizeBody,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacing8),
                Text(
                  'Rest well and start fresh tomorrow!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: DesignTokens.fontSizeCaption,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacing24),
                if (cap.requirePinToOverride) ...[
                  Text(
                    'Enter your PIN to keep going',
                    style: TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: DesignTokens.fontSizeCaption,
                      fontFamily: DesignTokens.fontFamilyPrimary,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacing12),
                  _buildPinOverrideButton(cap),
                ] else ...[
                  NoraButton(
                    label: 'Got it',
                    icon: Icons.check_rounded,
                    onPressed: () => cap.markBlockedShown(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinOverrideButton(HardCapProvider cap) {
    final pinController = TextEditingController();

    return NoraCard(
      backgroundColor: DesignTokens.background,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            style: const TextStyle(
              fontSize: 18,
              letterSpacing: 6,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '• • • •',
              hintStyle: TextStyle(
                color: DesignTokens.textMuted.withValues(alpha: 0.5),
                letterSpacing: 6,
              ),
              filled: true,
              fillColor: DesignTokens.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.spacing12),
          NoraButton(
            label: 'Keep Going',
            icon: Icons.lock_open_rounded,
            onPressed: () async {
              final accountability = context.read<AccountabilityProvider>();
              final verified =
                  await accountability.verifyPin(pinController.text);
              if (verified) {
                cap.resetFrictionWarnings();
                cap.markBlockedShown();
              }
            },
          ),
        ],
      ),
    );
  }
}
