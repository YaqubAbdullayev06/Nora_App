import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/breathing_pattern.dart';

/// The core animated widget that guides the user through a breathing phase.
///
/// Shows the mascot SVG expanding/contracting, an expanding ring,
/// and the current phase instruction text.
class AnimatedBreathingGuide extends StatefulWidget {
  final String mascotAssetPath;
  final Color color;
  final BreathingPhase? phase;
  final double phaseProgress;
  final bool isActive;

  const AnimatedBreathingGuide({
    super.key,
    required this.mascotAssetPath,
    required this.color,
    this.phase,
    this.phaseProgress = 0.0,
    this.isActive = false,
  });

  @override
  State<AnimatedBreathingGuide> createState() => _AnimatedBreathingGuideState();
}

class _AnimatedBreathingGuideState extends State<AnimatedBreathingGuide>
    with TickerProviderStateMixin {
  late AnimationController _mascotController;
  late AnimationController _ringController;
  late Animation<double> _mascotScale;
  late Animation<double> _ringScale;
  late Animation<double> _ringOpacity;

  String _lastPhaseName = '';

  @override
  void initState() {
    super.initState();
    _mascotController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _ringController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _mascotScale = Tween<double>(begin: 1.15, end: 0.85).animate(
      CurvedAnimation(parent: _mascotController, curve: Curves.easeInOut),
    );
    _ringScale = Tween<double>(begin: 1.3, end: 0.7).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeOut),
    );
    _ringOpacity = Tween<double>(begin: 0.4, end: 0.0).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeOut),
    );

    if (widget.isActive) {
      _startAnimations();
    }
  }

  @override
  void didUpdateWidget(AnimatedBreathingGuide oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive && !oldWidget.isActive) {
      _startAnimations();
    } else if (!widget.isActive && oldWidget.isActive) {
      _stopAnimations();
    }

    // Restart animation when phase changes
    if (widget.phase != null &&
        widget.phase!.name != _lastPhaseName) {
      _lastPhaseName = widget.phase!.name;
      if (widget.isActive) {
        _restartForPhase();
      }
    }
  }

  void _startAnimations() {
    if (widget.phase == null) return;
    _lastPhaseName = widget.phase!.name;

    final isInhale = widget.phase!.name.toLowerCase().contains('inhale');
    final duration = Duration(milliseconds: isInhale ? 1200 : 1600);

    _mascotController.duration = duration;
    _ringController.duration = Duration(milliseconds: duration.inMilliseconds + 200);

    if (isInhale) {
      _mascotController.forward(from: 0);
      _ringController.forward(from: 0);
    } else {
      _mascotController.reverse(from: 1);
      _ringController.reverse(from: 1);
    }
  }

  void _stopAnimations() {
    _mascotController.stop();
    _ringController.stop();
  }

  void _restartForPhase() {
    _mascotController.stop();
    _ringController.stop();
    _startAnimations();
  }

  @override
  void dispose() {
    _mascotController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer animated ring
          AnimatedBuilder(
            listenable: _ringController,
            builder: (context, child) {
              return Transform.scale(
                scale: _ringScale.value,
                child: Opacity(
                  opacity: _ringOpacity.value,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.color,
                        width: 3,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // Middle pulsing ring
          AnimatedBuilder(
            listenable: _mascotController,
            builder: (context, child) {
              return Transform.scale(
                scale: _mascotScale.value * 0.95,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(alpha: 0.08),
                  ),
                ),
              );
            },
          ),
          // Inner glow
          AnimatedBuilder(
            listenable: _mascotController,
            builder: (context, child) {
              return Transform.scale(
                scale: _mascotScale.value * 0.85,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(alpha: 0.12),
                  ),
                ),
              );
            },
          ),
          // Mascot SVG
          AnimatedBuilder(
            listenable: _mascotController,
            builder: (context, child) {
              return Transform.scale(
                scale: _mascotScale.value,
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: SvgPicture.asset(
                    widget.mascotAssetPath,
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
          // Phase instruction text
          Positioned(
            bottom: 0,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                widget.phase?.instruction ?? '',
                key: ValueKey(widget.phase?.instruction),
                style: TextStyle(
                  color: widget.color,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A simplified AnimatedBuilder that rebuilds on animation changes.
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required super.listenable,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
