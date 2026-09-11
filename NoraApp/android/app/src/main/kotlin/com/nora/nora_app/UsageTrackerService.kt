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
