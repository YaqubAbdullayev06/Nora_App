import 'package:flutter/material.dart';

/// A custom [PageRouteBuilder] that provides smooth fade transitions
/// between screens.
///
/// Usage:
/// ```dart
/// Navigator.of(context).push(FadePageRoute(
///   pageBuilder: (context, animation, secondaryAnimation) => const MyScreen(),
/// ));
/// ```
class FadePageRoute<T> extends PageRouteBuilder<T> {
  FadePageRoute({
    required super.pageBuilder,
    super.settings,
    super.fullscreenDialog,
    super.transitionDuration = const Duration(milliseconds: 350),
    super.reverseTransitionDuration = const Duration(milliseconds: 300),
  }) : super(opaque: true);

  @override
  Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)
      get transitionsBuilder => (context, animation, secondaryAnimation, child) {
            final fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ));

            return FadeTransition(
              opacity: fadeAnimation,
              child: child,
            );
          };
}

/// A custom [PageRouteBuilder] that slides the new screen up from the bottom.
///
/// Usage:
/// ```dart
/// Navigator.of(context).push(SlideUpRoute(
///   pageBuilder: (context, animation, secondaryAnimation) => const MyScreen(),
/// ));
/// ```
class SlideUpRoute<T> extends PageRouteBuilder<T> {
  SlideUpRoute({
    required super.pageBuilder,
    super.settings,
    super.fullscreenDialog,
    super.transitionDuration = const Duration(milliseconds: 400),
    super.reverseTransitionDuration = const Duration(milliseconds: 350),
  }) : super(opaque: true);

  @override
  Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)
      get transitionsBuilder => (context, animation, secondaryAnimation, child) {
            final slideAnimation = Tween<Offset>(
              begin: const Offset(0, 0.12),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ));

            final fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
            ));

            return SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          };
}

/// A custom [PageRouteBuilder] that slides the new screen in from the right.
///
/// Usage:
/// ```dart
/// Navigator.of(context).push(SlideRightRoute(
///   pageBuilder: (context, animation, secondaryAnimation) => const MyScreen(),
/// ));
/// ```
class SlideRightRoute<T> extends PageRouteBuilder<T> {
  SlideRightRoute({
    required super.pageBuilder,
    super.settings,
    super.fullscreenDialog,
    super.transitionDuration = const Duration(milliseconds: 350),
    super.reverseTransitionDuration = const Duration(milliseconds: 300),
  }) : super(opaque: true);

  @override
  Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)
      get transitionsBuilder => (context, animation, secondaryAnimation, child) {
            final slideAnimation = Tween<Offset>(
              begin: const Offset(0.3, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ));

            final fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
            ));

            return SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          };
}

/// Convenience extensions for [BuildContext] to make fade navigation cleaner.
extension FadeNavigation on BuildContext {
  /// Push a new screen with a fade animation.
  Future<T?> pushFade<T>(Widget page) {
    return Navigator.of(this).push<T>(
      FadePageRoute<T>(
        pageBuilder: (_, __, ___) => page,
      ),
    );
  }

  /// Replace the current screen with a fade animation.
  Future<T?> pushReplacementFade<T>(Widget page) {
    return Navigator.of(this).pushReplacement<T, void>(
      FadePageRoute<T>(
        pageBuilder: (_, __, ___) => page,
      ),
    );
  }

  /// Push and remove all previous routes, with a fade animation.
  Future<T?> pushAndRemoveAllFade<T>(Widget page) {
    return Navigator.of(this).pushAndRemoveUntil<T>(
      FadePageRoute<T>(
        pageBuilder: (_, __, ___) => page,
      ),
      (_) => false,
    );
  }

  /// Push a new screen with a slide-up animation.
  Future<T?> pushSlideUp<T>(Widget page) {
    return Navigator.of(this).push<T>(
      SlideUpRoute<T>(
        pageBuilder: (_, __, ___) => page,
      ),
    );
  }

  /// Push a new screen with a slide-from-right animation.
  Future<T?> pushSlideRight<T>(Widget page) {
    return Navigator.of(this).push<T>(
      SlideRightRoute<T>(
        pageBuilder: (_, __, ___) => page,
      ),
    );
  }
}
