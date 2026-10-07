import 'package:flutter_test/flutter_test.dart';
import 'package:nora_app/providers/app_provider.dart';

/// C2 regression: Weekly Review state was wiped/rebuilt in a loop.
///
/// `getOrCreateCurrentWeeklyReview()` is called from `build()` in
/// `WeeklyReviewScreen`, so it must be a pure, idempotent read:
///  * its memo key (`weekStart`) has to be stable across calls — it used to be
///    `now.subtract(Duration(days: now.weekday - 1))`, which carries the
///    current time-of-day, so the equality check never matched and the review
///    was re-created on every build;
///  * it must never call `notifyListeners()` — notifying during build throws
///    "setState() called during build" in debug and re-dirties the root scope
///    (an endless rebuild loop) in release.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('C2 weekly review rebuild loop', () {
    test('weekStart is local midnight of this week Monday', () {
      final provider = AppProvider();
      final first = provider.getOrCreateCurrentWeeklyReview();

      expect(first.weekStart.weekday, DateTime.monday,
          reason: 'week must start on Monday');
      expect(first.weekStart.hour, 0);
      expect(first.weekStart.minute, 0);
      expect(first.weekStart.second, 0);

      final second = provider.getOrCreateCurrentWeeklyReview();
      expect(identical(first, second), isTrue,
          reason: 'memo must hit on every call — a fresh instance means the '
              'review was silently wiped (the C2 bug)');
      expect(provider.currentWeeklyReview, same(first));
    });

    test('getOrCreate never notifies listeners, mutators still do', () {
      final provider = AppProvider();
      var notified = 0;
      provider.addListener(() => notified++);

      provider.getOrCreateCurrentWeeklyReview();
      provider.getOrCreateCurrentWeeklyReview();
      expect(notified, 0,
          reason: 'called from build(); notifying there throws in debug and '
              'causes a rebuild loop in release');

      provider.addWeeklyReflection('What went well?', 'Something.');
      expect(notified, 1,
          reason: 'real mutations must still notify so the UI updates');
    });

    test('review id is derived from the truncated week start', () {
      final provider = AppProvider();
      final review = provider.getOrCreateCurrentWeeklyReview();
      expect(review.id, 'review_${review.weekStart.millisecondsSinceEpoch}');
      expect(
        review.weekEnd.difference(review.weekStart).inDays,
        6,
        reason: 'week spans Monday through Sunday',
      );
    });
  });
}
