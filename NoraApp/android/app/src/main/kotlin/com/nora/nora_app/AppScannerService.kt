package com.nora.nora_app

import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import android.text.TextUtils
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.concurrent.TimeUnit

/**
 * AppScannerService — Scans all installed apps on the device.
 * Provides app metadata, categorization, and usage statistics
 * for the AI classifier to make blocking decisions.
 */
class AppScannerService(private val context: Context) {

    private val packageManager: PackageManager = context.packageManager

    data class AppInfo(
        val packageName: String,
        val appName: String,
        val isSystemApp: Boolean,
        val category: String,
        val installTime: Long,
        val lastUpdateTime: Long,
        val versionName: String,
        val targetSdk: Int,
    )

    /**
     * Scan all installed apps on the device.
     * Uses getInstalledPackages to find ALL apps (not just launcher apps).
     * Returns a list of app info maps for Flutter consumption.
     */
    fun scanAllApps(): List<Map<String, Any>> {
        val packages = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.getInstalledPackages(PackageManager.MATCH_ALL)
        } else {
            @Suppress("DEPRECATION")
            packageManager.getInstalledPackages(0)
        }

        val seenPackages = mutableSetOf<String>()
        val apps = mutableListOf<Map<String, Any>>()

        for (packageInfo in packages) {
            val packageName = packageInfo.packageName
            if (packageName == context.packageName) continue // Skip Nora itself
            if (seenPackages.contains(packageName)) continue
            seenPackages.add(packageName)

            try {
                val appInfo = packageInfo.applicationInfo ?: continue
                val label = packageManager.getApplicationLabel(appInfo).toString()
                val isSystem = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                val category = categorizeApp(appInfo, packageName)
                val installTime = packageInfo.firstInstallTime
                val lastUpdate = packageInfo.lastUpdateTime
                val version = packageInfo.versionName ?: ""
                val targetSdk = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    appInfo.targetSdkVersion
                } else {
                    0
                }

                apps.add(mapOf(
                    "packageName" to packageName,
                    "appName" to label,
                    "isSystemApp" to isSystem,
                    "category" to category,
                    "installTime" to installTime,
                    "lastUpdateTime" to lastUpdate,
                    "versionName" to version,
                    "targetSdk" to targetSdk,
                ))
            } catch (_: Exception) {
                // Skip apps we can't read
            }
        }

        return apps.sortedBy { it["appName"].toString().lowercase() }
    }

    /**
     * Get detailed info for a specific app.
     */
    fun getAppDetails(packageName: String): Map<String, Any>? {
        return try {
            val appInfo = packageManager.getApplicationInfo(packageName, 0)
            val label = packageManager.getApplicationLabel(appInfo).toString()
            val isSystem = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
            val category = categorizeApp(appInfo, packageName)
            val installTime = getInstallTime(packageName)
            val lastUpdate = getUpdateTime(packageName)
            val version = getVersionName(packageName)
            val usageToday = getUsageForPackage(packageName, TimeUnit.MILLISECONDS.toMillis(System.currentTimeMillis()) - TimeUnit.HOURS.toMillis(24))
            val usageWeek = getUsageForPackage(packageName, TimeUnit.MILLISECONDS.toMillis(System.currentTimeMillis()) - TimeUnit.DAYS.toMillis(7))

            mapOf(
                "packageName" to packageName,
                "appName" to label,
                "isSystemApp" to isSystem,
                "category" to category,
                "installTime" to installTime,
                "lastUpdateTime" to lastUpdate,
                "versionName" to (version ?: ""),
                "usageTodayMinutes" to (usageToday / 60000).toInt(),
                "usageWeekMinutes" to (usageWeek / 60000).toInt(),
            )
        } catch (_: Exception) {
            null
        }
    }

    /**
     * Get usage stats for all non-system apps.
     */
    fun getUsageStats(daysBack: Int = 7): List<Map<String, Any>> {
        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            ?: return emptyList()

        val calendar = Calendar.getInstance()
        val endTime = calendar.timeInMillis
        calendar.add(Calendar.DAY_OF_YEAR, -daysBack)
        val startTime = calendar.timeInMillis

        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY, startTime, endTime
        ) ?: return emptyList()

        return stats
            .filter { it.totalTimeInForeground > 0 }
            .map { stat ->
                val appName = try {
                    val appInfo = packageManager.getApplicationInfo(stat.packageName, 0)
                    packageManager.getApplicationLabel(appInfo).toString()
                } catch (_: Exception) {
                    stat.packageName
                }
                val isSystem = try {
                    val appInfo = packageManager.getApplicationInfo(stat.packageName, 0)
                    (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                } catch (_: Exception) {
                    false
                }
                val category = try {
                    val appInfo = packageManager.getApplicationInfo(stat.packageName, 0)
                    categorizeApp(appInfo, stat.packageName)
                } catch (_: Exception) {
                    "unknown"
                }

                mapOf(
                    "packageName" to stat.packageName,
                    "appName" to appName,
                    "totalTimeMinutes" to TimeUnit.MILLISECONDS.toMinutes(stat.totalTimeInForeground).toInt(),
                    "lastTimeUsed" to stat.lastTimeUsed,
                    "category" to category,
                    "isSystemApp" to isSystem,
                )
            }
            .filter { !(it["isSystemApp"] as Boolean) }
            .sortedByDescending { it["totalTimeMinutes"] as Int }
    }

    /**
     * Get the blocked apps list from SharedPreferences.
     */
    fun getBlockedApps(): Set<String> {
        val prefs = context.getSharedPreferences(MainActivity.PREFERENCES_NAME, Context.MODE_PRIVATE)
        return prefs.getStringSet(MainActivity.BLOCKED_PACKAGES_KEY, emptySet()) ?: emptySet()
    }

    /**
     * Set the blocked apps list in SharedPreferences.
     */
    fun setBlockedApps(packages: Set<String>) {
        context.getSharedPreferences(MainActivity.PREFERENCES_NAME, Context.MODE_PRIVATE)
            .edit()
            .putStringSet(MainActivity.BLOCKED_PACKAGES_KEY, packages)
            .apply()
    }

    /**
     * Add apps to the block list.
     * Also enables blocking so the accessibility service will intercept.
     */
    fun addToBlockedApps(additional: Set<String>) {
        val current = getBlockedApps().toMutableSet()
        current.addAll(additional)
        setBlockedApps(current)
        // Enable blocking so FocusBlockingAccessibilityService will check the list
        context.getSharedPreferences(MainActivity.PREFERENCES_NAME, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(MainActivity.BLOCKING_ENABLED_KEY, true)
            .apply()
    }

    /**
     * Remove apps from the block list.
     * Disables blocking when the list becomes empty.
     */
    fun removeFromBlockedApps(removals: Set<String>) {
        val current = getBlockedApps().toMutableSet()
        current.removeAll(removals)
        setBlockedApps(current)
        // Disable blocking when no apps are left to block
        if (current.isEmpty()) {
            context.getSharedPreferences(MainActivity.PREFERENCES_NAME, Context.MODE_PRIVATE)
                .edit()
                .putBoolean(MainActivity.BLOCKING_ENABLED_KEY, false)
                .apply()
        }
    }

    /**
     * Get an app's icon as raw PNG bytes.
     * Returns null if the icon can't be loaded.
     */
    fun getAppIconBytes(packageName: String): ByteArray? {
        return try {
            val icon = packageManager.getApplicationIcon(packageName)
            // Convert Drawable to Bitmap
            val bitmap = if (icon is android.graphics.drawable.BitmapDrawable) {
                icon.bitmap
            } else {
                val width = if (icon.intrinsicWidth > 0) icon.intrinsicWidth else 96
                val height = if (icon.intrinsicHeight > 0) icon.intrinsicHeight else 96
                val bmp = android.graphics.Bitmap.createBitmap(width, height, android.graphics.Bitmap.Config.ARGB_8888)
                val canvas = android.graphics.Canvas(bmp)
                icon.setBounds(0, 0, canvas.width, canvas.height)
                icon.draw(canvas)
                bmp
            }
            // Resize to 64x64 to keep data small
            val resized = android.graphics.Bitmap.createScaledBitmap(bitmap, 64, 64, true)
            // Compress to PNG bytes
            val stream = java.io.ByteArrayOutputStream()
            resized.compress(android.graphics.Bitmap.CompressFormat.PNG, 80, stream)
            stream.toByteArray()
        } catch (_: Exception) {
            null
        }
    }

    // ─── Public Helpers ───

    /**
     * Categorize an app by its package name using known mappings.
     * Public so UsageTrackerService can use it.
     */
    fun categorizeByPackageNamePublic(packageName: String): String {
        return categorizeByPackageName(packageName)
    }

    // ─── Private Helpers ───

    private fun categorizeApp(appInfo: ApplicationInfo, packageName: String): String {
        // Android's category system (API 26+):
        // CATEGORY_DEFAULT = 0, CATEGORY_GAME = 1, CATEGORY_AUDIO = 2,
        // CATEGORY_VIDEO = 3, CATEGORY_IMAGE = 4, CATEGORY_SOCIAL = 5,
        // CATEGORY_NEWS = 6, CATEGORY_MAPS = 7, CATEGORY_PRODUCTIVITY = 0(!)
        // PROBLEM: CATEGORY_PRODUCTIVITY == CATEGORY_DEFAULT == 0
        // So we MUST check specific non-zero categories first, then use package heuristics.

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val category = appInfo.category
            when (category) {
                ApplicationInfo.CATEGORY_SOCIAL -> return "social_media"
                ApplicationInfo.CATEGORY_VIDEO -> return "entertainment"
                ApplicationInfo.CATEGORY_GAME -> return "games"
                // Skip CATEGORY_PRODUCTIVITY (0) — it's the same as DEFAULT
                // Skip anything else that's 0 (default) — fall through to heuristics
            }
        }

        // Fallback: categorize by known package names (much more comprehensive)
        return categorizeByPackageName(packageName)
    }

    private fun categorizeByPackageName(packageName: String): String {
        val socialMediaPackages = setOf(
            // Meta
            "com.instagram.android", "com.facebook.katana", "com.facebook.lite",
            "com.facebook.orca", "com.facebook.adsmanager",
            // Twitter/X
            "com.twitter.android", "com.twitter.lite",
            // TikTok
            "com.zhiliaoapp.musically", "com.ss.android.ugc.trill",
            // Snapchat
            "com.snapchat.android",
            // LinkedIn
            "com.linkedin.android",
            // Pinterest
            "com.pinterest",
            // Reddit
            "com.reddit.frontpage", "com.reddit.frontpage.lite",
            // Discord
            "com.discord",
            // Telegram
            "com.telegram.messenger", "org.telegram.messenger",
            // WhatsApp
            "com.whatsapp", "com.whatsapp.w4b",
            // Viber
            "com.viber.voip",
            // Skype
            "com.skype.raider",
            // WeChat
            "com.tencent.mm",
            // Threads
            "com.instagram.threads",
            // BeReal
            "com.bereal.ft",
            // Mastodon
            "org.joinmastodon.android",
            // Bluesky
            "xyz.blueskyweb.app",
            // Tumblr
            "com.tumblr",
            // VK
            "com.vkontakte.android",
        )
        val entertainmentPackages = setOf(
            // Video
            "com.google.android.youtube", "com.google.android.apps.youtube.music",
            "com.netflix.mediaclient", "com.amazon.avod",
            "com.disney.disneyplus", "com.hbo.hbonow", "com.hbo.max",
            "com.peacocktv.peacockandroid", "com.apple.android.apps.tv.parsec",
            "com.hotstar.android", "com.zee5.android",
            // Music
            "com.spotify.music", "com.apple.android.music",
            "com.amazon.mp3", "com.soundcloud.android",
            "deezer.android.app", "com.gaana",
            // Short-form video
            "com.ss.android.ugc.aweme", // TikTok Chinese
            "com.kwai.video", "com.kwai.phone",
            // Streaming
            "com.twitch.android.app", "tv.twitch.android.app",
            "com.discovery.discoveryplus",
        )
        val gamePackages = setOf(
            "com.supercell.clashofclans", "com.supercell.clashroyale",
            "com.supercell.brawlstars", "com.supercell.hayday",
            "com.epicgames.fortnite", "com.mojang.minecraftpe",
            "com.activision.callofduty.shooter", "com.garena.game.codm",
            "com.mobile.legends", "com.riotgames.league.wildrift",
            "com.pubg.imobile", "com.tencent.ig",
            "com.dts.freefireth", "com.dts.freefiremax",
            "com.riotgames.league.teamfighttactics",
            "com.king.candycrushsaga", "com.king.candycrushsodasaga",
            "com.miniclip.eightballpool",
            "com.imangi.templerun2", "com.imangi.templerun",
            "com.outfit7.mytalkingtom2", "com.outfit7.talkingtom2",
            "com.fingersoft.hillclimb", "com.fingersoft.hillclimbracing",
            "com.ea.gp.fifamobile", "com.ea.game.pvzfree_row",
            "com.ubisoft.hungrysharkworld", "com.ubisoft.rainbowsixsiege",
            "com.roblox.client", "com.kiloo.subwaysurf",
            "com.gameloft.android.ANMP.GloftA9HM", // Asphalt 9
            "com.innersloth.spacemafia", // Among Us
            "com.amongus", "com.pewpewpew.space",
        )
        val socialMediaAIChat = setOf(
            // AI chatbots (some users want to block these)
            "com.openai.chatgpt", "com.openai",
            "com.microsoft.copilot",
            "com.google.android.apps.bard",
        )
        val productivityPackages = setOf(
            // Microsoft Office
            "com.microsoft.office.outlook", "com.microsoft.office.word",
            "com.microsoft.office.excel", "com.microsoft.office.powerpoint",
            "com.microsoft.office.onenote", "com.microsoft.office.onenote.copy",
            "com.microsoft.teams", "com.microsoft.americaonline",
            // Google Workspace
            "com.google.android.apps.docs", "com.google.android.apps.sheets",
            "com.google.android.apps.slides", "com.google.android.apps.docs.editors.docs",
            "com.google.android.apps.docs.editors.sheets",
            "com.google.android.apps.docs.editors.slides",
            "com.google.android.gm", // Gmail
            "com.google.android.calendar",
            // Notes & Task managers
            "com.notion.so", "com.notion.id", "com.trello",
            "com.asana", "com.todoist", "com.ticktick.task",
            "com.evernote", "com.evernote.android", "org.zeroxlab.snippet",
            // Cloud storage
            "com.google.android.apps.docs", "com.dropbox.android",
            "com.box.android", "com.microsoft.skydrive",
            "com.amazon.clouddrive.android",
            // Communication
            "com.slack", "us.zoom.videomeetings",
            "com.microsoft.teams", "com.amazon.chime",
            "com.google.android.apps.meetings",
            // Code editors
            "com.vscode", "com.github.deepthinker",
            // PDF
            "com.adobe.reader", "cn.wps.moffice_eng",
        )
        val educationPackages = setOf(
            "com.duolingo", "org.khanacademy", "com.udemy.android",
            "com.coursera.android", "com.quizlet.android",
            "com.kahoot.android", "com.google.android.apps.books",
            "com/google.android.apps.readaloud",
            "org.edx.android", "com.skillshare.android",
            "com.blinkist.android", "com.masterclass.android",
            "com.lingodeer", "com.memrise.android.memrise",
            "com.topcoder.android", "com.brainly",
        )
        val financePackages = setOf(
            "com.paypal.android.p2pmobile", "com.venmo",
            "com.cash.app", "com.zellepay.zell",
            "com.robinhood.android", "com.rbinance",
            "com.coinbase.android", "com.blockchain.android",
            "com.bankofamerica.cashpromobile",
            "com.chase.sig.android", "com.wellsfargo.mobile.android",
            "com.google.android.apps.walletnfcrel", // Google Pay
            "com.teslamotors.tesla", // Tesla app
        )
        val healthPackages = setOf(
            "com.nike.plusone", "com.nike.trainingclub",
            "com.strava", "com.myfitnesspal",
            "com.fitbit.FitbitMobile", "com.samsung.health",
            "com.google.android.apps.fitness",
            "com.calm", "com.headspace",
            "com.adidas", "com.underarmour",
        )
        val navigationPackages = setOf(
            "com.waze", "com.google.android.apps.maps",
            "com.uber.rider", "com.ubercab",
            "com.grabtaxi.passenger", "com.lyft",
        )
        val shoppingPackages = setOf(
            "com.amazon.mShop.android.shopping",
            "com.ebay.mobile", "com.shopee",
            "com.wish.android", "com.alibaba.aliexpresshd",
            "com.ASOS.ASOS", "com.Zalando",
            "com.nike", "com.adidas",
            "com.etsy.android", "com.bestbuy.android",
        )
        val newsPackages = setOf(
            "com.google.android.apps.magazines",
            "com.microsoft.office.news",
            "flipboard.app", "com.buzzfeed",
            "com.cnn.android", "com.bbc.news",
            "com.nytimes.android", "com.reuters",
        )

        // Check social media first (most commonly blocked)
        if (socialMediaPackages.any { packageName.contains(it, ignoreCase = true) }) return "social_media"
        if (entertainmentPackages.any { packageName.contains(it, ignoreCase = true) }) return "entertainment"
        if (gamePackages.any { packageName.contains(it, ignoreCase = true) }) return "games"
        if (socialMediaAIChat.any { packageName.contains(it, ignoreCase = true) }) return "social_media"
        if (productivityPackages.any { packageName.contains(it, ignoreCase = true) }) return "productivity"
        if (educationPackages.any { packageName.contains(it, ignoreCase = true) }) return "education"
        if (financePackages.any { packageName.contains(it, ignoreCase = true) }) return "finance"
        if (healthPackages.any { packageName.contains(it, ignoreCase = true) }) return "health"
        if (navigationPackages.any { packageName.contains(it, ignoreCase = true) }) return "navigation"
        if (shoppingPackages.any { packageName.contains(it, ignoreCase = true) }) return "shopping"
        if (newsPackages.any { packageName.contains(it, ignoreCase = true) }) return "news"

        return "other"
    }

    private fun getInstallTime(packageName: String): Long {
        return try {
            val packageInfo = packageManager.getPackageInfo(packageName, 0)
            packageInfo.firstInstallTime
        } catch (_: Exception) {
            0L
        }
    }

    private fun getUpdateTime(packageName: String): Long {
        return try {
            val packageInfo = packageManager.getPackageInfo(packageName, 0)
            packageInfo.lastUpdateTime
        } catch (_: Exception) {
            0L
        }
    }

    private fun getVersionName(packageName: String): String? {
        return try {
            val packageInfo = packageManager.getPackageInfo(packageName, 0)
            packageInfo.versionName
        } catch (_: Exception) {
            null
        }
    }

    private fun getUsageForPackage(packageName: String, sinceMillis: Long): Long {
        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            ?: return 0L

        val endTime = System.currentTimeMillis()
        val startTime = endTime - sinceMillis

        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY, startTime, endTime
        ) ?: return 0L

        return stats
            .filter { it.packageName == packageName }
            .sumOf { it.totalTimeInForeground }
    }
}
