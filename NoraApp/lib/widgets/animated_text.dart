import 'package:flutter/material.dart';

/// Animated text widget — Flutter equivalent of the React AnimatedText component.
/// Animates text letter-by-letter or word-by-word with staggered timing.
class AnimatedText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final AnimatedTextType animationType;
  final Duration duration;
  final Duration delay;
  final Duration staggerDelay;
  final double initialY;
  final double initialOpacity;
  final double animateY;
  final double animateOpacity;
  final TextAlign? textAlign;

  const AnimatedText({
    super.key,
    required this.text,
    this.style,
    this.animationType = AnimatedTextType.letters,
    this.duration = const Duration(milliseconds: 600),
    this.delay = Duration.zero,
    this.staggerDelay = const Duration(milliseconds: 50),
    this.initialY = 10,
    this.initialOpacity = 0,
    this.animateY = 0,
    this.animateOpacity = 1,
    this.textAlign,
  });

  @override
  State<AnimatedText> createState() => _AnimatedTextState();
}

enum AnimatedTextType { letters, words }

class _AnimatedTextState extends State<AnimatedText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;
  late List<String> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.animationType == AnimatedTextType.letters
        ? widget.text.split('')
        : widget.text.split(' ');

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration + (widget.staggerDelay * (_items.length - 1)),
    );

    _fadeAnimations = [];
    _slideAnimations = [];

    for (int i = 0; i < _items.length; i++) {
      final start = i * (widget.staggerDelay.inMilliseconds /
          _controller.duration!.inMilliseconds);
      final end = (start + widget.duration.inMilliseconds /
              _controller.duration!.inMilliseconds)
          .clamp(0.0, 1.0);

      _fadeAnimations.add(
        Tween<double>(
          begin: widget.initialOpacity,
          end: widget.animateOpacity,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        ),
      );

      _slideAnimations.add(
        Tween<Offset>(
          begin: Offset(0, widget.initialY),
          end: Offset(0, widget.animateY),
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        ),
      );
    }

    // Start after delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Wrap(
          alignment: WrapAlignment.center,
          children: List.generate(_items.length, (index) {
            return SlideTransition(
              position: _slideAnimations[index],
              child: FadeTransition(
                opacity: _fadeAnimations[index],
                child: Text(
                  widget.animationType == AnimatedTextType.letters
                      ? _items[index]
                      : '${_items[index]} ',
                  style: widget.style,
                  textAlign: widget.textAlign,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
