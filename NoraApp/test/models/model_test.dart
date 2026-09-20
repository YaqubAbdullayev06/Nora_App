import 'package:flutter_test/flutter_test.dart';
import 'package:nora_app/core/enums/age_group.dart';
import 'package:nora_app/models/user.dart';
import 'package:nora_app/models/focus.dart';

void main() {
  group('User model', () {
    test('fromJson parses valid JSON', () {
      final json = {
        'id': '123',
        'email': 'test@example.com',
        'name': 'Test User',
        'ageGroup': 'teen',
        'created_at': '2026-01-15T10:30:00.000Z',
      };

      final user = User.fromJson(json);

      expect(user.id, '123');
      expect(user.email, 'test@example.com');
      expect(user.name, 'Test User');
      expect(user.ageGroup, AgeGroup.teen);
      expect(user.createdAt, DateTime.parse('2026-01-15T10:30:00.000Z'));
    });

    test('fromJson defaults to adult for unknown age group', () {
      final json = {
        'id': '1',
        'email': 'a@b.com',
        'name': 'X',
        'ageGroup': 'unknown_group',
        'created_at': '2026-01-01T00:00:00.000Z',
      };

      final user = User.fromJson(json);
      expect(user.ageGroup, AgeGroup.adult);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': '1',
        'email': 'a@b.com',
        'name': 'X',
        'ageGroup': 'kid',
        'created_at': '2026-01-01T00:00:00.000Z',
      };

      final user = User.fromJson(json);
      expect(user.birthDate, isNull);
      expect(user.age, isNull);
      expect(user.avatarUrl, isNull);
      expect(user.settings, isNull);
    });

    test('toJson round-trips correctly', () {
      final original = User(
        id: '42',
        email: 'round@trip.com',
        name: 'Round Trip',
        ageGroup: AgeGroup.child,
        createdAt: DateTime.parse('2026-06-01T12:00:00.000Z'),
      );

      final json = original.toJson();
      final restored = User.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.email, original.email);
      expect(restored.name, original.name);
      expect(restored.ageGroup, original.ageGroup);
    });

    test('fromJson with empty string id defaults to empty', () {
      final json = {
        'id': '',
        'email': 'a@b.com',
        'name': 'X',
        'ageGroup': 'adult',
        'created_at': '2026-01-01T00:00:00.000Z',
      };

      final user = User.fromJson(json);
      expect(user.id, '');
    });
  });

  group('FocusSession model', () {
    test('fromJson parses backend format (snake_case)', () {
      final json = {
        'id': 'sess-1',
        'started_at': '2026-03-10T09:00:00.000Z',
        'ended_at': '2026-03-10T09:25:00.000Z',
        'duration_minutes': 25,
        'points_earned': 10,
        'completed': true,
      };

      final session = FocusSession.fromJson(json);

      expect(session.id, 'sess-1');
      expect(session.durationMinutes, 25);
      expect(session.pointsEarned, 10);
      expect(session.completed, true);
      expect(session.endTime, isNotNull);
    });

    test('fromJson parses Flutter format (camelCase)', () {
      final json = {
        'id': 'sess-2',
        'startTime': '2026-03-10T10:00:00.000Z',
        'endTime': '2026-03-10T10:30:00.000Z',
        'durationMinutes': 30,
        'pointsEarned': 15,
        'completed': true,
      };

      final session = FocusSession.fromJson(json);

      expect(session.id, 'sess-2');
      expect(session.durationMinutes, 30);
      expect(session.pointsEarned, 15);
    });

    test('fromJson handles missing optional fields gracefully', () {
      final json = <String, dynamic>{
        'id': 'sess-3',
        'started_at': '2026-03-10T11:00:00.000Z',
      };

      final session = FocusSession.fromJson(json);

      expect(session.id, 'sess-3');
      expect(session.endTime, isNull);
      expect(session.durationMinutes, 0);
      expect(session.pointsEarned, 0);
      expect(session.completed, false);
    });

    test('toJson round-trips correctly', () {
      final original = FocusSession(
        id: 'sess-rt',
        startTime: DateTime.parse('2026-03-10T12:00:00.000Z'),
        endTime: DateTime.parse('2026-03-10T12:25:00.000Z'),
        durationMinutes: 25,
        pointsEarned: 10,
        completed: true,
      );

      final json = original.toJson();
      final restored = FocusSession.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.durationMinutes, original.durationMinutes);
      expect(restored.pointsEarned, original.pointsEarned);
      expect(restored.completed, original.completed);
    });
  });
}
