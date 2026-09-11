package com.nora.nora_app

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.text.TextUtils
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	companion object {
		const val PREFERENCES_NAME = "nora_focus_protection"
		const val BLOCKING_ENABLED_KEY = "blocking_enabled"
		const val BLOCKED_PACKAGES_KEY = "blocked_packages"
		val DEFAULT_BLOCKED_PACKAGES = setOf(
			"com.instagram.android",
			"com.facebook.katana",
			"com.twitter.android",
			"com.linkedin.android",
			"com.google.android.youtube",
			"com.zhiliaoapp.musically",
		)
	}

	private val channelName = "com.nora.nora_app/focus_protection"
	private val scannerChannel = "com.nora.nora_app/app_scanner"
	private val usageChannel = "com.nora.nora_app/usage_tracker"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		// ─── Focus Protection Channel ───
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"getStatus" -> result.success(focusProtectionStatus())
					"requestAuthorization" -> {
						startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
						result.success(focusProtectionStatus())
					}
					"openSettings" -> {
						startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
						result.success(null)
					}
					"selectApps" -> {
						getSharedPreferences(PREFERENCES_NAME, MODE_PRIVATE)
							.edit()
							.putStringSet(BLOCKED_PACKAGES_KEY, DEFAULT_BLOCKED_PACKAGES)
							.apply()
						startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
						result.success(focusProtectionStatus())
					}
					"setBlockedPackages" -> {
						val packages = (call.arguments as? List<*>)
							?.filterIsInstance<String>()
							?.filter { it.isNotBlank() }
							?.toSet()
							?: emptySet()
						getSharedPreferences(PREFERENCES_NAME, MODE_PRIVATE)
							.edit()
							.putStringSet(BLOCKED_PACKAGES_KEY, packages)
							.apply()
						result.success(focusProtectionStatus())
					}
					"enableBlocking" -> {
						getSharedPreferences(PREFERENCES_NAME, MODE_PRIVATE)
							.edit()
							.putBoolean(BLOCKING_ENABLED_KEY, true)
							.apply()
						result.success(focusProtectionStatus())
					}
					"disableBlocking" -> {
						getSharedPreferences(PREFERENCES_NAME, MODE_PRIVATE)
							.edit()
							.putBoolean(BLOCKING_ENABLED_KEY, false)
							.apply()
						result.success(focusProtectionStatus())
					}
					else -> result.notImplemented()
				}
			}

		// ─── App Scanner Channel ───
		val appScanner = AppScannerService(this)
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, scannerChannel)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"scanAllApps" -> {
						val apps = appScanner.scanAllApps()
						result.success(mapOf("success" to true, "apps" to apps, "count" to apps.size))
					}
					"getAppDetails" -> {
						val packageName = call.arguments as? String
						if (packageName != null) {
							val details = appScanner.getAppDetails(packageName)
							if (details != null) {
								result.success(mapOf("success" to true, "app" to details))
							} else {
								result.success(mapOf("success" to false, "error" to "App not found"))
							}
						} else {
							result.success(mapOf("success" to false, "error" to "Package name required"))
						}
					}
					"getBlockedApps" -> {
						val blocked = appScanner.getBlockedApps()
						result.success(mapOf("success" to true, "blockedApps" to blocked.toList()))
					}
					"setBlockedApps" -> {
						val packages = (call.arguments as? List<*>)
							?.filterIsInstance<String>()
							?.filter { it.isNotBlank() }
							?.toSet()
							?: emptySet()
						appScanner.setBlockedApps(packages)
						result.success(mapOf("success" to true, "blockedApps" to packages.toList()))
					}
					"addToBlocked" -> {
						val packages = (call.arguments as? List<*>)
							?.filterIsInstance<String>()
							?.filter { it.isNotBlank() }
							?.toSet()
							?: emptySet()
						appScanner.addToBlockedApps(packages)
						val blocked = appScanner.getBlockedApps()
						result.success(mapOf("success" to true, "blockedApps" to blocked.toList()))
					}
					"removeFromBlocked" -> {
						val packages = (call.arguments as? List<*>)
							?.filterIsInstance<String>()
							?.filter { it.isNotBlank() }
							?.toSet()
							?: emptySet()
						appScanner.removeFromBlockedApps(packages)
						val blocked = appScanner.getBlockedApps()
						result.success(mapOf("success" to true, "blockedApps" to blocked.toList()))
					}
					"getAppIcon" -> {
						val packageName = call.arguments as? String
						if (packageName != null) {
							val iconBase64 = appScanner.getAppIconBase64(packageName)
							result.success(mapOf("success" to true, "icon" to iconBase64))
						} else {
							result.success(mapOf("success" to false, "error" to "Package name required"))
						}
					}
					else -> result.notImplemented()
				}
			}

		// ─── Usage Tracker Channel ───
		val usageTracker = UsageTrackerService(this)
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, usageChannel)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"getUsageStats" -> {
						val daysBack = (call.arguments as? Int) ?: 7
						val stats = usageTracker.getUsageStats(daysBack)
						result.success(stats)
					}
					"getTodayUsage" -> {
						val stats = usageTracker.getTodayUsage()
						result.success(stats)
					}
					"getAppUsage" -> {
						val args = call.arguments as? Map<*, *>
						val packageName = args?.get("packageName") as? String
						val daysBack = args?.get("daysBack") as? Int ?: 7
						if (packageName != null) {
							val usage = usageTracker.getAppUsage(packageName, daysBack)
							result.success(usage)
						} else {
							result.success(mapOf("success" to false, "error" to "Package name required"))
						}
					}
					else -> result.notImplemented()
				}
			}
	}

	private fun focusProtectionStatus(): Map<String, Any> {
		val usageAccessGranted = hasUsageAccess()
		val preferences = getSharedPreferences(PREFERENCES_NAME, MODE_PRIVATE)
		val accessibilityGranted = isAccessibilityServiceEnabled()
		val blockingEnabled = preferences.getBoolean(BLOCKING_ENABLED_KEY, false)
		val blockedPackages = preferences.getStringSet(BLOCKED_PACKAGES_KEY, emptySet()) ?: emptySet()
		return mapOf(
			"supported" to true,
			"authorized" to (accessibilityGranted && blockingEnabled),
			"usageAccessGranted" to usageAccessGranted,
			"accessibilityGranted" to accessibilityGranted,
			"blockingEnabled" to blockingEnabled,
			"blockedPackages" to blockedPackages.toList(),
			"message" to if (accessibilityGranted && blockingEnabled) {
				"Nora is blocking the selected apps during focus mode."
			} else if (accessibilityGranted) {
				"Accessibility is enabled. Turn on blocking to protect selected apps."
			} else {
				"Enable Nora Focus Protection in Android Accessibility settings before blocking apps."
			},
		)
	}

	private fun isAccessibilityServiceEnabled(): Boolean {
		val enabledServices = Settings.Secure.getString(
			contentResolver,
			Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
		) ?: return false
		val expected = "$packageName/${FocusBlockingAccessibilityService::class.java.name}"
		return enabledServices.split(':').any { TextUtils.equals(it, expected) }
	}

	private fun hasUsageAccess(): Boolean {
		val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
		val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
			appOps.unsafeCheckOpNoThrow(
				AppOpsManager.OPSTR_GET_USAGE_STATS,
				android.os.Process.myUid(),
				packageName,
			)
		} else {
			@Suppress("DEPRECATION")
			appOps.checkOpNoThrow(
				AppOpsManager.OPSTR_GET_USAGE_STATS,
				android.os.Process.myUid(),
				packageName,
			)
		}
		return mode == AppOpsManager.MODE_ALLOWED
	}
}
