import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinobihaven/features/anime/stream/model/sources.dart';
import 'package:shinobihaven/features/download/model/download_task.dart';
import 'package:shinobihaven/features/download/repository/downloads_repository.dart';

class DownloadsNotifier extends StateNotifier<List<DownloadTask>> {
  late final DownloadsRepository _repo;

  DownloadsNotifier() : super([]) {
    _repo = DownloadsRepository();
  }

  int _nextId = Random().nextInt(1000000);
  
  int _generateId() => _nextId++;

  Future<void> startDownload({
    required String animeSlug,
    required String animeTitle,
    required String episodeId,
    required String episodeNumber,
    required String title,
    required String serverId,
    required String url,
    required String? posterUrl,
    required List<Captions> captions,
  }) async {
    final id = _generateId();
    final subs = captions
        .map((c) => DownloadedSubtitle(language: c.language, url: c.link))
        .toList();

    final task = DownloadTask(
      id: id,
      animeSlug: animeSlug,
      animeTitle: animeTitle,
      episodeId: episodeId,
      episodeNumber: episodeNumber,
      title: title,
      serverId: serverId,
      url: url,
      posterUrl: posterUrl,
      subtitles: subs,
      status: DownloadStatus.queued,
      progress: 0.0,
    );

    state = [...state, task];

    _repo.downloadFile(
      task: task,
      onProgress: (received, total, speed) {
        _updateTask(
          id,
          bytesReceived: received,
          totalBytes: total,
          speedBytesPerSec: speed,
          progress: total != null && total > 0
              ? (received / total)
              : (received > 0 ? 0.5 : 0.0),
          status: DownloadStatus.downloading,
        );
      },
      onSubtitleSaved: (language, localPath) {
        final existing = state.firstWhere((t) => t.id == id);
        final updatedSubs = existing.subtitles
            .map(
              (s) =>
                  s.language == language ? s.copyWith(localPath: localPath) : s,
            )
            .toList();
        _updateTask(id, subtitles: updatedSubs);
      },
      onComplete: () {
        _updateTask(id, progress: 1.0, status: DownloadStatus.completed);
      },
      onError: (err) {
        _updateTask(id, status: DownloadStatus.failed, error: err);
      },
    );
  }

  void _updateTask(
    int id, {
    String? filePath,
    double? progress,
    int? bytesReceived,
    int? totalBytes,
    double? speedBytesPerSec,
    List<DownloadedSubtitle>? subtitles,
    DownloadStatus? status,
    String? error,
  }) {
    state = state
        .map(
          (t) => t.id == id
              ? t.copyWith(
                  filePath: filePath,
                  progress: progress,
                  bytesReceived: bytesReceived ?? t.bytesReceived,
                  totalBytes: totalBytes ?? t.totalBytes,
                  speedBytesPerSec: speedBytesPerSec ?? t.speedBytesPerSec,
                  subtitles: subtitles ?? t.subtitles,
                  status: status ?? t.status,
                  error: error ?? t.error,
                )
              : t,
        )
        .toList();
  }
}

final downloadsProvider =
    StateNotifierProvider<DownloadsNotifier, List<DownloadTask>>(
      (ref) => DownloadsNotifier(),
    );
