import 'package:flutter/services.dart';

/// HapticService — Centralized haptic feedback for NoraApp.
///
/// Provides consistent tactile feedback across all interactions:
/// - Task completion: medium impact (reward)
/// - Timer start/stop: heavy impact (milestone)
/// - Button press: light impact (acknowledgment)
/// - Selection change: selection click (subtle)
/// - Error/warning: error vibration (attention)
///
/// All haptics are no-ops on platforms that don't support them (web, desktop).
class HapticService {
  HapticService._();

  // ─── Task Events ───

  /// Task completed — satisfying "click" feel.
  static void taskCompleted() {
    HapticFeedback.mediumImpact();
  }

  /// Task unchecked — subtle reverse feedback.
  static void taskUnchecked() {
    HapticFeedback.lightImpact();
  }

  // ─── Timer Events ───

  /// Timer started — strong confirmation.
  static void timerStarted() {
    HapticFeedback.heavyImpact();
  }

  /// Timer paused — medium feedback.
  static void timerPaused() {
    HapticFeedback.mediumImpact();
  }

  /// Timer completed — celebratory double pulse.
  static void timerCompleted() async {
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.mediumImpact();
  }

  /// Pomodoro break started — gentle transition.
  static void breakStarted() {
    HapticFeedback.lightImpact();
  }

  // ─── Navigation Events ───

  /// Tab switched — subtle.
  static void tabSwitched() {
    HapticFeedback.selectionClick();
  }

  /// Bottom sheet opened — medium.
  static void sheetOpened() {
    HapticFeedback.mediumImpact();
  }

  /// Modal dismissed — light.
  static void modalDismissed() {
    HapticFeedback.lightImpact();
  }

  // ─── Interaction Events ───

  /// Button pressed — light acknowledgment.
  static void buttonPressed() {
    HapticFeedback.lightImpact();
  }

  /// Toggle changed — selection click.
  static void toggleChanged() {
    HapticFeedback.selectionClick();
  }

  /// Slider moved — very light.
  static void sliderMoved() {
    HapticFeedback.selectionClick();
  }

  // ─── Feedback Events ───

  /// Success action — medium impact.
  static void success() {
    HapticFeedback.mediumImpact();
  }

  /// Error or warning — attention getter.
  static void error() {
    HapticFeedback.heavyImpact();
  }

  /// Subtle notification — light.
  static void notification() {
    HapticFeedback.lightImpact();
  }

  // ─── Breathing / Wellness Events ───

  /// Breathing cycle complete — gentle.
  static void breathingCycle() {
    HapticFeedback.selectionClick();
  }

  /// Focus session milestone — medium.
  static void focusMilestone() {
    HapticFeedback.mediumImpact();
  }

  // ─── Custom ───

  /// Custom pattern: pulse [count] times with [interval] between each.
  static Future<void> pulse(int count, {Duration interval = const Duration(milliseconds: 100)}) async {
    for (int i = 0; i < count; i++) {
      HapticFeedback.mediumImpact();
      if (i < count - 1) {
        await Future.delayed(interval);
      }
    }
  }
}
