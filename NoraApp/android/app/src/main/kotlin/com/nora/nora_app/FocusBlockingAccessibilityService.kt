package com.nora.nora_app

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.content.SharedPreferences
import android.view.accessibility.AccessibilityEvent

class FocusBlockingAccessibilityService : AccessibilityService() {
    private var lastBlockedPackage: String? = null
    private var lastBlockedAt = 0L
    private var blockingEnabled = false
    private val blockedApps = mutableSetOf<String>()
    private var preferences: SharedPreferences? = null
    private var preferenceListener: SharedPreferences.OnSharedPreferenceChangeListener? = null

    override fun onServiceConnected() {
        super.onServiceConnected()
        preferences = getSharedPreferences(MainActivity.PREFERENCES_NAME, MODE_PRIVATE)
        syncFromPreferences()
        preferenceListener = SharedPreferences.OnSharedPreferenceChangeListener { _, _ ->
            syncFromPreferences()
        }
        preferences?.registerOnSharedPreferenceChangeListener(preferenceListener)
    }

    private fun syncFromPreferences() {
        val prefs = preferences ?: return
        blockingEnabled = prefs.getBoolean(MainActivity.BLOCKING_ENABLED_KEY, false)
        blockedApps.clear()
        prefs.getStringSet(MainActivity.BLOCKED_PACKAGES_KEY, emptySet())?.let { blockedApps.addAll(it) }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val packageName = event.packageName?.toString() ?: return
        if (!blockingEnabled) return
        if (packageName == this.packageName || packageName !in blockedApps) return

        val now = System.currentTimeMillis()
        if (packageName == lastBlockedPackage && now - lastBlockedAt < 1000) return
        lastBlockedPackage = packageName
        lastBlockedAt = now

        startActivity(
            Intent(this, BlockedAppActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                .putExtra(BlockedAppActivity.BLOCKED_PACKAGE_EXTRA, packageName),
        )
    }

    override fun onDestroy() {
        preferences?.unregisterOnSharedPreferenceChangeListener(preferenceListener)
        preferenceListener = null
        super.onDestroy()
    }

    override fun onInterrupt() = Unit
}
