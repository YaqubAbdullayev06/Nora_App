import 'package:flutter_test/flutter_test.dart';
import 'package:nora_app/core/enums/age_group.dart';
import 'package:nora_app/features/profile/utils/age_group_helpers.dart';

void main() {
  group('AgeGroup extension properties', () {
    test('scoreLabel returns correct values for each age group', () {
      expect(AgeGroup.baby.scoreLabel, 'Stars');
      expect(AgeGroup.child.scoreLabel, 'Stars');
      expect(AgeGroup.kid.scoreLabel, 'Points');
      expect(AgeGroup.teen.scoreLabel, 'XP');
      expect(AgeGroup.adult.scoreLabel, 'Score');
    });

    test('streakLabel returns correct values for each age group', () {
      expect(AgeGroup.baby.streakLabel, 'Days');
      expect(AgeGroup.child.streakLabel, 'Days');
      expect(AgeGroup.kid.streakLabel, 'Streak');
      expect(AgeGroup.teen.streakLabel, 'Streak');
      expect(AgeGroup.adult.streakLabel, 'Streak');
    });

    test('sessionsLabel returns correct values for each age group', () {
      expect(AgeGroup.baby.sessionsLabel, 'Plays');
      expect(AgeGroup.child.sessionsLabel, 'Plays');
      expect(AgeGroup.kid.sessionsLabel, 'Quests');
      expect(AgeGroup.teen.sessionsLabel, 'Sessions');
      expect(AgeGroup.adult.sessionsLabel, 'Sessions');
    });

    test('timeLabel returns correct values for each age group', () {
      expect(AgeGroup.baby.timeLabel, 'Play Time');
      expect(AgeGroup.child.timeLabel, 'Play Time');
      expect(AgeGroup.kid.timeLabel, 'Focus Time');
      expect(AgeGroup.teen.timeLabel, 'Study Time');
      expect(AgeGroup.adult.timeLabel, 'Deep Work');
    });

    test('settingsTitle returns correct values', () {
      expect(AgeGroup.baby.settingsTitle, 'Settings');
      expect(AgeGroup.kid.settingsTitle, 'Options');
      expect(AgeGroup.adult.settingsTitle, 'Settings');
    });

    test('logoutLabel returns correct values', () {
      expect(AgeGroup.baby.logoutLabel, 'Bye-bye!');
      expect(AgeGroup.kid.logoutLabel, 'Log Out');
      expect(AgeGroup.teen.logoutLabel, 'Sign Out');
      expect(AgeGroup.adult.logoutLabel, 'Sign Out');
    });
  });

  group('AgeGroup enum basics', () {
    test('has exactly 5 values', () {
      expect(AgeGroup.values.length, 5);
    });

    test('values are in expected order', () {
      expect(AgeGroup.values, [
        AgeGroup.baby,
        AgeGroup.child,
        AgeGroup.kid,
        AgeGroup.teen,
        AgeGroup.adult,
      ]);
    });

    test('name property returns lowercase string', () {
      expect(AgeGroup.baby.name, 'baby');
      expect(AgeGroup.child.name, 'child');
      expect(AgeGroup.kid.name, 'kid');
      expect(AgeGroup.teen.name, 'teen');
      expect(AgeGroup.adult.name, 'adult');
    });
  });
}
