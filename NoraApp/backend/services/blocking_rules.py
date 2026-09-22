"""
Age-specific app blocking rules and known app category mappings.

Extracted from app_classifier.py for clarity and reusability.
"""

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
        "always_block": ["social_media", "games"],
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


def get_blocking_rules(age_group: str) -> dict:
    """Look up blocking rules for an age group.

    "child" is an alias for "baby" (ages 1-6) so both get strict rules
    instead of falling through to the adult defaults.
    """
    if age_group in ("child", "baby"):
        return AGE_BLOCKING_RULES["baby"]
    return AGE_BLOCKING_RULES.get(age_group, AGE_BLOCKING_RULES["adult"])
