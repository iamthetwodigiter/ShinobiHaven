import 'package:flutter/material.dart';
import 'package:shinobihaven/core/theme/app_theme.dart';
import 'package:shinobihaven/core/services/notification_service.dart';

import 'package:shinobihaven/features/download/model/download_task.dart';

class OngoingDownloads extends StatelessWidget {
  final int taskId;
  final String animeTitle;
  final String episodeNumber;
  final int progress;
  final int received;
  final int? total;
  final double speed;
  final int displayedSpeedBytesPerSec;
  final int? etaSec;
  final DownloadStatus status;
  final String? error;
  final VoidCallback? onCancel;

  const OngoingDownloads({
    super.key,
    required this.taskId,
    required this.animeTitle,
    required this.episodeNumber,
    required this.progress,
    required this.received,
    required this.total,
    required this.speed,
    required this.displayedSpeedBytesPerSec,
    this.etaSec,
    this.status = DownloadStatus.downloading,
    this.error,
    this.onCancel,
  });

  String _formatEta(int? seconds) {
    if (seconds == null || seconds <= 0) return '--';
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) {
      final m = seconds ~/ 60;
      final s = seconds % 60;
      return '${m}m ${s}s';
    }
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor = AppTheme.gradient1;
    String statusText = '';

    if (status == DownloadStatus.queued) {
      statusColor = Colors.grey;
      statusText = 'Queued';
    } else if (status == DownloadStatus.failed) {
      statusColor = Colors.red;
      statusText = error != null && error!.contains('Cancelled')
          ? 'Cancelled'
          : 'Failed: ${error ?? 'Unknown error'}';
    } else if (status == DownloadStatus.completed) {
      statusColor = AppTheme.primaryGreen;
      statusText = 'Completed';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: status == DownloadStatus.failed
              ? Colors.red.withAlpha(50)
              : Colors.white.withAlpha(20),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  status == DownloadStatus.failed
                      ? (error != null && error!.contains('Cancelled')
                            ? Icons.block_flipped
                            : Icons.error_outline_rounded)
                      : (status == DownloadStatus.queued
                            ? Icons.timer_outlined
                            : Icons.downloading_rounded),
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      animeTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Episode $episodeNumber',
                      style: TextStyle(
                        color: Colors.white.withAlpha(150),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (status == DownloadStatus.downloading ||
                  status == DownloadStatus.queued)
                IconButton(
                  onPressed: onCancel,
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white70,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              else if (status == DownloadStatus.failed)
                IconButton(
                  onPressed:
                      onCancel, // Reuse onCancel to remove the item from UI
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.white70,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              if (status == DownloadStatus.downloading) ...[
                const SizedBox(width: 8),
                Text(
                  '$progress%',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (status == DownloadStatus.downloading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (progress.clamp(0, 100)) / 100.0,
                backgroundColor: Colors.white.withAlpha(20),
                color: statusColor,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${NotificationService.formatFileSize(received)} / ${total != null ? NotificationService.formatFileSize(total!) : 'Unknown'}',
                  style: TextStyle(
                    color: Colors.white.withAlpha(150),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${speed > 0 ? '${NotificationService.formatFileSize(displayedSpeedBytesPerSec)}/s' : '—'} • ${_formatEta(etaSec)}',
                  style: TextStyle(
                    color: Colors.white.withAlpha(150),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ] else if (statusText.isNotEmpty)
            Text(
              statusText,
              style: TextStyle(
                color: statusColor.withAlpha(200),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}
