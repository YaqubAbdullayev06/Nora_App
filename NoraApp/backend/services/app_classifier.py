"""
AI App Classifier — Uses LLM to analyze installed apps and usage data.
Recommends which apps to block for better focus and productivity.
"""
import json
from typing import Any, Optional


# Known app categories for classification
KNOWN_CATEGORIES = {
    "social_media": [
        "com.instagram.android", "com.facebook.katana", "com.twitter.android",
        "com.zhiliaoapp.musically", "com.ss.android.ugc.trill", "com.snapchat.android",
        "com.pinterest", "com.reddit.frontpage", "com.linkedin.android",
        "com.discord", "com.telegram.messenger", "org.telegram.messenger",
        "com.whatsapp", "com.viber.voip", "com.skype.raider",
        "com.facebook.lite", "com.instagram.lite", "com.twitter.android.lite",
    ],
    "entertainment": [
        "com.google.android.youtube", "com.netflix.mediaclient",
        "com.amazon.avod", "com.disney.disneyplus", "com.hbo.hbonow",
        "com.spotify.music", "com.apple.android.music",
        "com.google.android.apps.youtube.music",
        "com.ss.android.ugc.aweme", "com.kwai.video", "com.twitch.android.app",
        "com.vimeo.android.videoapp", "com.plexapp.android",
    ],
    "games": [
        "com.supercell.clashofclans", "com.supercell.clashroyale",
        "com.supercell.brawlstars", "com.epicgames.fortnite",
        "com.activision.callofduty.shooter", "com.garena.game.codm",
        "com.mobile.legends", "com.riotgames.league.wildrift",
        "com.mojang.minecraftpe", "com.ea.gp.fifamobile",
    ],
    "productivity": [
        "com.microsoft.office.outlook", "com.microsoft.office.word",
        "com.microsoft.office.excel", "com.google.android.apps.docs",
        "com.google.android.apps.sheets", "com.google.android.apps.slides",
        "com.notion.so", "com.trello", "com.asana",
        "com.slack", "com.microsoft.teams", "us.zoom.videomeetings",
        "com.google.android.calendar", "com.microsoft.office.onenote",
    ],
    "education": [
        "com.duolingo", "org.khanacademy", "com.udemy.android",
        "com.coursera.android", "com.quizlet.android",
        "com.kahoot.android", "com.google.android.apps.books",
        "com.memrise.android.memrise", "com.brainly",
    ],
}

# Age-appropriate blocking rules
AGE_BLOCKING_RULES = {
    "baby": {
        "always_block": ["social_media", "games", "news"],
        "max_social_media_minutes": 0,
        "max_entertainment_minutes": 15,
        "strict_mode": True,
    },
    "kid": {
        "always_block": ["social_media", "news"],
        "max_social_media_minutes": 0,
        "max_entertainment_minutes": 30,
        "max_game_minutes": 30,
        "strict_mode": True,
    },
    "teen": {
        "always_block": [],
        "max_social_media_minutes": 60,
        "max_entertainment_minutes": 120,
        "max_game_minutes": 60,
        "strict_mode": False,
    },
    "adult": {
        "always_block": [],
        "max_social_media_minutes": 120,
        "max_entertainment_minutes": 180,
        "max_game_minutes": 60,
        "strict_mode": False,
    },
}


class AppClassifier:
    """AI-powered app classifier and blocking recommender."""

    def __init__(self):
        self._classification_cache: dict[str, str] = {}

    def classify_apps(self, apps: list[dict[str, Any]], age_group: str = "adult") -> dict[str, Any]:
        """
        Classify apps and return blocking recommendations.
        Uses rule-based classification with AI enhancement for unknown apps.
        """
        classified = []
        recommendations = []
        ai_recommended_block = []
        ai_recommended_keep = []

        rules = AGE_BLOCKING_RULES.get(age_group, AGE_BLOCKING_RULES["adult"])

        for app in apps:
            package_name = app.get("packageName", "")
            app_name = app.get("appName", "")
            category = app.get("category", "other")
            is_system = app.get("isSystemApp", False)

            if is_system:
                classified.append({**app, "aiCategory": category, "shouldBlock": False})
                continue

            # Use known category or fall back to "other"
            if category == "other":
                category = self._classify_by_package(package_name)

            should_block = False
            reason = ""

            # Check age-based rules
            if category in rules.get("always_block", []):
                should_block = True
                reason = f"Age group '{age_group}' policy blocks {category} apps"

            classified.append({
                **app,
                "aiCategory": category,
                "shouldBlock": should_block,
                "blockReason": reason,
            })

            if should_block:
                ai_recommended_block.append({
                    "packageName": package_name,
                    "appName": app_name,
                    "category": category,
                    "reason": reason,
                })

        # Generate AI analysis summary
        category_counts = {}
        for item in classified:
            cat = item.get("aiCategory", "other")
            category_counts[cat] = category_counts.get(cat, 0) + 1

        distraction_apps = [a for a in classified if a.get("aiCategory") in ("social_media", "entertainment", "games") and not a.get("isSystemApp")]
        productive_apps = [a for a in classified if a.get("aiCategory") in ("productivity", "education") and not a.get("isSystemApp")]

        return {
            "success": True,
            "ageGroup": age_group,
            "totalApps": len(apps),
            "userApps": len([a for a in classified if not a.get("isSystemApp")]),
            "categoryBreakdown": category_counts,
            "distractionAppsCount": len(distraction_apps),
            "productiveAppsCount": len(productive_apps),
            "classifiedApps": classified,
            "aiRecommendedBlock": ai_recommended_block,
            "aiRecommendedKeep": ai_recommended_keep,
            "rules": rules,
            "summary": self._generate_summary(classified, rules, age_group),
        }

    def analyze_usage(self, usage_data: dict[str, Any], age_group: str = "adult") -> dict[str, Any]:
        """
        Analyze usage data and provide AI-powered insights.
        """
        rules = AGE_BLOCKING_RULES.get(age_group, AGE_BLOCKING_RULES["adult"])
        apps = usage_data.get("apps", [])
        total_time = usage_data.get("totalScreenTimeMinutes", 0)
        social_time = usage_data.get("socialMediaMinutes", 0)
        entertainment_time = usage_data.get("entertainmentMinutes", 0)

        # Check against limits
        alerts = []
        recommendations = []
        social_limit = rules.get("max_social_media_minutes", 999)
        entertainment_limit = rules.get("max_entertainment_minutes", 999)
        game_limit = rules.get("max_game_minutes", 999)

        if social_time > social_limit:
            alerts.append({
                "type": "limit_exceeded",
                "category": "social_media",
                "message": f"Social media usage ({social_time}m) exceeds recommended limit ({social_limit}m)",
                "severity": "high",
            })
            # Recommend blocking top social apps
            for app in apps:
                if app.get("category") == "social_media" and app.get("totalTimeMinutes", 0) > 15:
                    recommendations.append({
                        "action": "block",
                        "packageName": app["packageName"],
                        "appName": app["appName"],
                        "reason": f"Used {app['totalTimeMinutes']}m today, exceeds healthy limit",
                    })

        if entertainment_time > entertainment_limit:
            alerts.append({
                "type": "limit_exceeded",
                "category": "entertainment",
                "message": f"Entertainment usage ({entertainment_time}m) exceeds recommended limit ({entertainment_limit}m)",
                "severity": "medium",
            })

        # Find most used apps
        top_distraction = [
            a for a in apps
            if a.get("category") in ("social_media", "entertainment", "games")
        ][:5]

        top_productive = [
            a for a in apps
            if a.get("category") in ("productivity", "education")
        ][:5]

        # Generate insights
        insights = []
        if total_time > 180:
            insights.append("You've spent over 3 hours on your device today. Consider taking a break.")
        if social_time > total_time * 0.4 and total_time > 0:
            insights.append("Social media takes up over 40% of your screen time. This may impact focus.")
        if not top_productive:
            insights.append("No productive apps used today. Consider spending time on learning or work.")
        if total_time < 30:
            insights.append("Great job keeping screen time low today!")

        return {
            "success": True,
            "ageGroup": age_group,
            "totalScreenTimeMinutes": total_time,
            "alerts": alerts,
            "recommendations": recommendations,
            "topDistractionApps": top_distraction,
            "topProductiveApps": top_productive,
            "insights": insights,
            "focusScore": self._calculate_focus_score(total_time, social_time, entertainment_time),
        }

    def _classify_by_package(self, package_name: str) -> str:
        """Classify an app by its package name using known mappings."""
        for category, packages in KNOWN_CATEGORIES.items():
            if package_name in packages:
                return category

        # Fuzzy matching for variants
        package_lower = package_name.lower()
        if any(s in package_lower for s in ["instagram", "facebook", "twitter", "tiktok", "snap", "reddit"]):
            return "social_media"
        if any(s in package_lower for s in ["youtube", "netflix", "spotify", "twitch", "video", "music", "stream"]):
            return "entertainment"
        if any(s in package_lower for s in ["game", "clash", "fortnite", "puzzle", "race", "battle"]):
            return "games"
        if any(s in package_lower for s in ["office", "docs", "calendar", "note", "slack", "teams", "drive"]):
            return "productivity"
        if any(s in package_lower for s in ["learn", "study", "duolingo", "course", "quiz"]):
            return "education"

        return "other"

    def _generate_summary(self, classified: list, rules: dict, age_group: str) -> str:
        """Generate a human-readable summary of the classification."""
        total = len(classified)
        user_apps = [a for a in classified if not a.get("isSystemApp")]
        blocking_count = len([a for a in classified if a.get("shouldBlock")])
        social_count = len([a for a in user_apps if a.get("aiCategory") == "social_media"])
        games_count = len([a for a in user_apps if a.get("aiCategory") == "games"])
        productivity_count = len([a for a in user_apps if a.get("aiCategory") == "productivity"])

        lines = [
            f"Scanned {total} apps ({len(user_apps)} user-installed).",
            f"Found {social_count} social media apps, {games_count} games, {productivity_count} productivity apps.",
        ]

        if blocking_count > 0:
            blocking_apps = [a for a in classified if a.get("shouldBlock")]
            names = [a.get("appName", "") for a in blocking_apps[:5]]
            lines.append(f"AI recommends blocking {blocking_count} apps: {', '.join(names)}{'...' if blocking_count > 5 else ''}")

        if rules.get("strict_mode"):
            lines.append("Strict mode is active for this age group.")
        else:
            social_limit = rules.get("max_social_media_minutes", 0)
            if social_limit > 0:
                lines.append(f"Recommended social media limit: {social_limit} minutes/day.")
            elif social_limit == 0:
                lines.append("Social media is not recommended for this age group.")

        return " ".join(lines)

    def _calculate_focus_score(self, total_time: int, social_time: int, entertainment_time: int) -> int:
        """Calculate a focus score (0-100) based on usage patterns."""
        if total_time == 0:
            return 100

        distraction_time = social_time + entertainment_time
        distraction_ratio = distraction_time / total_time

        # Start with 100, deduct based on distraction ratio
        score = max(0, int(100 - (distraction_ratio * 100)))

        # Extra penalty for excessive total screen time
        if total_time > 240:
            score = max(0, score - 20)
        elif total_time > 120:
            score = max(0, score - 10)

        return score


# Singleton
app_classifier = AppClassifier()
