import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:shinobihaven/core/theme/app_theme.dart';

class DownloadedEpisodeTile extends StatelessWidget {
  final String filePath;
  final String fileName;
  final String? title;
  final String? episodeNumber;
  final String size;
  const DownloadedEpisodeTile({
    super.key,
    required this.filePath,
    required this.fileName,
    this.title,
    this.episodeNumber,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: AppTheme.blackGradient,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppTheme.gradient1.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(child: Icon(Icons.play_arrow, color: AppTheme.gradient1)),
      ),
      title: Text(
        title ?? fileName,
        style: TextStyle(color: AppTheme.whiteGradient),
      ),
      subtitle: Text(
        '${episodeNumber ?? ''} • $size',
        style: TextStyle(color: AppTheme.whiteGradient.withValues(alpha: 0.7)),
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (v) async {
          if (v == 'open') {
            await OpenFile.open(filePath);
          } else if (v == 'delete') {
            try {
              final f = File(filePath);
              if (f.existsSync()) f.deleteSync();
              Navigator.of(context).pop();
            } catch (_) {}
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(value: 'open', child: Text('Open')),
          PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
      onTap: () async {
        await OpenFile.open(filePath);
      },
    );
  }
}
