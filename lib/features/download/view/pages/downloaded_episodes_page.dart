import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:shinobihaven/core/theme/app_theme.dart';
import 'package:shinobihaven/features/download/view/widgets/downloaded_episode_tile.dart';

class DownloadedEpisodesPage extends StatelessWidget {
  final String animeTitle;
  final List<Map<String, dynamic>> episodes;

  const DownloadedEpisodesPage({
    super.key,
    required this.animeTitle,
    required this.episodes,
  });

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final sorted = List<Map<String, dynamic>>.from(episodes)
      ..sort((a, b) {
        final an = (a['episodeNumber'] ?? '').toString();
        final bn = (b['episodeNumber'] ?? '').toString();
        return an.compareTo(bn);
      });

    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlack,
        title: Text(animeTitle, style: TextStyle(color: AppTheme.gradient1)),
      ),
      body: ListView.separated(
        padding: EdgeInsets.all(12),
        itemCount: sorted.length,
        separatorBuilder: (_, __) => SizedBox(height: 8),
        itemBuilder: (context, i) {
          final e = sorted[i];
          final filePath = e['filePath'] as String;
          final fileName = p.basename(filePath);
          final size =
              (e['size'] as int?) ??
              (File(filePath).existsSync() ? File(filePath).lengthSync() : 0);
          return DownloadedEpisodeTile(
            filePath: filePath,
            fileName: fileName,
            title: (e['title'] as String?),
            episodeNumber: (e['episodeNumber'] as String?),
            size: _formatSize(size),
          );
        },
      ),
    );
  }
}
