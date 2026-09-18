package com.nora.nora_app

import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import java.util.Calendar
import java.util.concurrent.TimeUnit

/**
 * UsageTrackerService — Tracks detailed app usage statistics.
 * Provides per-app usage data for AI analysis and smart blocking decisions.
 */
class UsageTrackerService(private val context: Context) {

    private val packageManager: PackageManager = context.packageManager

    /**
     * Get detailed usage stats for all user apps.
     * Returns sorted by most used (descending).
     */
    fun getUsageStats(daysBack: Int = 7): Map<String, Any> {
        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            ?: return mapOf("success" to false, "error" to "UsageStatsManager not available")

        val calendar = Calendar.getInstance()
        val endTime = calendar.timeInMillis
        calendar.add(Calendar.DAY_OF_YEAR, -daysBack)
        val startTime = calendar.timeInMillis

        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY, startTime, endTime
        ) ?: return mapOf("success" to false, "error" to "No usage data available")

        val appUsages = stats
            .filter { it.totalTimeInForeground > 0 }
            .mapNotNull { stat ->
                try {
                    val appInfo = packageManager.getApplicationInfo(stat.packageName, 0)
                    val isSystem = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                    if (isSystem) return@mapNotNull null

                    val appName = packageManager.getApplicationLabel(appInfo).toString()
                    val category = AppScannerService(context).categorizeByPackageNamePublic(stat.packageName)

                    mapOf(
                        "packageName" to stat.packageName,
                        "appName" to appName,
                        "totalTimeMinutes" to TimeUnit.MILLISECONDS.toMinutes(stat.totalTimeInForeground).toInt(),
                        "lastTimeUsed" to stat.lastTimeUsed,
                        "category" to category,
                    )
                } catch (_: Exception) {
                    null
                }
            }
            .sortedByDescending { it["totalTimeMinutes"] as Int }

        val totalTime = appUsages.sumOf { it["totalTimeMinutes"] as Int }
        val socialMediaTime = appUsages
            .filter { it["category"] == "social_media" }
            .sumOf { it["totalTimeMinutes"] as Int }
        val entertainmentTime = appUsages
            .filter { it["category"] == "entertainment" }
            .sumOf { it["totalTimeMinutes"] as Int }
        val productivityTime = appUsages
            .filter { it["category"] == "productivity" }
            .sumOf { it["totalTimeMinutes"] as Int }

        return mapOf(
            "success" to true,
            "daysBack" to daysBack,
            "totalScreenTimeMinutes" to totalTime,
            "socialMediaMinutes" to socialMediaTime,
            "entertainmentMinutes" to entertainmentTime,
            "productivityMinutes" to productivityTime,
            "appCount" to appUsages.size,
            "apps" to appUsages.take(50), // Top 50 apps
        )
    }

    /**
     * Get per-day top app usage for the current week (Mon–Sun).
     * Returns a list of 7 entries, one per day. Days in the future have empty data.
     */
    fun getWeeklyAppUsage(): Map<String, Any> {
        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            ?: return mapOf("success" to false, "error" to "UsageStatsManager not available")

        val calendar = Calendar.getInstance()
        // End of today
        val endTime = calendar.timeInMillis
        // Start of Monday this week
        calendar.set(Calendar.DAY_OF_WEEK, Calendar.MONDAY)
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        val startTime = calendar.timeInMillis

        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY, startTime, endTime
        ) ?: return mapOf("success" to false, "error" to "No usage data available")

        val appScanner = AppScannerService(context)
        val now = Calendar.getInstance()
        val todayWeekday = now.get(Calendar.DAY_OF_WEEK)
        // Convert Java Calendar.MONDAY=2 … SUNDAY=1 to 0=Mon … 6=Sun
        val todayIndex = (todayWeekday + 5) % 7

        // Group stats by day index
        val dayBuckets = List(7) { mutableMapOf<String, Int>() } // packageName -> minutes

        for (stat in stats) {
            if (stat.totalTimeInForeground <= 0) continue
            // Determine which day this stat belongs to
            val statCal = Calendar.getInstance().apply { timeInMillis = stat.lastTimeUsed }
            val statDayOfWeek = statCal.get(Calendar.DAY_OF_WEEK)
            val dayIndex = (statDayOfWeek + 5) % 7

            // Only include Mon–today
            if (dayIndex > todayIndex) continue

            val minutes = TimeUnit.MILLISECONDS.toMinutes(stat.totalTimeInForeground).toInt()
            dayBuckets[dayIndex][stat.packageName] =
                (dayBuckets[dayIndex][stat.packageName] ?: 0) + minutes
        }

        // Build result: for each day, pick the top app
        val result = mutableListOf<Map<String, Any>>()
        for (i in 0 until 7) {
            if (i > todayIndex) {
                // Future day
                result.add(mapOf(
                    "dayIndex" to i,
                    "appName" to "",
                    "minutes" to 0,
                    "category" to "",
                ))
                continue
            }

            val bucket = dayBuckets[i]
            if (bucket.isEmpty()) {
                result.add(mapOf(
                    "dayIndex" to i,
                    "appName" to "",
                    "minutes" to 0,
                    "category" to "",
                ))
                continue
            }

            // Find the package with the most usage
            val topEntry = bucket.entries.maxByOrNull { it.value }!!
            val packageName = topEntry.key
            val minutes = topEntry.value

            var appName: String
            var category: String
            try {
                val appInfo = packageManager.getApplicationInfo(packageName, 0)
                appName = packageManager.getApplicationLabel(appInfo).toString()
                category = appScanner.categorizeByPackageNamePublic(packageName)
            } catch (_: Exception) {
                appName = packageName
                category = "other"
            }

            result.add(mapOf(
                "dayIndex" to i,
                "appName" to appName,
                "minutes" to minutes,
                "category" to category,
            ))
        }

        return mapOf(
            "success" to true,
            "days" to result,
        )
    }

    /**
     * Get today's usage summary.
     */
    fun getTodayUsage(): Map<String, Any> {
        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            ?: return mapOf("success" to false, "error" to "UsageStatsManager not available")

        val calendar = Calendar.getInstance()
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        val startTime = calendar.timeInMillis
        val endTime = System.currentTimeMillis()

        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY, startTime, endTime
        ) ?: return mapOf("success" to false, "error" to "No usage data available")

        val appUsages = stats
            .filter { it.totalTimeInForeground > 0 }
            .mapNotNull { stat ->
                try {
                    val appInfo = packageManager.getApplicationInfo(stat.packageName, 0)
                    val isSystem = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                    if (isSystem) return@mapNotNull null

                    val appName = packageManager.getApplicationLabel(appInfo).toString()
                    val category = AppScannerService(context).categorizeByPackageNamePublic(stat.packageName)

                    mapOf(
                        "packageName" to stat.packageName,
                        "appName" to appName,
                        "totalTimeMinutes" to TimeUnit.MILLISECONDS.toMinutes(stat.totalTimeInForeground).toInt(),
                        "lastTimeUsed" to stat.lastTimeUsed,
                        "category" to category,
                    )
                } catch (_: Exception) {
                    null
                }
            }
            .sortedByDescending { it["totalTimeMinutes"] as Int }

        val totalTime = appUsages.sumOf { it["totalTimeMinutes"] as Int }
        val socialMediaTime = appUsages
            .filter { it["category"] == "social_media" }
            .sumOf { it["totalTimeMinutes"] as Int }

        return mapOf(
            "success" to true,
            "totalScreenTimeMinutes" to totalTime,
            "socialMediaMinutes" to socialMediaTime,
            "appCount" to appUsages.size,
            "apps" to appUsages.take(30),
        )
    }

    /**
     * Get usage for a specific app.
     */
    fun getAppUsage(packageName: String, daysBack: Int = 7): Map<String, Any> {
        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            ?: return mapOf("success" to false, "error" to "UsageStatsManager not available")

        val calendar = Calendar.getInstance()
        val endTime = calendar.timeInMillis
        calendar.add(Calendar.DAY_OF_YEAR, -daysBack)
        val startTime = calendar.timeInMillis

        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY, startTime, endTime
        ) ?: return mapOf("success" to false, "error" to "No usage data available")

        val appStats = stats.filter { it.packageName == packageName }
        val totalTime = appStats.sumOf { it.totalTimeInForeground }
        val dailyBreakdown = appStats.map { stat ->
            mapOf(
                "date" to stat.lastTimeUsed,
                "minutes" to TimeUnit.MILLISECONDS.toMinutes(stat.totalTimeInForeground).toInt(),
            )
        }

        val appName = try {
            val appInfo = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(appInfo).toString()
        } catch (_: Exception) {
            packageName
        }

        return mapOf(
            "success" to true,
            "packageName" to packageName,
            "appName" to appName,
            "totalMinutes" to TimeUnit.MILLISECONDS.toMinutes(totalTime).toInt(),
            "daysBack" to daysBack,
            "dailyBreakdown" to dailyBreakdown,
        )
    }
}
