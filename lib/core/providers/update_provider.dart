import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinobihaven/core/services/background_update_service.dart';

class UpdateSettings {
  final bool autoCheckEnabled;
  final int checkIntervalHours;
  final int lastCheck;
  final String? dismissedVersion;
  final int failureCount;
  final DateTime? nextCheckTime;

  UpdateSettings({
    required this.autoCheckEnabled,
    required this.checkIntervalHours,
    required this.lastCheck,
    this.dismissedVersion,
    required this.failureCount,
    this.nextCheckTime,
  });

  UpdateSettings copyWith({
    bool? autoCheckEnabled,
    int? checkIntervalHours,
    int? lastCheck,
    String? dismissedVersion,
    int? failureCount,
    DateTime? nextCheckTime,
  }) {
    return UpdateSettings(
      autoCheckEnabled: autoCheckEnabled ?? this.autoCheckEnabled,
      checkIntervalHours: checkIntervalHours ?? this.checkIntervalHours,
      lastCheck: lastCheck ?? this.lastCheck,
      dismissedVersion: dismissedVersion ?? this.dismissedVersion,
      failureCount: failureCount ?? this.failureCount,
      nextCheckTime: nextCheckTime ?? this.nextCheckTime,
    );
  }
}

class UpdateSettingsNotifier extends StateNotifier<UpdateSettings> {
  UpdateSettingsNotifier() : super(UpdateSettings(
    autoCheckEnabled: true,
    checkIntervalHours: 12,
    lastCheck: 0,
    failureCount: 0,
  )) {
    _loadSettings();
  }

  void _loadSettings() {
    final settings = BackgroundUpdateService.getSettings();
    state = UpdateSettings(
      autoCheckEnabled: settings['enabled'] ?? true,
      checkIntervalHours: settings['interval'] ?? 12,
      lastCheck: settings['lastCheck'] ?? 0,
      dismissedVersion: settings['dismissedVersion'],
      failureCount: settings['failureCount'] ?? 0,
      nextCheckTime: BackgroundUpdateService.getNextCheckTime(),
    );
  }

  Future<void> setAutoCheckEnabled(bool enabled) async {
    await BackgroundUpdateService.setAutoCheckEnabled(enabled);
    state = state.copyWith(autoCheckEnabled: enabled);
  }

  Future<void> setCheckInterval(int hours) async {
    await BackgroundUpdateService.setCheckInterval(hours);
    state = state.copyWith(
      checkIntervalHours: hours,
      nextCheckTime: BackgroundUpdateService.getNextCheckTime(),
    );
  }

  Future<void> dismissUpdate(String version) async {
    await BackgroundUpdateService.dismissUpdate(version);
    state = state.copyWith(dismissedVersion: version);
  }

  Future<bool> checkForUpdatesNow() async {
    final success = await BackgroundUpdateService.checkForUpdatesNow();
    if (success) {
      _loadSettings();
    }
    return success;
  }

  void refreshSettings() {
    _loadSettings();
  }
}

final updateSettingsProvider = StateNotifierProvider<UpdateSettingsNotifier, UpdateSettings>((ref) {
  return UpdateSettingsNotifier();
});

final updateCheckStatusProvider = StateProvider<bool>((ref) => false);

final formattedLastCheckProvider = Provider<String>((ref) {
  final settings = ref.watch(updateSettingsProvider);
  
  if (settings.lastCheck == 0) {
    return 'Never checked for updates';
  }
  
  final lastCheckDate = DateTime.fromMillisecondsSinceEpoch(settings.lastCheck);
  final now = DateTime.now();
  final difference = now.difference(lastCheckDate);
  
  if (difference.inMinutes < 60) {
    return 'Last checked ${difference.inMinutes} minutes ago';
  } else if (difference.inHours < 24) {
    return 'Last checked ${difference.inHours} hours ago';
  } else {
    return 'Last checked ${difference.inDays} days ago';
  }
});

final formattedNextCheckProvider = Provider<String>((ref) {
  final settings = ref.watch(updateSettingsProvider);
  
  if (settings.nextCheckTime == null) {
    return 'Next check: Unknown';
  }
  
  final nextCheck = settings.nextCheckTime!;
  final now = DateTime.now();
  
  if (nextCheck.isBefore(now)) {
    return 'Next check: Due now';
  }
  
  final difference = nextCheck.difference(now);
  
  if (difference.inHours < 1) {
    return 'Next check: In ${difference.inMinutes} minutes';
  } else if (difference.inHours < 24) {
    return 'Next check: In ${difference.inHours} hours';
  } else {
    return 'Next check: In ${difference.inDays} days';
  }
});