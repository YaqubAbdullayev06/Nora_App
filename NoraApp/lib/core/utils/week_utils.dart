import '../../models/focus.dart';

/// Monday-start week boundaries and weekly bucketing.
///
/// M1: every week helper here works on LOCAL MIDNIGHT values.
/// `now.subtract(Duration(days: now.weekday - 1))` — the formula this file
/// replaces — keeps the *current time-of-day*, so bucketing a date-only
/// session against it shifted every weekday after Monday one slot to the left
/// (Tuesday's minutes rendered under Monday, Sunday's under Saturday), and the
/// derived review key drifted by the time of day.

/// Local midnight of the Monday that starts the week containing [day].
///
/// Calendar arithmetic instead of `Duration.subtract` so a DST change inside
/// the week cannot move the boundary off midnight.
DateTime startOfWeek(DateTime day) => DateTime(day.year, day.month, day.day - (day.weekday - 1));

/// Local midnight of the Sunday that starts the last day of the week
/// containing [day] (i.e. [startOfWeek] + 6 days).
DateTime endOfWeek(DateTime day) {
  final monday = startOfWeek(day);
  return DateTime(monday.year, monday.month, monday.day + 6);
}

/// Completed [sessions] bucketed into the 7 days of the week containing [now],
/// index 0 = Monday … index 6 = Sunday. Each bucket holds session minutes.
///
/// Incomplete sessions and sessions outside the week are ignored.
List<int> weeklyMinutesByDay(List<FocusSession> sessions, DateTime now) {
  final weekStart = startOfWeek(now);
  final nextWeekStart =
      DateTime(weekStart.year, weekStart.month, weekStart.day + 7);

  final minutes = List<int>.filled(7, 0);
  for (final session in sessions) {
    if (!session.completed) continue;
    final day = DateTime(
      session.startTime.year,
      session.startTime.month,
      session.startTime.day,
    );
    if (day.isBefore(weekStart) || !day.isBefore(nextWeekStart)) continue;
    // `weekday` is calendar-based, so it stays correct across DST shifts
    // (unlike `difference(inDays)`, which counts 24h units).
    minutes[day.weekday - 1] += session.durationMinutes;
  }
  return minutes;
}
