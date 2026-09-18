package com.nora.nora_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder

/**
 * FocusProtectionForegroundService — Keeps a persistent notification alive
 * while app blocking is active.  Android may kill an accessibility service
 * under memory pressure; a foreground-service notification tells the user
 * that protection has dropped if the process dies.
 */
class FocusProtectionForegroundService : Service() {

    companion object {
        private const val CHANNEL_ID = "nora_focus_protection"
        private const val NOTIFICATION_ID = 7777
        private const val ACTION_START = "com.nora.nora_app.action.START_PROTECTION"
        private const val ACTION_STOP = "com.nora.nora_app.action.STOP_PROTECTION"

        fun start(context: Context) {
            val intent = Intent(context, FocusProtectionForegroundService::class.java).apply {
                action = ACTION_START
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            val intent = Intent(context, FocusProtectionForegroundService::class.java).apply {
                action = ACTION_STOP
            }
            context.startService(intent)
        }

        fun isRunning(): Boolean = _isRunning
        private var _isRunning = false
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                _isRunning = true
                startForeground(NOTIFICATION_ID, buildNotification())
            }
            ACTION_STOP -> {
                _isRunning = false
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
            else -> {
                // Default: treat as start
                _isRunning = true
                startForeground(NOTIFICATION_ID, buildNotification())
            }
        }
        return START_STICKY
    }

    override fun onDestroy() {
        _isRunning = false
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Focus Protection",
                NotificationManager.IMPORTANCE_LOW,  // No sound, just visible
            ).apply {
                description = "Shows when app blocking is active"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        // Tapping the notification opens the main activity
        val openIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingOpen = PendingIntent.getActivity(
            this, 0, openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        return Notification.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentTitle("Nora Focus Protection")
            .setContentText("App blocking is active")
            .setOngoing(true)
            .setContentIntent(pendingOpen)
            .setCategory(Notification.CATEGORY_SERVICE)
            .build()
    }
}
