import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shinobihaven/core/constants/app_details.dart';
import 'package:shinobihaven/core/services/notification_service.dart';
import 'package:shinobihaven/features/download/model/download_task.dart';
import 'package:shinobihaven/features/download/repository/downloads_repository.dart';
import 'package:ffmpeg_kit_flutter_new_https/ffmpeg_kit_config.dart';

@pragma('vm:entry-point')
class DownloadBackgroundService {
  @pragma('vm:entry-point')
  static Future<void> initialize() async {
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: NotificationChannel.downloads.id,
        initialNotificationTitle: 'ShinobiHaven',
        initialNotificationContent: 'Background Download Service Initiated',
        foregroundServiceTypes: [AndroidForegroundType.dataSync],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    // Explicitly start the service if it's not running
    if (!await service.isRunning()) {
      await service.startService();
    }
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    // Initialize dependencies in the background isolate
    try {
      await AppDetails.init();
      await Hive.initFlutter(Platform.isAndroid ? null : AppDetails.basePath);
      await NotificationService.initialize(isBackground: true);
      // Initialize FFmpegKit for this isolate
      if (Platform.isAndroid || Platform.isIOS) {
        FFmpegKitConfig.init();
      }
    } catch (e) {
      debugPrint('Error initializing background service: $e');
    }

    final repository = DownloadsRepository();

    service.on('start_download').listen((event) async {
      if (event == null) return;

      try {
        final taskJson = event['task'] as Map<String, dynamic>;
        final task = DownloadTask.fromJson(taskJson);

        await repository.downloadFile(
          task: task,
          onProgress: (received, total, speed) {
            service.invoke('progress_update', {
              'id': task.id,
              'received': received,
              'total': total,
              'speed': speed,
            });
          },
          onComplete: () {
            service.invoke('download_complete', {'id': task.id});
          },
          onError: (error) {
            service.invoke('download_error', {'id': task.id, 'error': error});
          },
          onSubtitleSaved: (lang, path) {
            service.invoke('subtitle_saved', {
              'id': task.id,
              'language': lang,
              'path': path,
            });
          },
        );
      } catch (e) {
        debugPrint('Error starting download in background: $e');
        service.invoke('download_error', {
          'id': (event['task'] as Map)['id'],
          'error': e.toString(),
        });
      }
    });

    service.on('stop_service').listen((event) {
      service.stopSelf();
    });
  }
}
