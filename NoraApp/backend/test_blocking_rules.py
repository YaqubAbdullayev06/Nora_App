"""Tests for blocking_rules — age-specific app blocking configuration."""
import sys
import os

# Add backend dir to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from services.blocking_rules import AGE_BLOCKING_RULES, KNOWN_CATEGORIES


class TestAgeBlockingRules:
    """Tests for AGE_BLOCKING_RULES data structure."""

    def test_all_age_groups_present(self):
        expected = {"baby", "kid", "teen", "adult"}
        assert set(AGE_BLOCKING_RULES.keys()) == expected

    def test_baby_rules_are_strict(self):
        rules = AGE_BLOCKING_RULES["baby"]
        assert rules["strict_mode"] is True
        assert "social_media" in rules["always_block"]
        assert "games" in rules["always_block"]
        assert rules["max_social_media_minutes"] == 0
        assert rules["max_entertainment_minutes"] == 15

    def test_kid_blocks_social_media(self):
        rules = AGE_BLOCKING_RULES["kid"]
        assert rules["strict_mode"] is True
        assert "social_media" in rules["always_block"]
        assert rules["max_social_media_minutes"] == 0
        assert rules["max_game_minutes"] == 30

    def test_teen_has_moderate_limits(self):
        rules = AGE_BLOCKING_RULES["teen"]
        assert rules["strict_mode"] is False
        assert rules["always_block"] == []
        assert rules["max_social_media_minutes"] == 60
        assert rules["max_entertainment_minutes"] == 120

    def test_adult_has_relaxed_limits(self):
        rules = AGE_BLOCKING_RULES["adult"]
        assert rules["strict_mode"] is False
        assert rules["always_block"] == []
        assert rules["max_social_media_minutes"] == 120
        assert rules["max_entertainment_minutes"] == 180

    def test_rules_increase_with_age(self):
        """Social media limits should increase from baby → adult."""
        baby_social = AGE_BLOCKING_RULES["baby"]["max_social_media_minutes"]
        teen_social = AGE_BLOCKING_RULES["teen"]["max_social_media_minutes"]
        adult_social = AGE_BLOCKING_RULES["adult"]["max_social_media_minutes"]
        assert baby_social < teen_social < adult_social


class TestKnownCategories:
    """Tests for KNOWN_CATEGORIES data structure."""

    def test_has_required_categories(self):
        required = {"social_media", "entertainment", "games", "productivity", "education"}
        assert required.issubset(set(KNOWN_CATEGORIES.keys()))

    def test_social_media_contains_instagram(self):
        assert "com.instagram.android" in KNOWN_CATEGORIES["social_media"]

    def test_entertainment_contains_youtube(self):
        assert "com.google.android.youtube" in KNOWN_CATEGORIES["entertainment"]

    def test_games_contains_minecraft(self):
        assert "com.mojang.minecraftpe" in KNOWN_CATEGORIES["games"]

    def test_productivity_contains_slack(self):
        assert "com.slack" in KNOWN_CATEGORIES["productivity"]

    def test_education_contains_duolingo(self):
        assert "com.duolingo" in KNOWN_CATEGORIES["education"]

    def test_no_package_duplicates_across_categories(self):
        """No package should appear in multiple categories."""
        all_packages = []
        for packages in KNOWN_CATEGORIES.values():
            all_packages.extend(packages)
        assert len(all_packages) == len(set(all_packages)), \
            f"Duplicate packages found: {[p for p in all_packages if all_packages.count(p) > 1]}"
