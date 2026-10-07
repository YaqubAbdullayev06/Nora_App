import 'package:flutter_test/flutter_test.dart';
import 'package:nora_app/core/utils/week_utils.dart';
import 'package:nora_app/models/focus.dart';

FocusSession session(DateTime start,
        {int minutes = 30, bool completed = true}) =>
    FocusSession(
      id: 's_${start.microsecondsSinceEpoch}',
      startTime: start,
      endTime: start.add(Duration(minutes: minutes)),
      durationMinutes: minutes,
      pointsEarned: minutes,
      completed: completed,
    );

void main() {
  group('startOfWeek / endOfWeek', () {
    test('lands on local midnight of Monday regardless of time of day', () {
      // 2026-09-23 is a Wednesday; input carries a time-of-day.
      final s = startOfWeek(DateTime(2026, 9, 23, 14, 37, 12));
      expect(s, DateTime(2026, 9, 21));
      expect(s.weekday, DateTime.monday);
      expect(s.hour, 0);
      expect(s.minute, 0);

      // A Monday input is itself (truncated to midnight).
      expect(startOfWeek(DateTime(2026, 9, 21, 23, 59)), DateTime(2026, 9, 21));
      // Sunday belongs to the week that started the previous Monday.
      expect(startOfWeek(DateTime(2026, 9, 27, 8)), DateTime(2026, 9, 21));
    });

    test('crosses month and year boundaries', () {
      // 2027-01-01 is a Friday → Monday 2026-12-28.
      expect(startOfWeek(DateTime(2027, 1, 1, 10)), DateTime(2026, 12, 28));
      // Negative day-of-month arithmetic must normalise.
      expect(startOfWeek(DateTime(2027, 1, 3, 6)), DateTime(2026, 12, 28));
    });

    test('endOfWeek is the Sunday (6 days) of the same week', () {
      final now = DateTime(2026, 9, 23, 14, 37);
      expect(endOfWeek(now), DateTime(2026, 9, 27));
      expect(endOfWeek(now).weekday, DateTime.sunday);
      expect(endOfWeek(now).difference(startOfWeek(now)).inDays, 6);
    });
  });

  group('weeklyMinutesByDay (M1 off-by-one regression)', () {
    // Wednesday 2026-09-23, mid-afternoon — the condition under which the old
    // `now.subtract(Duration(days: now.weekday - 1))` boundary kept a
    // time-of-day and shifted every day after Monday one slot to the left.
    final now = DateTime(2026, 9, 23, 14, 37, 12);

    test('bucketing is exact Monday..Sunday when now carries a time of day', () {
      final sessions = [
        session(DateTime(2026, 9, 21, 8, 0), minutes: 10), // Mon
        session(DateTime(2026, 9, 22, 9, 30), minutes: 20), // Tue
        session(DateTime(2026, 9, 23, 14, 0), minutes: 30), // Wed
        session(DateTime(2026, 9, 24, 23, 59), minutes: 40), // Thu
        session(DateTime(2026, 9, 25, 0, 0), minutes: 50), // Fri
        session(DateTime(2026, 9, 26, 12, 0), minutes: 60), // Sat
        session(DateTime(2026, 9, 27, 18, 0), minutes: 70), // Sun
        // Outside the week:
        session(DateTime(2026, 9, 20, 23, 0), minutes: 80), // last Sun
        session(DateTime(2026, 9, 28, 7, 0), minutes: 90), // next Mon
        // Not completed:
        session(DateTime(2026, 9, 22, 10, 0), minutes: 100, completed: false),
      ];

      expect(weeklyMinutesByDay(sessions, now), [10, 20, 30, 40, 50, 60, 70],
          reason: 'index 0 = Monday … index 6 = Sunday, no day shifted');
    });

    test('aggregates multiple sessions into the same day', () {
      final sessions = [
        session(DateTime(2026, 9, 27, 6, 0), minutes: 15), // Sun
        session(DateTime(2026, 9, 27, 21, 0), minutes: 25), // Sun
        session(DateTime(2026, 9, 22, 6, 0), minutes: 5), // Tue
      ];
      final buckets = weeklyMinutesByDay(sessions, now);
      expect(buckets, [0, 5, 0, 0, 0, 0, 40]);
      expect(buckets.reduce((a, b) => a + b), 45);
    });

    test('returns 7 buckets for an empty week', () {
      expect(weeklyMinutesByDay([], now), [0, 0, 0, 0, 0, 0, 0]);
    });

    test('sessions one week apart never bleed into the current week', () {
      final sessions = [
        session(DateTime(2026, 9, 14, 12), minutes: 45), // previous Monday
        session(DateTime(2026, 10, 5, 12), minutes: 65), // two weeks ahead
      ];
      expect(weeklyMinutesByDay(sessions, now), [0, 0, 0, 0, 0, 0, 0]);
    });
  });
}
