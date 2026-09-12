import 'package:flutter/material.dart';

/// A wrapper widget that provides a smooth fade + slide-up entrance
/// animation for any screen content.
///
/// Usage:
/// ```dart
/// class MyScreen extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return AnimatedScreen(
///       child: Column(
///         children: [ /* your content */ ],
///       ),
///     );
///   }
/// }
/// ```
class AnimatedScreen extends StatefulWidget {
  /// The child widget to animate in.
  final Widget child;

  /// Duration of the entrance animation.
  final Duration duration;

  /// Delay before the animation starts.
  final Duration delay;

  /// Initial slide offset (default: slides up from 0.08).
  final Offset slideOffset;

  /// Whether the animation is enabled (set to false for no animation).
  final bool enabled;

  const AnimatedScreen({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
    this.slideOffset = const Offset(0, 0.08),
    this.enabled = true,
  });

  @override
  State<AnimatedScreen> createState() => _AnimatedScreenState();
}

class _AnimatedScreenState extends State<AnimatedScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    if (widget.enabled) {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled && widget.enabled) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// A wrapper that provides staggered children animations.
///
/// Animates children one by one with a configurable stagger delay.
///
/// Usage:
/// ```dart
/// AnimatedStaggerList(
///   children: [
///     Text('First'),
///     Text('Second'),
///     Text('Third'),
///   ],
/// )
/// ```
class AnimatedStaggerList extends StatefulWidget {
  /// The list of child widgets to animate in sequentially.
  final List<Widget> children;

  /// Duration of each child's animation.
  final Duration duration;

  /// Delay between each child's animation start.
  final Duration staggerDelay;

  /// Initial delay before the first child animates.
  final Duration initialDelay;

  /// Slide offset for each child.
  final Offset slideOffset;

  /// Axis direction for the list.
  final Axis scrollDirection;

  /// Whether to wrap in a SingleChildScrollView.
  final bool scrollable;

  const AnimatedStaggerList({
    super.key,
    required this.children,
    this.duration = const Duration(milliseconds: 400),
    this.staggerDelay = const Duration(milliseconds: 80),
    this.initialDelay = Duration.zero,
    this.slideOffset = const Offset(0, 0.06),
    this.scrollDirection = Axis.vertical,
    this.scrollable = false,
  });

  @override
  State<AnimatedStaggerList> createState() => _AnimatedStaggerListState();
}

class _AnimatedStaggerListState extends State<AnimatedStaggerList> {
  @override
  Widget build(BuildContext context) {
    final items = List.generate(widget.children.length, (index) {
      return _StaggeredItem(
        index: index,
        duration: widget.duration,
        delay: widget.initialDelay + widget.staggerDelay * index,
        slideOffset: widget.slideOffset,
        child: widget.children[index],
      );
    });

    Widget list;
    switch (widget.scrollDirection) {
      case Axis.horizontal:
        list = Row(children: items);
        break;
      case Axis.vertical:
        list = Column(mainAxisSize: MainAxisSize.min, children: items);
        break;
    }

    if (widget.scrollable) {
      return SingleChildScrollView(
        scrollDirection: widget.scrollDirection,
        child: list,
      );
    }

    return list;
  }
}

class _StaggeredItem extends StatefulWidget {
  final int index;
  final Duration duration;
  final Duration delay;
  final Offset slideOffset;
  final Widget child;

  const _StaggeredItem({
    required this.index,
    required this.duration,
    required this.delay,
    required this.slideOffset,
    required this.child,
  });

  @override
  State<_StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<_StaggeredItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
