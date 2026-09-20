import 'package:flutter/material.dart';
import '../core/enums/age_group.dart';
import '../core/theme/persona_theme.dart';

/// ChangeNotifier wrapper around [PersonaTheme] that integrates with Provider.
///
/// When the persona changes, [notifyListeners] fires and any widget that
/// depends on this provider (via [Provider.of] or [Consumer]) rebuilds.
///
/// [DesignTokens] keeps its static getters for backward compatibility;
/// they now read from the provider so the widget tree stays reactive.
class DesignTokensProvider extends ChangeNotifier {
  PersonaTheme _persona;

  DesignTokensProvider({PersonaTheme? initial})
      : _persona = initial ?? PersonaTheme.adultTheme;

  /// The current persona theme.
  PersonaTheme get persona => _persona;

  /// The current age group.
  AgeGroup get ageGroup => _persona.ageGroup;

  /// Switch to a new persona. Fires [notifyListeners] so the UI rebuilds.
  void setPersona(PersonaTheme newPersona) {
    if (_persona == newPersona) return;
    _persona = newPersona;
    // Update the static accessor so non-widget code still works.
    DesignTokensScope._current = newPersona;
    notifyListeners();
  }

  /// Convenience: switch persona by age group.
  void setAgeGroup(AgeGroup group) {
    setPersona(PersonaTheme.forAgeGroup(group));
  }
}

/// Static accessor that keeps [DesignTokens.xxx] working without a context.
///
/// After [DesignTokensProvider] is mounted in the widget tree, its
/// [setPersona] method updates this automatically. Legacy call sites that
/// used [DesignTokens.init] should migrate to the provider, but this
/// ensures nothing breaks during the transition.
class DesignTokensScope {
  DesignTokensScope._();

  static PersonaTheme _current = PersonaTheme.adultTheme;

  static PersonaTheme get current => _current;

  /// Legacy init — prefer [DesignTokensProvider.setPersona] instead.
  static void init(PersonaTheme theme) {
    _current = theme;
  }
}
