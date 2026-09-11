import 'package:flutter/material.dart';

/// Bouncing dots loader — Flutter equivalent of the React LoaderOne.
/// Three animated dots that bounce horizontally with staggered timing.
class LoaderOne extends StatefulWidget {
  final Color? color;
  final double dotSize;
  final double spacing;

  const LoaderOne({
    super.key,
    this.color,
    this.dotSize = 12.0,
    this.spacing = 4.0,
  });

  @override
  State<LoaderOne> createState() => _LoaderOneState();
}

class _LoaderOneState extends State<LoaderOne>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _positionAnimations;
  late List<Animation<double>> _opacityAnimations;
  late List<Animation<double>> _scaleAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _positionAnimations = [];
    _opacityAnimations = [];
    _scaleAnimations = [];

    for (int i = 0; i < 3; i++) {
      final delay = i * 0.2;

      _positionAnimations.add(
        Tween<double>(begin: 0, end: 10).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(
              delay,
              delay + 0.5,
              curve: Curves.easeInOut,
            ),
          ),
        )..addStatusListener((status) {
            if (status == AnimationStatus.completed && i == 2) {
              _controller.reverse();
            }
            if (status == AnimationStatus.dismissed && i == 2) {
              _controller.forward();
            }
          }),
      );

      _opacityAnimations.add(
        Tween<double>(begin: 0.5, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(
              delay,
              delay + 0.5,
              curve: Curves.easeInOut,
            ),
          ),
        ),
      );

      _scaleAnimations.add(
        Tween<double>(begin: 1.0, end: 1.2).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(
              delay,
              delay + 0.5,
              curve: Curves.easeInOut,
            ),
          ),
        ),
      );
    }

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = widget.color ?? Colors.blue;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return Padding(
              padding: EdgeInsets.only(right: i < 2 ? widget.spacing : 0),
              child: Transform.translate(
                offset: Offset(_positionAnimations[i].value, 0),
                child: Transform.scale(
                  scale: _scaleAnimations[i].value,
                  child: Opacity(
                    opacity: _opacityAnimations[i].value,
                    child: Container(
                      width: widget.dotSize,
                      height: widget.dotSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotColor,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
