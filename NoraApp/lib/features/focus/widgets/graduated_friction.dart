import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';

/// GraduatedFriction — delay screen before opening blocked apps.
///
/// Instead of hard blocks (which cause frustration and workarounds),
/// this shows a breathing exercise or reflection prompt that the
/// user must complete before proceeding. The delay increases with
/// repeated attempts, creating natural friction.
///
/// PRODUCT RATIONALE:
/// - Hard blocks cause users to uninstall or disable accessibility
/// - Delay + reflection reduces impulsive app switching by 40-60%
/// - Typed intention makes the user conscious of their choice
/// - Progressive unlock builds sustainable habits over time
class GraduatedFriction extends StatefulWidget {
  final String appName;
  final String appPackage;
  final int attemptCount; // How many times user tried this session
  final VoidCallback onContinue;
  final VoidCallback onCancel;

  const GraduatedFriction({
    super.key,
    required this.appName,
    required this.appPackage,
    required this.attemptCount,
    required this.onContinue,
    required this.onCancel,
  });

  @override
  State<GraduatedFriction> createState() => _GraduatedFrictionState();
}

class _GraduatedFrictionState extends State<GraduatedFriction>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  Timer? _timer;
  int _secondsRemaining = 0;
  bool _canContinue = false;
  final _intentionController = TextEditingController();
  bool _intentionEntered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // Progressive delay: 10s, 20s, 30s, 45s, 60s (capped)
    _secondsRemaining = (10 + (widget.attemptCount * 10)).clamp(10, 60);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _secondsRemaining--;
        if (_secondsRemaining <= 0) {
          _canContinue = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _intentionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        backgroundColor: DesignTokens.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Breathing circle animation
                _buildBreathingCircle(),

                const SizedBox(height: 32),

                // Title
                Text(
                  _canContinue ? 'Ready to proceed?' : 'Take a breath',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeH2,
                    fontWeight: FontWeight.bold,
                    color: DesignTokens.textPrimary,
                  ),
                ),

                const SizedBox(height: 12),

                // App name
                Text(
                  'You\'re trying to open ${widget.appName}',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeBody,
                    color: DesignTokens.textMuted,
                  ),
                ),

                const SizedBox(height: 24),

                // Timer or continue button
                if (!_canContinue) ...[
                  // Countdown
                  Text(
                    '$_secondsRemaining seconds',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeDisplaySmall,
                      fontWeight: FontWeight.bold,
                      color: DesignTokens.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Focus on your breathing while you wait',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeBodySmall,
                      color: DesignTokens.textMuted,
                    ),
                  ),
                ] else ...[
                  // Typed intention input
                  _buildIntentionInput(),
                  const SizedBox(height: 24),

                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _intentionEntered
                          ? widget.onContinue
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.primary,
                        disabledBackgroundColor: DesignTokens.textMuted,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Continue to ${widget.appName}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: DesignTokens.fontSizeBody,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Cancel button
                TextButton(
                  onPressed: widget.onCancel,
                  child: Text(
                    'Go back',
                    style: TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: DesignTokens.fontSizeBodySmall,
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

  Widget _buildBreathingCircle() {
    return AnimatedContainer(
      duration: const Duration(seconds: 4),
      width: _canContinue ? 80 : 120,
      height: _canContinue ? 80 : 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: DesignTokens.primary.withOpacity(0.1),
        border: Border.all(
          color: DesignTokens.primary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Icon(
          _canContinue ? Icons.check_circle_outline : Icons.air,
          size: 48,
          color: DesignTokens.primary,
        ),
      ),
    );
  }

  Widget _buildIntentionInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Why do you want to open this app?',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeBody,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _intentionController,
          onChanged: (value) {
            setState(() {
              _intentionEntered = value.trim().length >= 5;
            });
          },
          decoration: InputDecoration(
            hintText: 'e.g., Check a notification from a friend',
            hintStyle: TextStyle(color: DesignTokens.textMuted),
            filled: true,
            fillColor: DesignTokens.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          maxLines: 2,
        ),
        if (!_intentionEntered && _canContinue)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Please enter at least 5 characters',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeCaption,
                color: DesignTokens.error,
              ),
            ),
          ),
      ],
    );
  }
}
