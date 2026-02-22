package app.thetwodigiter.shinobihaven

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import com.antonkarpenko.ffmpegkit.FFmpegKit
import com.antonkarpenko.ffmpegkit.ReturnCode
import com.antonkarpenko.ffmpegkit.FFmpegKitConfig
import com.antonkarpenko.ffmpegkit.FFmpegSession
import com.antonkarpenko.ffmpegkit.Statistics
import com.antonkarpenko.ffmpegkit.Log
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import java.io.File

class DownloadService : Service() {
    private val CHANNEL_ID = "downloads_channel"
    private val NOTIFICATION_ID = 1001
    
    private var lastUpdateSize = 0L
    private var lastUpdateTime = 0L
    private var currentSpeed = 0.0

    companion object {
        const val ACTION_START = "ACTION_START"
        const val ACTION_STOP = "ACTION_STOP"
        private var currentSessionId: Long? = null
        
        fun stopCurrentDownload() {
            currentSessionId?.let {
                FFmpegKit.cancel(it)
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action ?: ACTION_START

        if (action == ACTION_STOP) {
            val taskId = intent?.getStringExtra("taskId") ?: ""
            stopCurrentDownload()
            notifyFlutter("download_error", mapOf("taskId" to taskId, "error" to "Cancelled by user"))
            stopForeground(true)
            val manager = getSystemService(NotificationManager::class.java)
            manager.cancel(NOTIFICATION_ID)
            stopSelf()
            return START_NOT_STICKY
        }

        val animeTitle = intent?.getStringExtra("animeTitle") ?: "Anime"
        val episodeNumber = intent?.getStringExtra("episodeNumber") ?: ""
        val url = intent?.getStringExtra("url") ?: ""
        val savePath = intent?.getStringExtra("savePath") ?: ""
        val taskId = intent?.getStringExtra("taskId") ?: ""
        val totalDuration = intent?.getDoubleExtra("totalDuration", 0.0) ?: 0.0

        val notification = createNotification(animeTitle, "Starting download...", 0, taskId)
        startForeground(NOTIFICATION_ID, notification)

        if (url.isNotEmpty() && savePath.isNotEmpty()) {
            startDownload(animeTitle, episodeNumber, url, savePath, taskId, totalDuration)
        } else {
            stopSelf()
        }

        return START_NOT_STICKY
    }

    private fun startDownload(animeTitle: String, episodeNumber: String, url: String, savePath: String, taskId: String, totalDuration: Double) {
        val cmd = "-y -protocol_whitelist file,http,https,tcp,tls -i \"$url\" -map 0 -bsf:a aac_adtstoasc -c copy \"$savePath\""

        val session = FFmpegKit.executeAsync(cmd, { session: FFmpegSession ->
            val returnCode = session.getReturnCode()
            currentSessionId = null

            if (ReturnCode.isSuccess(returnCode)) {
                notifyFlutter("download_complete", mapOf("taskId" to taskId))
                showCompletionNotification(animeTitle, "Episode $episodeNumber download completed", true)
            } else if (ReturnCode.isCancel(returnCode)) {
                 // Already handled
            } else {
                notifyFlutter("download_error", mapOf("taskId" to taskId, "error" to "FFmpeg failed with return code $returnCode"))
                showCompletionNotification(animeTitle, "Episode $episodeNumber download failed", false)
            }
            
            stopForeground(true)
            val manager = getSystemService(NotificationManager::class.java)
            manager.cancel(NOTIFICATION_ID)
            stopSelf()
        }, { log: Log ->
            // Optionally logs
        }, { statistics: Statistics ->
            val size = statistics.getSize() // in bytes
            val timeMs = statistics.getTime()
            
            // Calculate instantaneous speed
            val now = System.currentTimeMillis()
            val timeDelta = now - lastUpdateTime
            var speedBytesPerSec = 0.0
            
            if (timeDelta >= 500) { // Update speed every 500ms
                val sizeDelta = size - lastUpdateSize
                speedBytesPerSec = (sizeDelta.toDouble() / timeDelta.toDouble()) * 1000.0
                
                lastUpdateSize = size
                lastUpdateTime = now
                currentSpeed = speedBytesPerSec
            } else {
                speedBytesPerSec = currentSpeed
            }
            
            var progress = 0.0
            if (totalDuration > 0) {
                progress = (timeMs / (totalDuration * 1000.0)).coerceIn(0.0, 1.0)
            }

            // Estimate total size based on progress
            val estimatedTotal = if (progress > 0.01) {
                (size / progress).toLong()
            } else {
                0L
            }

            val progressInt = (progress * 100).toInt()
            val content = if (totalDuration > 0) {
                "Downloading Episode $episodeNumber: $progressInt% (${formatSize(size)})"
            } else {
                "Downloading Episode $episodeNumber: ${formatSize(size)}"
            }

            updateNotification(animeTitle, content, null, if (totalDuration > 0) progressInt else -1, taskId)
            
            notifyFlutter("download_progress", mapOf(
                "taskId" to taskId,
                "received" to size,
                "total" to estimatedTotal,
                "speed" to speedBytesPerSec,
                "progress" to progress
            ))
        })
        
        currentSessionId = session.getSessionId()
    }

    private fun showCompletionNotification(title: String, content: String, isSuccess: Boolean) {
        val manager = getSystemService(NotificationManager::class.java)
        val completionId = 2000 + (title.hashCode() % 1000)
        
        val notifyIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            action = "OPEN_DOWNLOADS"
        }
        val notifyPendingIntent = PendingIntent.getActivity(
            this, 2, notifyIntent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(content)
            .setSmallIcon(if (isSuccess) android.R.drawable.stat_sys_download_done else android.R.drawable.stat_notify_error)
            .setAutoCancel(true)
            .setOngoing(false)
            .setContentIntent(notifyPendingIntent)

        manager.notify(completionId, builder.build())
    }

    private fun formatSize(bytes: Long): String {
        if (bytes <= 0) return "0 B"
        if (bytes < 1024) return "$bytes B"
        if (bytes < 1024 * 1024) return String.format("%.1f KB", bytes / 1024.0)
        return String.format("%.1f MB", bytes / (1024.0 * 1024.0))
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "Downloads Channel",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }

    private fun createNotification(title: String, content: String, progress: Int, taskId: String): Notification {
        val stopIntent = Intent(this, DownloadService::class.java).apply {
            action = ACTION_STOP
            putExtra("taskId", taskId)
        }
        val stopPendingIntent = PendingIntent.getService(this, 0, stopIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

        val notifyIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            action = "OPEN_DOWNLOADS"
        }
        val notifyPendingIntent = PendingIntent.getActivity(
            this, 1, notifyIntent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(content)
            .setSmallIcon(android.R.drawable.stat_sys_download)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Cancel", stopPendingIntent)
            .setContentIntent(notifyPendingIntent)
            
        if (progress >= 0) {
            builder.setProgress(100, progress, false)
        } else {
            builder.setProgress(0, 0, true)
        }
        
        return builder.build()
    }

    private fun updateNotification(title: String, content: String, isSuccess: Boolean?, progress: Int, taskId: String) {
        val manager = getSystemService(NotificationManager::class.java)
        
        val stopIntent = Intent(this, DownloadService::class.java).apply {
            action = ACTION_STOP
            putExtra("taskId", taskId)
        }
        val stopPendingIntent = PendingIntent.getService(this, 10, stopIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

        val notifyIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            action = "OPEN_DOWNLOADS"
        }
        val notifyPendingIntent = PendingIntent.getActivity(
            this, 1, notifyIntent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(content)
            .setSmallIcon(if (isSuccess == true) android.R.drawable.stat_sys_download_done else android.R.drawable.stat_sys_download)
            .setOngoing(isSuccess == null)
            .setOnlyAlertOnce(true)
            .setContentIntent(notifyPendingIntent)

        if (isSuccess == null) {
            builder.addAction(android.R.drawable.ic_menu_close_clear_cancel, "Cancel", stopPendingIntent)
            if (progress >= 0) {
                builder.setProgress(100, progress, false)
            } else {
                builder.setProgress(0, 0, true)
            }
        }

        manager.notify(NOTIFICATION_ID, builder.build())
    }

    private fun notifyFlutter(method: String, arguments: Map<String, Any?>) {
        MainActivity.sendEvent(method, arguments)
    }
}
