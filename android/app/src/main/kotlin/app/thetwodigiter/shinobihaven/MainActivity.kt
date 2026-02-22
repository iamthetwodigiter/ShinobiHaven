package app.thetwodigiter.shinobihaven

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent

class MainActivity : FlutterActivity() {
    companion object {
        private var channel: MethodChannel? = null
        private const val CHANNEL_NAME = "app.thetwodigiter.shinobihaven/download"

        fun sendEvent(method: String, arguments: Map<String, Any?>) {
            android.os.Handler(android.os.Looper.getMainLooper()).post {
                channel?.invokeMethod(method, arguments)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        
        handleIntent(intent)
        
        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startDownload" -> {
                    val animeTitle = call.argument<String>("animeTitle")
                    val episodeNumber = call.argument<String>("episodeNumber")
                    val url = call.argument<String>("url")
                    val savePath = call.argument<String>("savePath")
                    val taskId = call.argument<String>("taskId")
                    val totalDuration = call.argument<Double>("totalDuration") ?: 0.0

                    val intent = Intent(this, DownloadService::class.java).apply {
                        action = DownloadService.ACTION_START
                        putExtra("animeTitle", animeTitle)
                        putExtra("episodeNumber", episodeNumber)
                        putExtra("url", url)
                        putExtra("savePath", savePath)
                        putExtra("taskId", taskId)
                        putExtra("totalDuration", totalDuration)
                    }
                    
                    startServiceCompatible(intent)
                    result.success(true)
                }
                "cancelDownload" -> {
                    val taskId = call.argument<String>("taskId")
                    val intent = Intent(this, DownloadService::class.java).apply {
                        action = DownloadService.ACTION_STOP
                        putExtra("taskId", taskId)
                    }
                    startServiceCompatible(intent)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent?.action == "OPEN_DOWNLOADS") {
            sendEvent("notification_tapped", emptyMap())
        }
    }

    private fun startServiceCompatible(intent: Intent) {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    override fun onDestroy() {
        channel = null
        super.onDestroy()
    }
}
