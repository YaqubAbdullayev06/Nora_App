import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nora_app/core/enums/age_group.dart';
import 'package:nora_app/core/theme/persona_theme.dart';

/// Persona theming tests.
///
/// Validates that each age group produces distinct, consistent themes
/// and that all required properties are present.
void main() {
  group('PersonaTheme', () {
    test('Kid theme has fox mascot and playful colors', () {
      final theme = PersonaTheme.forAge(AgeGroup.kid);

      expect(theme.mascotAsset, contains('fox'));
      expect(theme.displayName, 'Kid');
      expect(theme.personaName, 'Nora Fox');
      expect(theme.ageRange, '7-12');
      expect(theme.primary, isNotNull);
      expect(theme.accent, isNotNull);
      expect(theme.gradient, isNotNull);
    });

    test('Teen theme has bolt mascot and electric colors', () {
      final theme = PersonaTheme.forAge(AgeGroup.teen);

      expect(theme.mascotAsset, contains('bolt'));
      expect(theme.displayName, 'Teen');
      expect(theme.personaName, 'Nora Bolt');
      expect(theme.ageRange, '13-17');
      expect(theme.primary, isNotNull);
      expect(theme.accent, isNotNull);
    });

    test('Adult theme has brain mascot and green colors', () {
      final theme = PersonaTheme.forAge(AgeGroup.adult);

      expect(theme.mascotAsset, contains('brain'));
      expect(theme.displayName, 'Adult');
      expect(theme.personaName, 'Nora Brain');
      expect(theme.ageRange, '18+');
    });

    test('Child theme has star mascot and safe colors', () {
      final theme = PersonaTheme.forAge(AgeGroup.child);

      expect(theme.mascotAsset, contains('star'));
      expect(theme.displayName, 'Child (Parent-Managed)');
      expect(theme.personaName, 'Nora Little');
      expect(theme.ageRange, '1-6');
    });

    test('All themes have valid gradient colors', () {
      for (final age in AgeGroup.values) {
        final theme = PersonaTheme.forAge(age);
        final gradient = theme.gradient;

        expect(gradient, isNotNull, reason: '$age theme should have gradient');
        expect(gradient!.colors.length, 2, reason: '$age gradient should have 2 colors');
      }
    });

    test('Each persona has a unique primary color', () {
      final colors = AgeGroup.values
          .map((age) => PersonaTheme.forAge(age).primary.value)
          .toSet();

      // All primary colors should be unique (4 personas)
      expect(colors.length, AgeGroup.values.length,
          reason: 'Each persona should have a distinct primary color');
    });
  });

  group('AgeGroup', () {
    test('has all expected values', () {
      expect(AgeGroup.values.length, 4);
      expect(AgeGroup.child, isNotNull);
      expect(AgeGroup.kid, isNotNull);
      expect(AgeGroup.teen, isNotNull);
      expect(AgeGroup.adult, isNotNull);
    });

    test('child displays as Parent-Managed', () {
      expect(AgeGroup.child.displayName, 'Child (Parent-Managed)');
    });

    test('child persona is Nora Little', () {
      expect(AgeGroup.child.personaName, 'Nora Little');
    });
  });
}
