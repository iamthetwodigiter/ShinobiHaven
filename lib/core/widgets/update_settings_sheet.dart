import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinobihaven/core/providers/update_provider.dart';
import 'package:shinobihaven/core/theme/app_theme.dart';
import 'package:shinobihaven/core/utils/toast.dart';
import 'package:toastification/toastification.dart';

class UpdateSettingsSheet extends ConsumerStatefulWidget {
  const UpdateSettingsSheet({super.key});

  @override
  ConsumerState<UpdateSettingsSheet> createState() =>
      _UpdateSettingsSheetState();
}

class _UpdateSettingsSheetState extends ConsumerState<UpdateSettingsSheet> {
  late bool _autoCheckEnabled;
  late double _checkInterval;
  bool _isCheckingNow = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(updateSettingsProvider);
    _autoCheckEnabled = settings.autoCheckEnabled;
    _checkInterval = settings.checkIntervalHours.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(updateSettingsProvider);
    final lastCheckText = ref.watch(formattedLastCheckProvider);
    final nextCheckText = ref.watch(formattedNextCheckProvider);

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.blackGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.greyGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 20),

          Text(
            'Update Settings',
            style: TextStyle(
              color: AppTheme.whiteGradient,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),

          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryBlack,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.gradient1.withValues(alpha: 0.3),
              ),
            ),
            child: SwitchListTile(
              title: Text(
                'Auto-check for updates',
                style: TextStyle(color: AppTheme.whiteGradient),
              ),
              subtitle: Text(
                'Automatically check for new releases in background',
                style: TextStyle(
                  color: AppTheme.whiteGradient.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
              value: _autoCheckEnabled,
              activeThumbColor: AppTheme.whiteGradient,
              activeTrackColor: AppTheme.gradient1,
              onChanged: (value) {
                setState(() {
                  _autoCheckEnabled = value;
                });
              },
            ),
          ),

          if (_autoCheckEnabled) ...[
            SizedBox(height: 20),

            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlack,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.gradient1.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Check interval: ${_checkInterval.toInt()} hours',
                    style: TextStyle(
                      color: AppTheme.whiteGradient,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'How often to check for updates',
                    style: TextStyle(
                      color: AppTheme.whiteGradient.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 12),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppTheme.gradient1,
                      inactiveTrackColor: AppTheme.gradient1.withValues(
                        alpha: 0.3,
                      ),
                      thumbColor: AppTheme.gradient1,
                      overlayColor: AppTheme.gradient1.withValues(alpha: 0.2),
                    ),
                    child: Slider(
                      value: _checkInterval,
                      min: 1,
                      max: 24,
                      divisions: 23,
                      label: '${_checkInterval.toInt()}h',
                      onChanged: (value) {
                        setState(() {
                          _checkInterval = value;
                        });
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '1h',
                        style: TextStyle(
                          color: AppTheme.whiteGradient.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '24h',
                        style: TextStyle(
                          color: AppTheme.whiteGradient.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 20),

          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.gradient1.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.gradient1.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.gradient1,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        lastCheckText,
                        style: TextStyle(
                          color: AppTheme.whiteGradient,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                if (settings.autoCheckEnabled) ...[
                  SizedBox(height: 4),
                  Text(
                    nextCheckText,
                    style: TextStyle(
                      color: AppTheme.whiteGradient.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
                if (settings.failureCount > 0) ...[
                  SizedBox(height: 4),
                  Text(
                    'Recent check failures: ${settings.failureCount}',
                    style: TextStyle(color: Colors.orange, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.gradient1),
                foregroundColor: AppTheme.gradient1,
              ),
              onPressed: _isCheckingNow ? null : _checkForUpdatesNow,
              icon: _isCheckingNow
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.gradient1,
                      ),
                    )
                  : Icon(Icons.refresh),
              label: Text(_isCheckingNow ? 'Checking...' : 'Check Now'),
            ),
          ),

          SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppTheme.gradient1),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.gradient1,
                    foregroundColor: AppTheme.whiteGradient,
                  ),
                  onPressed: _saveSettings,
                  child: Text('Save'),
                ),
              ),
            ],
          ),

          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  void _checkForUpdatesNow() async {
    setState(() {
      _isCheckingNow = true;
    });

    try {
      final success = await ref
          .read(updateSettingsProvider.notifier)
          .checkForUpdatesNow();

      if (mounted) {
        Toast(
          context: context,
          title: success ? 'Update Check Complete' : 'Update Check Failed',
          description: success
              ? 'Checked for updates successfully'
              : 'Failed to check for updates. Try again later.',
          type: success ? ToastificationType.success : ToastificationType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingNow = false;
        });
      }
    }
  }

  void _saveSettings() async {
    await ref
        .read(updateSettingsProvider.notifier)
        .setAutoCheckEnabled(_autoCheckEnabled);
    await ref
        .read(updateSettingsProvider.notifier)
        .setCheckInterval(_checkInterval.toInt());

    if (mounted) {
      Navigator.pop(context);
      Toast(
        context: context,
        title: 'Settings Saved',
        description: 'Update preferences have been saved successfully',
        type: ToastificationType.success,
      );
    }
  }
}
