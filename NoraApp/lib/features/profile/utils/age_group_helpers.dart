import 'package:flutter/material.dart';
import '../../../core/enums/age_group.dart';

extension AgeGroupHelpers on AgeGroup {
  String get scoreLabel {
    switch (this) {
      case AgeGroup.baby:
        return 'Stars';
      case AgeGroup.child:
        return 'Stars';
      case AgeGroup.kid:
        return 'Points';
      case AgeGroup.teen:
        return 'XP';
      case AgeGroup.adult:
        return 'Score';
    }
  }

  String get streakLabel {
    switch (this) {
      case AgeGroup.baby:
        return 'Days';
      case AgeGroup.child:
        return 'Days';
      case AgeGroup.kid:
        return 'Streak';
      case AgeGroup.teen:
        return 'Streak';
      case AgeGroup.adult:
        return 'Streak';
    }
  }

  String get sessionsLabel {
    switch (this) {
      case AgeGroup.baby:
        return 'Plays';
      case AgeGroup.child:
        return 'Plays';
      case AgeGroup.kid:
        return 'Quests';
      case AgeGroup.teen:
        return 'Sessions';
      case AgeGroup.adult:
        return 'Sessions';
    }
  }

  String get timeLabel {
    switch (this) {
      case AgeGroup.baby:
        return 'Play Time';
      case AgeGroup.child:
        return 'Play Time';
      case AgeGroup.kid:
        return 'Focus Time';
      case AgeGroup.teen:
        return 'Study Time';
      case AgeGroup.adult:
        return 'Deep Work';
    }
  }

  String get settingsTitle {
    switch (this) {
      case AgeGroup.baby:
        return 'Settings';
      case AgeGroup.child:
        return 'Settings';
      case AgeGroup.kid:
        return 'Options';
      case AgeGroup.teen:
        return 'Settings';
      case AgeGroup.adult:
        return 'Settings';
    }
  }

  String get editProfileSubtitle {
    switch (this) {
      case AgeGroup.baby:
        return 'Ask a grown-up to help';
      case AgeGroup.child:
        return 'Ask a grown-up to help';
      case AgeGroup.kid:
        return 'Change your name or avatar';
      case AgeGroup.teen:
        return 'Update your info';
      case AgeGroup.adult:
        return 'Manage your account';
    }
  }

  String get notificationSubtitle {
    switch (this) {
      case AgeGroup.baby:
        return 'Fun reminders';
      case AgeGroup.child:
        return 'Fun reminders';
      case AgeGroup.kid:
        return 'Alert me for quests';
      case AgeGroup.teen:
        return 'Customize alerts';
      case AgeGroup.adult:
        return 'Manage notifications';
    }
  }

  String get accountTitle {
    switch (this) {
      case AgeGroup.baby:
        return 'More';
      case AgeGroup.child:
        return 'More';
      case AgeGroup.kid:
        return 'Account';
      case AgeGroup.teen:
        return 'Account';
      case AgeGroup.adult:
        return 'Account';
    }
  }

  String get helpTitle {
    switch (this) {
      case AgeGroup.baby:
        return 'Help';
      case AgeGroup.child:
        return 'Help';
      case AgeGroup.kid:
        return 'Get Help';
      case AgeGroup.teen:
        return 'Support';
      case AgeGroup.adult:
        return 'Help & Support';
    }
  }

  String get helpSubtitle {
    switch (this) {
      case AgeGroup.baby:
        return 'Ask a grown-up';
      case AgeGroup.child:
        return 'Ask a grown-up';
      case AgeGroup.kid:
        return 'Chat with Nora';
      case AgeGroup.teen:
        return 'FAQ and contact';
      case AgeGroup.adult:
        return 'FAQ, contact, docs';
    }
  }

  String get logoutLabel {
    switch (this) {
      case AgeGroup.baby:
        return 'Bye-bye!';
      case AgeGroup.child:
        return 'Bye-bye!';
      case AgeGroup.kid:
        return 'Log Out';
      case AgeGroup.teen:
        return 'Sign Out';
      case AgeGroup.adult:
        return 'Sign Out';
    }
  }

  String get logoutTitle {
    switch (this) {
      case AgeGroup.baby:
        return 'Say bye-bye?';
      case AgeGroup.child:
        return 'Say bye-bye?';
      case AgeGroup.kid:
        return 'Log out?';
      case AgeGroup.teen:
        return 'Sign out?';
      case AgeGroup.adult:
        return 'Sign out?';
    }
  }

  String get logoutMessage {
    switch (this) {
      case AgeGroup.baby:
        return 'Nora will miss you! See you soon!';
      case AgeGroup.child:
        return 'Nora will miss you! See you soon!';
      case AgeGroup.kid:
        return 'Your progress will be saved. Come back soon!';
      case AgeGroup.teen:
        return 'Your data is safe. See you next time!';
      case AgeGroup.adult:
        return 'Your session will end. All data is saved.';
    }
  }

  String get logoutButtonLabel {
    switch (this) {
      case AgeGroup.baby:
        return 'Bye!';
      case AgeGroup.child:
        return 'Bye!';
      case AgeGroup.kid:
        return 'Log Out';
      case AgeGroup.teen:
        return 'Sign Out';
      case AgeGroup.adult:
        return 'Sign Out';
    }
  }

  List<Map<String, String>> get features {
    switch (this) {
      case AgeGroup.baby:
        return [
          {'label': 'Play', 'icon': 'sports_esports'},
          {'label': 'Colors', 'icon': 'palette'},
          {'label': 'Music', 'icon': 'music_note'},
        ];
      case AgeGroup.child:
        return [
          {'label': 'Play', 'icon': 'sports_esports'},
          {'label': 'Colors', 'icon': 'palette'},
          {'label': 'Music', 'icon': 'music_note'},
        ];
      case AgeGroup.kid:
        return [
          {'label': 'Adventures', 'icon': 'explore'},
          {'label': 'Games', 'icon': 'sports_esports'},
          {'label': 'Learning', 'icon': 'school'},
        ];
      case AgeGroup.teen:
        return [
          {'label': 'Focus', 'icon': 'center_focus_strong'},
          {'label': 'Social', 'icon': 'people'},
          {'label': 'Goals', 'icon': 'flag'},
        ];
      case AgeGroup.adult:
        return [
          {'label': 'Productivity', 'icon': 'trending_up'},
          {'label': 'Analytics', 'icon': 'analytics'},
          {'label': 'Wellness', 'icon': 'spa'},
        ];
    }
  }

  IconData featureIcon(String icon) {
    switch (icon) {
      case 'sports_esports':
        return Icons.sports_esports_rounded;
      case 'palette':
        return Icons.palette_rounded;
      case 'music_note':
        return Icons.music_note_rounded;
      case 'explore':
        return Icons.explore_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'center_focus_strong':
        return Icons.center_focus_strong_rounded;
      case 'people':
        return Icons.people_rounded;
      case 'flag':
        return Icons.flag_rounded;
      case 'trending_up':
        return Icons.trending_up_rounded;
      case 'analytics':
        return Icons.analytics_rounded;
      case 'spa':
        return Icons.spa_rounded;
      default:
        return Icons.star_rounded;
    }
  }
}
