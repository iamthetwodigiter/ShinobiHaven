import 'package:flutter/material.dart';
import 'package:shinobihaven/core/theme/app_theme.dart';
import 'package:shinobihaven/core/services/notification_service.dart';

class OngoingDownloads extends StatelessWidget {
  final String animeTitle;
  final String episodeNumber;
  final int progress;
  final int received;
  final int? total;
  final double speed;
  final int displayedSpeedBytesPerSec;
  final int? etaSec;
  const OngoingDownloads({
    super.key,
    required this.animeTitle,
    required this.episodeNumber,
    required this.progress,
    required this.received,
    required this.total,
    required this.speed,
    required this.displayedSpeedBytesPerSec,
    this.etaSec,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.downloading, color: AppTheme.gradient1),
      title: Text(
        '$animeTitle • Ep $episodeNumber',
        style: TextStyle(color: AppTheme.whiteGradient),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: (progress.clamp(0, 100)) / 100.0,
            color: AppTheme.gradient1,
          ),
          SizedBox(height: 6),
          Text(
            '${NotificationService.formatFileSize(received)} / ${total != null ? NotificationService.formatFileSize(total!) : 'Unknown'} • ${speed > 0 ? '${NotificationService.formatFileSize(displayedSpeedBytesPerSec)}/s' : '—'} • ${etaSec != null ? '${etaSec}s left' : '--'}',
            style: TextStyle(
              color: AppTheme.whiteGradient.withAlpha(180),
              fontSize: 12,
            ),
          ),
        ],
      ),
      trailing: Text('$progress%'),
    );
  }
}
