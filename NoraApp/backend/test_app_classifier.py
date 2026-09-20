"""Tests for AppClassifier — AI-powered app classification."""
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from services.app_classifier import app_classifier


class TestAppClassifier:
    """Tests for the AppClassifier singleton."""

    def test_classify_social_media_app(self):
        apps = [{"packageName": "com.instagram.android", "appName": "Instagram", "category": "other", "isSystemApp": False}]
        result = app_classifier.classify_apps(apps, "adult")
        assert result["success"] is True
        assert len(result["classifiedApps"]) == 1
        assert result["classifiedApps"][0]["aiCategory"] == "social_media"

    def test_classify_system_app_not_blocked(self):
        apps = [{"packageName": "com.android.phone", "appName": "Phone", "category": "other", "isSystemApp": True}]
        result = app_classifier.classify_apps(apps, "adult")
        assert result["classifiedApps"][0]["shouldBlock"] is False

    def test_baby_age_group_blocks_social_media(self):
        apps = [{"packageName": "com.instagram.android", "appName": "Instagram", "category": "social_media", "isSystemApp": False}]
        result = app_classifier.classify_apps(apps, "baby")
        assert result["classifiedApps"][0]["shouldBlock"] is True
        assert len(result["aiRecommendedBlock"]) == 1

    def test_adult_age_group_allows_social_media(self):
        apps = [{"packageName": "com.instagram.android", "appName": "Instagram", "category": "social_media", "isSystemApp": False}]
        result = app_classifier.classify_apps(apps, "adult")
        assert result["classifiedApps"][0]["shouldBlock"] is False

    def test_classify_productive_app_not_blocked(self):
        apps = [{"packageName": "com.slack", "appName": "Slack", "category": "productivity", "isSystemApp": False}]
        result = app_classifier.classify_apps(apps, "adult")
        assert result["classifiedApps"][0]["shouldBlock"] is False

    def test_empty_apps_returns_success(self):
        result = app_classifier.classify_apps([], "adult")
        assert result["success"] is True
        assert result["totalApps"] == 0
        assert result["classifiedApps"] == []

    def test_summary_generated(self):
        apps = [{"packageName": "com.instagram.android", "appName": "Instagram", "category": "social_media", "isSystemApp": False}]
        result = app_classifier.classify_apps(apps, "baby")
        assert isinstance(result["summary"], str)
        assert len(result["summary"]) > 0

    def test_category_breakdown_counted(self):
        apps = [
            {"packageName": "com.instagram.android", "appName": "Instagram", "category": "social_media", "isSystemApp": False},
            {"packageName": "com.slack", "appName": "Slack", "category": "productivity", "isSystemApp": False},
        ]
        result = app_classifier.classify_apps(apps, "adult")
        assert result["categoryBreakdown"]["social_media"] == 1
        assert result["categoryBreakdown"]["productivity"] == 1

    def test_fuzzy_classification_by_package_name(self):
        """Unknown category apps should be classified by package name fuzzy matching."""
        apps = [{"packageName": "com.random.tiktok.clone", "appName": "TikTok Clone", "category": "other", "isSystemApp": False}]
        result = app_classifier.classify_apps(apps, "adult")
        assert result["classifiedApps"][0]["aiCategory"] == "social_media"


class TestAnalyzeUsage:
    """Tests for usage analysis."""

    def test_analyze_usage_returns_success(self):
        usage = {
            "apps": [],
            "totalScreenTimeMinutes": 60,
            "socialMediaMinutes": 30,
            "entertainmentMinutes": 10,
        }
        result = app_classifier.analyze_usage(usage, "adult")
        assert result["success"] is True
        assert result["totalScreenTimeMinutes"] == 60

    def test_social_media_over_limit_triggers_alert(self):
        usage = {
            "apps": [{"packageName": "com.instagram.android", "appName": "Instagram", "category": "social_media", "totalTimeMinutes": 90}],
            "totalScreenTimeMinutes": 120,
            "socialMediaMinutes": 90,
            "entertainmentMinutes": 0,
        }
        result = app_classifier.analyze_usage(usage, "teen")
        assert len(result["alerts"]) > 0
        assert any(a["category"] == "social_media" for a in result["alerts"])

    def test_low_screen_time_gets_positive_insight(self):
        usage = {
            "apps": [],
            "totalScreenTimeMinutes": 15,
            "socialMediaMinutes": 0,
            "entertainmentMinutes": 0,
        }
        result = app_classifier.analyze_usage(usage, "adult")
        assert any("Great job" in i or "low" in i.lower() for i in result["insights"])
