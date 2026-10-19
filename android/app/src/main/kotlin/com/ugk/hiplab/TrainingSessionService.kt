package com.ugk.hiplab

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.Log

/**
 * Keeps a training session (player / hip check) running while the app is in
 * the background or the screen is locked (Android voice fix, 2026-10-19).
 *
 * Without it a backgrounded HipLab is an ordinary cached process: it is put
 * in the background CPU group (little cores, low CPU share), the device may
 * suspend between two voice lines, and on Android 15+ an app that is neither
 * the top app nor running a foreground service is refused audio focus
 * (AUDIOFOCUS_REQUEST_FAILED) – every coaching line asks for it. Battery
 * whitelisting and auto-start do not change any of that.
 *
 * A `mediaPlayback` foreground service lifts the process to foreground-service
 * priority and holds a partial wake lock so the session clock and the voice
 * keep their timing. It does not play audio itself (just_audio does) and shows
 * one low-importance ongoing notification. Started from Dart over the
 * `hiplab/training_session` channel when a session page opens, stopped when it
 * closes; also stopped with the task.
 */
class TrainingSessionService : Service() {
    private var wakeLock: PowerManager.WakeLock? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Always enter the foreground first: a service started with
        // startForegroundService must call startForeground even when the
        // request that reached it is a stop.
        try {
            val notification = buildNotification()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK,
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (e: Exception) {
            Log.w(TAG, "startForeground failed", e)
            stopSelf()
            return START_NOT_STICKY
        }
        if (intent?.action == ACTION_STOP) {
            finish()
            return START_NOT_STICKY
        }
        acquireWakeLock()
        Log.i(TAG, "training session service started")
        return START_NOT_STICKY
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        finish()
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        releaseWakeLock()
        running = false
        Log.i(TAG, "training session service stopped")
        super.onDestroy()
    }

    private fun finish() {
        releaseWakeLock()
        stopForeground(STOP_FOREGROUND_REMOVE) // minSdk 24
        stopSelf()
    }

    private fun acquireWakeLock() {
        if (wakeLock?.isHeld == true) return
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "hiplab:training").apply {
            setReferenceCounted(false)
            // Safety cap: a session never lasts this long; the lock is
            // released when the session page closes.
            acquire(WAKE_LOCK_CAP_MS)
        }
    }

    private fun releaseWakeLock() {
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
    }

    private fun buildNotification(): Notification {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if (manager.getNotificationChannel(CHANNEL_ID) == null) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    "训练进行中",
                    NotificationManager.IMPORTANCE_LOW,
                ).apply {
                    description = "训练或自测进行时保持计时和语音指导"
                    setShowBadge(false)
                }
                manager.createNotificationChannel(channel)
            }
        }
        val open = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pending = open?.let {
            PendingIntent.getActivity(
                this,
                0,
                it,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        return builder
            .setSmallIcon(R.mipmap.ic_launcher_monochrome)
            .setContentTitle("开胯训练进行中")
            .setContentText("锁屏或切到后台时，计时和语音会继续")
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setCategory(Notification.CATEGORY_SERVICE)
            .apply { if (pending != null) setContentIntent(pending) }
            .build()
    }

    companion object {
        private const val TAG = "HipTrainingService"
        private const val CHANNEL_ID = "training_session"
        private const val NOTIFICATION_ID = 4107
        private const val ACTION_STOP = "com.ugk.hiplab.action.STOP_TRAINING_SESSION"
        private const val WAKE_LOCK_CAP_MS = 3L * 60 * 60 * 1000

        @Volatile
        private var running = false

        /** True when the request reached the system. */
        fun start(context: Context): Boolean {
            val intent = Intent(context, TrainingSessionService::class.java)
            return try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
                running = true
                true
            } catch (e: Exception) {
                // e.g. ForegroundServiceStartNotAllowedException when asked
                // from the background; the session still runs in the
                // foreground as before.
                Log.w(TAG, "could not start training session service", e)
                false
            }
        }

        fun stop(context: Context) {
            if (!running) return
            running = false
            val intent = Intent(context, TrainingSessionService::class.java)
                .setAction(ACTION_STOP)
            try {
                // Routed through onStartCommand so a service that has not
                // reached startForeground yet still does so before stopping.
                context.startService(intent)
            } catch (e: Exception) {
                context.stopService(Intent(context, TrainingSessionService::class.java))
            }
        }
    }
}
