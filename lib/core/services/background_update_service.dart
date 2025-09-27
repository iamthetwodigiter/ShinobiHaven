import 'dart:async';
import 'dart:math';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shinobihaven/core/constants/app_details.dart';
import 'package:shinobihaven/core/utils/notification_service.dart';
import 'package:shinobihaven/core/utils/update_checker.dart';

class BackgroundUpdateService {
  static const String _updateBoxName = 'update_settings';
  static const String _lastCheckKey = 'last_update_check';
  static const String _dismissedVersionKey = 'dismissed_update_version';
  static const String _checkIntervalKey = 'update_check_interval_hours';
  static const String _autoCheckEnabledKey = 'auto_check_enabled';
  static const String _failureCountKey = 'failure_count';
  static const String _lastFailureKey = 'last_failure_time';
  
  static const int defaultCheckIntervalHours = 12;
  static const int minCheckIntervalHours = 6;
  static const int maxCheckIntervalHours = 72;
  static const int maxFailureCount = 3;
  
  static Timer? _periodicTimer;
  static bool _isChecking = false;
  static Box? _updateBox;
  
  static Future<void> initialize() async {
    if (!Hive.isBoxOpen(_updateBoxName)) {
      _updateBox = await Hive.openBox(_updateBoxName);
    } else {
      _updateBox = Hive.box(_updateBoxName);
    }
    
    if (!_updateBox!.containsKey(_autoCheckEnabledKey)) {
      await _updateBox!.put(_autoCheckEnabledKey, true);
    }
    if (!_updateBox!.containsKey(_checkIntervalKey)) {
      await _updateBox!.put(_checkIntervalKey, defaultCheckIntervalHours);
    }
    if (!_updateBox!.containsKey(_failureCountKey)) {
      await _updateBox!.put(_failureCountKey, 0);
    }
    
    final isEnabled = _updateBox!.get(_autoCheckEnabledKey, defaultValue: true);
    
    if (isEnabled) {
      await _scheduleNextCheck();
      _startPeriodicChecking();
    }
  }
  
  static void _startPeriodicChecking() {
    _periodicTimer?.cancel();
    
    _periodicTimer = Timer.periodic(Duration(hours: 1), (timer) async {
      if (_updateBox == null) return;
      
      final isEnabled = _updateBox!.get(_autoCheckEnabledKey, defaultValue: true);
      
      if (!isEnabled) {
        timer.cancel();
        return;
      }
      
      if (_shouldCheckForUpdates()) {
        await _performBackgroundCheck();
      }
    });
  }
  
  static bool _shouldCheckForUpdates() {
    if (_updateBox == null) return false;
    
    final lastCheck = _updateBox!.get(_lastCheckKey, defaultValue: 0);
    final interval = _updateBox!.get(_checkIntervalKey, defaultValue: defaultCheckIntervalHours);
    final failureCount = _updateBox!.get(_failureCountKey, defaultValue: 0);
    final lastFailure = _updateBox!.get(_lastFailureKey, defaultValue: 0);
    final now = DateTime.now().millisecondsSinceEpoch;
    
    num adjustedInterval = interval;
    if (failureCount > 0) {
      adjustedInterval = (interval * math.pow(2, failureCount.clamp(0, 3))).toInt();
      adjustedInterval = adjustedInterval.clamp(interval, maxCheckIntervalHours);
      
      if ((now - lastFailure) < (2 * 60 * 60 * 1000)) {
        return false;
      }
    }
    
    return (now - lastCheck) >= (adjustedInterval * 60 * 60 * 1000);
  }
  
  static Future<void> _performBackgroundCheck() async {
    if (_isChecking || _updateBox == null) return;
    _isChecking = true;
    
    try {
      final latestRelease = await UpdateChecker.getLatestRelease();
      
      await _updateBox!.put(_lastCheckKey, DateTime.now().millisecondsSinceEpoch);
      
      if (latestRelease != null) {
        final currentVersion = AppDetails.version;
        final latestVersion = latestRelease.tagName;
        
        final comparison = UpdateChecker.compareVersions(currentVersion, latestVersion);
        
        if (comparison < 0) {
          final dismissedVersion = _updateBox!.get(_dismissedVersionKey);
          
          if (dismissedVersion != latestVersion) {
            await _showUpdateNotification(latestVersion, latestRelease.body);
          }
        }
      }
      
      await _updateBox!.put(_failureCountKey, 0);
      
      await _scheduleNextCheck();
      
    } catch (e) {
      debugPrint('Background update check failed: $e');
      await _handleCheckFailure();
    } finally {
      _isChecking = false;
    }
  }
  
  static Future<void> _handleCheckFailure() async {
    if (_updateBox == null) return;
    
    final currentFailures = _updateBox!.get(_failureCountKey, defaultValue: 0);
    final newFailureCount = (currentFailures + 1).clamp(0, maxFailureCount);
    
    await _updateBox!.put(_failureCountKey, newFailureCount);
    await _updateBox!.put(_lastFailureKey, DateTime.now().millisecondsSinceEpoch);
    
    await _scheduleRetry();
  }
  
  static Future<void> _showUpdateNotification(String version, String releaseNotes) async {
    await NotificationService.cancelNotification(NotificationIds.updateAvailable);
    
    await NotificationServiceExtensions.showUpdateAvailable(version: version);
    
    final shortNotes = _extractShortReleaseNotes(releaseNotes);
    
    await NotificationService.showSimpleNotification(
      id: NotificationIds.updateAvailable + 1,
      title: 'ShinobiHaven $version Available!',
      description: shortNotes.isNotEmpty ? shortNotes : 'New features and improvements available',
      channel: NotificationChannel.updates,
      payload: 'update_details:$version',
      actions: [
        AndroidNotificationAction(
          'install_now',
          'Install Now',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'view_changes',
          "What's New",
          showsUserInterface: true,
          cancelNotification: false,
        ),
        AndroidNotificationAction(
          'dismiss',
          'Dismiss',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );
  }
  
  static String _extractShortReleaseNotes(String notes) {
    if (notes.isEmpty) return '';
    
    final lines = notes
        .replaceAll('**', '')
        .replaceAll('##', '')
        .replaceAll('###', '')
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .take(3)
        .toList();
    
    if (lines.isEmpty) return '';
    
    final preview = lines.join(' • ');
    return preview.length > 100 ? '${preview.substring(0, 97)}...' : preview;
  }
  
  static Future<void> _scheduleNextCheck() async {
    if (_updateBox == null) return;
    
    final baseInterval = _updateBox!.get(_checkIntervalKey, defaultValue: defaultCheckIntervalHours);
    
    final random = Random();
    final randomOffset = random.nextInt(4) - 2;
    final actualInterval = (baseInterval + randomOffset).clamp(minCheckIntervalHours, maxCheckIntervalHours);
    
    final nextCheckTime = DateTime.now().add(Duration(hours: actualInterval));
    await _updateBox!.put(_lastCheckKey, nextCheckTime.millisecondsSinceEpoch - (actualInterval * 60 * 60 * 1000));
  }
  
  static Future<void> _scheduleRetry() async {
    if (_updateBox == null) return;
    
    final failureCount = _updateBox!.get(_failureCountKey, defaultValue: 0);
    final retryHours = (2 * math.pow(2, failureCount.clamp(0, 3))).toInt().clamp(2, 24);
    
    final retryTime = DateTime.now().add(Duration(hours: retryHours));
    await _updateBox!.put(_lastCheckKey, retryTime.millisecondsSinceEpoch - (retryHours * 60 * 60 * 1000));
  }
  
  static Future<bool> checkForUpdatesNow() async {
    if (_isChecking || _updateBox == null) return false;
    
    await _updateBox!.put(_lastCheckKey, 0);
    await _updateBox!.put(_failureCountKey, 0);
    
    await _performBackgroundCheck();
    return true;
  }
  
  static Future<void> dismissUpdate(String version) async {
    if (_updateBox == null) return;
    
    await _updateBox!.put(_dismissedVersionKey, version);
    
    await NotificationService.cancelNotification(NotificationIds.updateAvailable);
    await NotificationService.cancelNotification(NotificationIds.updateAvailable + 1);
  }
  
  static Future<void> setCheckInterval(int hours) async {
    if (_updateBox == null) return;
    
    final clampedHours = hours.clamp(minCheckIntervalHours, maxCheckIntervalHours);
    await _updateBox!.put(_checkIntervalKey, clampedHours);
  }
  
  static Future<void> setAutoCheckEnabled(bool enabled) async {
    if (_updateBox == null) return;
    
    await _updateBox!.put(_autoCheckEnabledKey, enabled);
    
    if (enabled) {
      _startPeriodicChecking();
    } else {
      _periodicTimer?.cancel();
    }
  }
  
  static Map<String, dynamic> getSettings() {
    if (_updateBox == null) return {};
    
    return {
      'enabled': _updateBox!.get(_autoCheckEnabledKey, defaultValue: true),
      'interval': _updateBox!.get(_checkIntervalKey, defaultValue: defaultCheckIntervalHours),
      'lastCheck': _updateBox!.get(_lastCheckKey, defaultValue: 0),
      'dismissedVersion': _updateBox!.get(_dismissedVersionKey),
      'failureCount': _updateBox!.get(_failureCountKey, defaultValue: 0),
      'lastFailure': _updateBox!.get(_lastFailureKey, defaultValue: 0),
    };
  }
  
  static DateTime? getNextCheckTime() {
    if (_updateBox == null) return null;
    
    final lastCheck = _updateBox!.get(_lastCheckKey, defaultValue: 0);
    final interval = _updateBox!.get(_checkIntervalKey, defaultValue: defaultCheckIntervalHours);
    
    if (lastCheck == 0) return null;
    
    return DateTime.fromMillisecondsSinceEpoch(lastCheck + (interval * 60 * 60 * 1000));
  }
  
  static void dispose() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }
}