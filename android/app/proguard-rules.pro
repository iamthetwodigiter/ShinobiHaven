-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.engine.plugins.** { *; }
-keep class io.flutter.embedding.engine.** { *; }

-keep class com.baseflow.permissionhandler.** { *; }

-keep class com.arthenica.** { *; }
-keep class com.arthenica.ffmpegkit.** { *; }
-keep class org.ffmpeg.** { *; }

-keep class dev.flutter.pigeon.** { *; }
-keep class com.**pathprovider** { *; }

-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task