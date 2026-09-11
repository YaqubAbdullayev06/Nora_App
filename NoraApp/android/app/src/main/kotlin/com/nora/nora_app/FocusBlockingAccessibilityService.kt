package com.nora.nora_app

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.view.accessibility.AccessibilityEvent

class FocusBlockingAccessibilityService : AccessibilityService() {
    private var lastBlockedPackage: String? = null
    private var lastBlockedAt = 0L

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED &&
            event?.eventType != AccessibilityEvent.TYPE_WINDOWS_CHANGED
        ) {
            return
        }

        val packageName = event.packageName?.toString() ?: return
        val preferences = getSharedPreferences(MainActivity.PREFERENCES_NAME, MODE_PRIVATE)
        if (!preferences.getBoolean(MainActivity.BLOCKING_ENABLED_KEY, false)) return

        val blockedPackages = preferences.getStringSet(MainActivity.BLOCKED_PACKAGES_KEY, emptySet()) ?: emptySet()
        if (packageName == this.packageName || packageName !in blockedPackages) return

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

    override fun onInterrupt() = Unit
}
