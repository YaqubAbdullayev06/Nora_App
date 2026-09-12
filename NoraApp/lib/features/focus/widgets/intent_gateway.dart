import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/design_tokens.dart';

/// IntentGateway — Smart friction screen when opening blocked apps.
///
/// Instead of hard blocks, shows a 5-second mandatory pause + intention prompt.
/// - If user types a valid intention (10+ chars): grants 3-minute temp pass
/// - If left blank or impulse: redirects back to active task
///
/// DESIGN:
/// - Dark glassmorphism background with breathing animation
/// - Pulsing radial ring during countdown
/// - Clean typography, minimal cognitive load
/// - Haptic feedback on key actions
class IntentGateway extends StatefulWidget {
  final String appName;
  final String appPackage;
  final int attemptCount;
  final VoidCallback onContinue;
  final VoidCallback onCancel;
  final VoidCallback? onTempPass; // 3-min pass granted

  const IntentGateway({
    super.key,
    required this.appName,
    required this.appPackage,
    required this.attemptCount,
    required this.onContinue,
    required this.onCancel,
    this.onTempPass,
  });

  @override
  State<IntentGateway> createState() => _IntentGatewayState();
}

class _IntentGatewayState extends State<IntentGateway>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _countdownController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  int _secondsRemaining = 5;
  bool _canProceed = false;
  bool _showInput = false;
  final _intentionController = TextEditingController();
  bool _intentionValid = false;
  bool _grantingPass = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startCountdown();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    _countdownController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    _fadeController.forward();
  }

  void _startCountdown() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _secondsRemaining--;
        if (_secondsRemaining <= 0) {
          _canProceed = true;
          _showInput = true;
          timer.cancel();
          HapticFeedback.mediumImpact();
        }
      });
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _countdownController.dispose();
    _intentionController.dispose();
    super.dispose();
  }

  void _handleGrantPass() {
    setState(() => _grantingPass = true);
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (widget.onTempPass != null) {
        widget.onTempPass!();
      } else {
        widget.onContinue();
      }
    });
  }

  void _handleGoBack() {
    HapticFeedback.lightImpact();
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                DesignTokens.background,
                DesignTokens.background.withOpacity(0.95),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  // Breathing circle with countdown
                  _buildPulsingCircle(),
                  const SizedBox(height: 32),
                  // Title
                  _buildTitle(),
                  const SizedBox(height: 12),
                  // Subtitle
                  _buildSubtitle(),
                  const Spacer(flex: 1),
                  // Input or buttons
                  if (_showInput) _buildIntentionSection(),
                  if (!_showInput) _buildCountdownText(),
                  const SizedBox(height: 16),
                  // Go back (always visible)
                  _buildGoBackButton(),
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPulsingCircle() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final size = _canProceed ? 100.0 : 120.0 + (_pulseAnimation.value * 20);
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (_canProceed ? DesignTokens.success : DesignTokens.primary)
                    .withOpacity(0.2 + (_pulseAnimation.value * 0.1)),
                blurRadius: 40,
                spreadRadius: 8,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (_canProceed ? DesignTokens.success : DesignTokens.primary)
                        .withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
              // Inner circle
              Container(
                width: size * 0.7,
                height: size * 0.7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (_canProceed ? DesignTokens.success : DesignTokens.primary)
                      .withOpacity(0.1),
                ),
                child: Icon(
                  _canProceed ? Icons.psychology : Icons.shield,
                  size: 36,
                  color: _canProceed ? DesignTokens.success : DesignTokens.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTitle() {
    return Text(
      _canProceed ? 'What\'s your intention?' : 'Pause and reflect',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: DesignTokens.textPrimary,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      _canProceed
          ? 'Type your reason to open ${widget.appName}'
          : 'You\'re about to open ${widget.appName}',
      style: TextStyle(
        fontSize: 15,
        color: DesignTokens.textMuted,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildCountdownText() {
    return Column(
      children: [
        Text(
          '$_secondsRemaining',
          style: TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.bold,
            color: DesignTokens.primary,
            height: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'seconds before you can proceed',
          style: TextStyle(
            fontSize: 13,
            color: DesignTokens.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildIntentionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Intention input
        Container(
          decoration: BoxDecoration(
            color: DesignTokens.surface.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _intentionValid
                  ? DesignTokens.success.withOpacity(0.5)
                  : DesignTokens.border,
              width: 1,
            ),
          ),
          child: TextField(
            controller: _intentionController,
            autofocus: true,
            onChanged: (value) {
              setState(() {
                _intentionValid = value.trim().length >= 10;
              });
            },
            onSubmitted: (_) {
              if (_intentionValid) _handleGrantPass();
            },
            style: TextStyle(
              color: DesignTokens.textPrimary,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: 'e.g., Check work message from Slack...',
              hintStyle: TextStyle(color: DesignTokens.textMuted.withOpacity(0.6)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            maxLines: 2,
          ),
        ),

        const SizedBox(height: 12),

        // Character count hint
        Row(
          children: [
            Icon(
              _intentionValid ? Icons.check_circle : Icons.info_outline,
              size: 14,
              color: _intentionValid ? DesignTokens.success : DesignTokens.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              _intentionValid
                  ? 'Good reason — tap below to proceed'
                  : 'At least 10 characters to confirm',
              style: TextStyle(
                fontSize: 12,
                color: _intentionValid ? DesignTokens.success : DesignTokens.textMuted,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Grant pass button
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _intentionValid && !_grantingPass ? _handleGrantPass : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.success,
              disabledBackgroundColor: DesignTokens.surface,
              foregroundColor: Colors.white,
              disabledForegroundColor: DesignTokens.textMuted,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: _grantingPass
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timer, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Open for 3 minutes',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoBackButton() {
    return TextButton(
      onPressed: _handleGoBack,
      child: Text(
        'Go back to my task',
        style: TextStyle(
          color: DesignTokens.primary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
