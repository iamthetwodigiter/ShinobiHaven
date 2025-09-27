import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinobihaven/core/providers/update_provider.dart';
import 'package:shinobihaven/core/utils/update_checker.dart';
import 'package:shinobihaven/core/utils/toast.dart';
import 'package:toastification/toastification.dart';

enum NotificationChannel {
  downloads(
    'download_channel',
    'Downloads',
    'Notifications for download progress and completion',
  ),
  updates(
    'update_channel',
    'App Updates',
    'Notifications for app update status',
  ),
  general('general_channel', 'General', 'General app notifications'),
  episodes('episodes_channel', 'Episodes', 'Episode download notifications');

  const NotificationChannel(this.id, this.name, this.description);
  final String id;
  final String name;
  final String description;
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    if (Platform.isAndroid) {
      await Permission.notification.request();
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);

    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }

    _isInitialized = true;
  }

  static Future<void> _createNotificationChannels() async {
    for (final channel in NotificationChannel.values) {
      final androidChannel = AndroidNotificationChannel(
        channel.id,
        channel.name,
        description: channel.description,
        importance: Importance.high,
        enableVibration: true,
        showBadge: true,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(androidChannel);
    }
  }

  static Future<void> showProgressNotification({
    required int id,
    required String title,
    required String description,
    required NotificationChannel channel,
    int progress = 0,
    int maxProgress = 100,
    bool ongoing = true,
    bool showProgress = true,
    bool silent = false,
    String? payload,
    List<AndroidNotificationAction>? actions,
  }) async {
    await initialize();

    final androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: Importance.high,
      priority: Priority.high,
      ongoing: ongoing,
      autoCancel: !ongoing,
      showProgress: showProgress,
      maxProgress: maxProgress,
      progress: progress,
      icon: '@mipmap/ic_launcher',
      actions: actions,
      playSound: !silent,
      enableVibration: !silent,
      onlyAlertOnce: silent,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: !silent,
      presentBadge: true,
      presentSound: !silent,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      description,
      details,
      payload: payload,
    );
  }

  static Future<void> showSimpleNotification({
    required int id,
    required String title,
    required String description,
    required NotificationChannel channel,
    bool autoCancel = true,
    bool playSound = true,
    String? payload,
    List<AndroidNotificationAction>? actions,
  }) async {
    await initialize();

    final androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: Importance.high,
      priority: Priority.high,
      ongoing: false,
      autoCancel: autoCancel,
      showProgress: false,
      icon: '@mipmap/ic_launcher',
      actions: actions,
      playSound: playSound,
      enableVibration: playSound,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: playSound,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      description,
      details,
      payload: payload,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class NotificationIds {
  static const int updateDownload = 1001;
  static const int updateComplete = 1002;
  static const int updateFailed = 1003;
  static const int updateAvailable = 1004;

  static const int episodeDownload = 2001;
  static const int episodeComplete = 2002;
  static const int episodeFailed = 2003;

  static const int generalInfo = 3001;
  static const int generalWarning = 3002;
  static const int generalError = 3003;
}

extension NotificationServiceExtensions on NotificationService {
  static Future<void> showDownloadStarted({
    required int id,
    required String itemName,
    required NotificationChannel channel,
  }) async {
    await NotificationService.showProgressNotification(
      id: id,
      title: 'Download Started',
      description: 'Downloading $itemName...',
      channel: channel,
      progress: 0,
      ongoing: true,
      silent: false,
      payload: 'download_started:$itemName',
    );
  }

  static Future<void> updateDownloadProgress({
    required int id,
    required String itemName,
    required NotificationChannel channel,
    required int progress,
  }) async {
    await NotificationService.showProgressNotification(
      id: id,
      title: 'Downloading',
      description: 'Downloading $itemName... $progress%',
      channel: channel,
      progress: progress,
      ongoing: true,
      silent: true,
      payload: 'download_progress:$itemName:$progress',
    );
  }

  static Future<void> showDownloadCompleted({
    required int id,
    required String itemName,
    required NotificationChannel channel,
    String? actionText,
    String? actionId,
    String? filePath,
    int? progressNotificationId,
  }) async {
    if (progressNotificationId != null) {
      await NotificationService.cancelNotification(progressNotificationId);
    }

    final actions = actionText != null && actionId != null
        ? [
            AndroidNotificationAction(
              actionId,
              actionText,
              showsUserInterface: true,
              cancelNotification: false,
            ),
          ]
        : null;

    await NotificationService.showSimpleNotification(
      id: id,
      title: 'Download Complete',
      description: '$itemName is ready! Tap to install.',
      channel: channel,
      actions: actions,
      playSound: true,
      payload: filePath != null
          ? 'download_complete:$filePath'
          : 'download_complete:$itemName',
    );
  }

  static Future<void> showDownloadFailed({
    required int id,
    required String itemName,
    required NotificationChannel channel,
    String? error,
    int? progressNotificationId,
  }) async {
    if (progressNotificationId != null) {
      await NotificationService.cancelNotification(progressNotificationId);
    }

    await NotificationService.showSimpleNotification(
      id: id,
      title: 'Download Failed',
      description:
          'Failed to download $itemName${error != null ? ': $error' : ''}',
      channel: channel,
      playSound: true,
      payload: 'download_failed:$itemName',
    );
  }

  static Future<void> showUpdateAvailable({required String version}) async {
    await NotificationService.showSimpleNotification(
      id: NotificationIds.updateAvailable,
      title: 'Update Available',
      description: 'ShinobiHaven $version is available for download!',
      channel: NotificationChannel.updates,
      payload: 'update_available:$version',
      actions: [
        AndroidNotificationAction(
          'update',
          'Update Now',
          showsUserInterface: true,
          cancelNotification: false,
        ),
        AndroidNotificationAction(
          'later',
          'Later',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );
  }
}

class NotificationHandler {
  static Future<void> handleNotificationAction(
    BuildContext context,
    WidgetRef ref,
    String? payload,
    String? actionId,
  ) async {
    if (payload == null) return;

    if (payload.startsWith('update_available:')) {
      final version = payload.split(':')[1];
      await _handleUpdateAvailable(context, ref, version, actionId);
    } else if (payload.startsWith('update_details:')) {
      final version = payload.split(':')[1];
      await _handleUpdateDetails(context, ref, version, actionId);
    }
  }

  static Future<void> _handleUpdateAvailable(
    BuildContext context,
    WidgetRef ref,
    String version,
    String? actionId,
  ) async {
    switch (actionId) {
      case 'update':
      case 'install_now':
        await UpdateChecker.checkForUpdates(context, showNoUpdateDialog: false);
        break;

      case 'later':
      case 'dismiss':
        await ref.read(updateSettingsProvider.notifier).dismissUpdate(version);
        if (context.mounted) {
          Toast(
            context: context,
            title: 'Update Dismissed',
            description: 'You won\'t be notified about this version again',
            type: ToastificationType.info,
          );
        }
        break;

      default:
        await UpdateChecker.checkForUpdates(context, showNoUpdateDialog: false);
        break;
    }
  }

  static Future<void> _handleUpdateDetails(
    BuildContext context,
    WidgetRef ref,
    String version,
    String? actionId,
  ) async {
    switch (actionId) {
      case 'install_now':
        await UpdateChecker.checkForUpdates(context, showNoUpdateDialog: false);
        break;

      case 'view_changes':
        await UpdateChecker.checkForUpdates(context, showNoUpdateDialog: false);
        break;

      case 'dismiss':
        await ref.read(updateSettingsProvider.notifier).dismissUpdate(version);
        break;

      default:
        await UpdateChecker.checkForUpdates(context, showNoUpdateDialog: false);
        break;
    }
  }
}
