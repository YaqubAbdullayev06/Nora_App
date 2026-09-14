import 'package:flutter/material.dart';

/// Centralized emoji-to-icon mapping for Nora app.
/// Replaces all emoji characters with proper Flutter Icons or SVG assets.
class EmojiIcons {
  EmojiIcons._();

  // ─── Category Icons ───
  static const IconData social = Icons.chat_rounded;
  static const IconData entertainment = Icons.movie_rounded;
  static const IconData gaming = Icons.sports_esports_rounded;
  static const IconData productivity = Icons.work_rounded;
  static const IconData messaging = Icons.forum_rounded;
  static const IconData education = Icons.auto_stories_rounded;
  static const IconData news = Icons.article_rounded;
  static const IconData photography = Icons.camera_alt_rounded;
  static const IconData finance = Icons.account_balance_rounded;
  static const IconData health = Icons.local_hospital_rounded;
  static const IconData shopping = Icons.shopping_cart_rounded;
  static const IconData utilities = Icons.build_rounded;
  static const IconData other = Icons.apps_rounded;

  // ─── Achievement Icons ───
  static const IconData streak = Icons.local_fire_department_rounded;
  static const IconData earlyBird = Icons.wb_sunny_rounded;
  static const IconData trophy = Icons.emoji_events_rounded;
  static const IconData target = Icons.gps_fixed_rounded;
  static const IconData trending = Icons.trending_up_rounded;
  static const IconData analytics = Icons.analytics_rounded;
  static const IconData sync = Icons.sync_rounded;
  static const IconData brain = Icons.psychology_rounded;

  // ─── Notification Icons ───
  static const IconData alert = Icons.warning_rounded;
  static const IconData idea = Icons.lightbulb_rounded;
  static const IconData chart = Icons.bar_chart_rounded;
  static const IconData award = Icons.emoji_events_rounded;

  // ─── Sound Icons ───
  static const IconData ocean = Icons.waves_rounded;
  static const IconData forest = Icons.forest_rounded;
  static const IconData coffee = Icons.coffee_rounded;
  static const IconData nature = Icons.eco_rounded;

  // ─── Misc Icons ───
  static const IconData star = Icons.star_rounded;
  static const IconData lock = Icons.lock_rounded;
  static const IconData sparkles = Icons.auto_awesome_rounded;

  // ─── Category Emoji to Icon Mapping ───
  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'social':
        return social;
      case 'entertainment':
        return entertainment;
      case 'gaming':
        return gaming;
      case 'productivity':
        return productivity;
      case 'messaging':
        return messaging;
      case 'education':
        return education;
      case 'news':
        return news;
      case 'photography':
        return photography;
      case 'finance':
        return finance;
      case 'health':
        return health;
      case 'shopping':
        return shopping;
      case 'utilities':
        return utilities;
      default:
        return other;
    }
  }

  // ─── Category Color Mapping ───
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'social':
        return const Color(0xFF4267B2); // Facebook blue
      case 'entertainment':
        return const Color(0xFFE50914); // Netflix red
      case 'gaming':
        return const Color(0xFF7289DA); // Discord purple
      case 'productivity':
        return const Color(0xFF0078D4); // Microsoft blue
      case 'messaging':
        return const Color(0xFF25D366); // WhatsApp green
      case 'education':
        return const Color(0xFF1976D2); // Learning blue
      case 'news':
        return const Color(0xFF424242); // News gray
      case 'photography':
        return const Color(0xFFE1306C); // Instagram pink
      case 'finance':
        return const Color(0xFF00C853); // Money green
      case 'health':
        return const Color(0xFF00BFA5); // Health teal
      case 'shopping':
        return const Color(0xFFFF6D00); // Shopping orange
      case 'utilities':
        return const Color(0xFF78909C); // Utility blue-gray
      default:
        return const Color(0xFF9E9E9E); // Default gray
    }
  }

  // ─── Achievement Emoji to Icon Mapping ───
  static IconData getAchievementIcon(String title) {
    if (title.contains('Streak')) return streak;
    if (title.contains('Early Bird')) return earlyBird;
    if (title.contains('Best') || title.contains('Perfect')) return trophy;
    if (title.contains('Focus') || title.contains('Master')) return target;
    return star;
  }

  // ─── Notification Emoji to Icon Mapping ───
  static IconData getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'alert':
        return alert;
      case 'suggestion':
      case 'idea':
        return idea;
      case 'insight':
        return chart;
      case 'achievement':
        return award;
      default:
        return idea;
    }
  }

  // ─── Sound Emoji to Icon Mapping ───
  static IconData getSoundIcon(String soundName) {
    if (soundName.toLowerCase().contains('ocean') ||
        soundName.toLowerCase().contains('wave') ||
        soundName.toLowerCase().contains('white') ||
        soundName.toLowerCase().contains('pink')) {
      return ocean;
    }
    if (soundName.toLowerCase().contains('forest') ||
        soundName.toLowerCase().contains('nature')) {
      return forest;
    }
    if (soundName.toLowerCase().contains('café') ||
        soundName.toLowerCase().contains('cafe')) {
      return coffee;
    }
    return nature;
  }
}
