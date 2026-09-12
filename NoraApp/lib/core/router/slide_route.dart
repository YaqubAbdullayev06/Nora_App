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
}
