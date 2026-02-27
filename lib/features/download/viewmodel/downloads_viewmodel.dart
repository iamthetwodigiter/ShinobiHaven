import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinobihaven/features/anime/stream/model/sources.dart'
    hide Stream;
import 'package:shinobihaven/features/download/model/download_task.dart';
import 'package:shinobihaven/features/download/model/downloads_state.dart';
import 'package:shinobihaven/features/download/repository/downloads_repository.dart';

class DownloadsViewModel extends StateNotifier<DownloadsState> {
  static const _channel = MethodChannel(
    'app.thetwodigiter.shinobihaven/download',
  );

  final _notificationTapController = StreamController<void>.broadcast();
  Stream<void> get onNotificationTap => _notificationTapController.stream;

  final DownloadsRepository _repository;

  DownloadsViewModel(this._repository) : super(DownloadsState.initial()) {
    if (Platform.isAndroid || Platform.isIOS) {
      _initServiceListeners();
    }
    if (Platform.isAndroid) {
      _initNativeListeners();
    }
    loadCompletedDownloads();
  }

  Future<void> loadCompletedDownloads() async {
    state = state.copyWith(isLoadingCompleted: true);
    try {
      final list = await _repository.loadDownloadsIndex();
      state = state.copyWith(completedTasks: list, isLoadingCompleted: false);
    } catch (_) {
      state = state.copyWith(completedTasks: [], isLoadingCompleted: false);
    }
  }

  void _initNativeListeners() {
    _channel.setMethodCallHandler((call) async {
      final args = call.arguments as Map?;
      if (args == null) return;

      if (call.method == 'notification_tapped') {
        _notificationTapController.add(null);
        return;
      }

      final taskId = args['taskId'];
      int? id;
      if (taskId != null) {
        id = int.tryParse(taskId.toString());
      }

      if (id == null) return;

      switch (call.method) {
        case 'download_progress':
          _updateTaskState(
            id,
            bytesReceived: args['received'],
            totalBytes: args['total'],
            progress: (args['progress'] as num?)?.toDouble() ?? 0.0,
            speedBytesPerSec: (args['speed'] as num?)?.toDouble(),
            status: DownloadStatus.downloading,
          );
          break;
        case 'download_complete':
          final t = state.ongoingTasks.where((t) => t.id == id).firstOrNull;
          if (t != null) {
            _repository.getTaskSavePath(t).then((path) async {
              await _repository.recordCompletedDownload(path, t);
              _repository.removeOngoingPath(path);
              loadCompletedDownloads(); // Refresh completed list
              dismissTask(id!);
            });
          }
          _updateTaskState(id, progress: 1.0, status: DownloadStatus.completed);
          break;
        case 'download_error':
          final t = state.ongoingTasks.where((t) => t.id == id).firstOrNull;
          if (t != null) {
            _repository.getTaskSavePath(t).then((path) {
              _repository.removeOngoingPath(path);
            });
          }
          _updateTaskState(
            id,
            status: DownloadStatus.failed,
            error: args['error'],
          );
          break;
      }
    });
  }

  void _initServiceListeners() {
    final service = _getService();
    if (service == null) return;

    service.on('progress_update').listen((event) {
      if (event != null) {
        _updateTaskState(
          event['id'] as int,
          bytesReceived: event['received'],
          totalBytes: event['total'],
          speedBytesPerSec: (event['speed'] as num?)?.toDouble(),
          progress: event['total'] != null && event['total'] > 0
              ? (event['received'] / event['total'])
              : 0.5,
          status: DownloadStatus.downloading,
        );
      }
    });

    service.on('subtitle_saved').listen((event) {
      if (event != null) {
        final id = event['id'];
        final language = event['language'];
        final localPath = event['path'];

        final existing = state.ongoingTasks
            .where((t) => t.id == id)
            .firstOrNull;
        if (existing != null) {
          final updatedSubs = existing.subtitles
              .map(
                (s) => s.language == language
                    ? s.copyWith(localPath: localPath)
                    : s,
              )
              .toList();
          _updateTaskState(id as int, subtitles: updatedSubs);
        }
      }
    });

    service.on('download_complete').listen((event) {
      if (event != null) {
        final id = event['id'] as int;
        _updateTaskState(id, progress: 1.0, status: DownloadStatus.completed);
        loadCompletedDownloads();
        dismissTask(id);
      }
    });

    service.on('download_error').listen((event) {
      if (event != null) {
        _updateTaskState(
          event['id'] as int,
          status: DownloadStatus.failed,
          error: event['error'],
        );
      }
    });
  }

  int _nextId = Random().nextInt(1000000);

  Future<void> cancelDownload(int id) async {
    final t = state.ongoingTasks.where((t) => t.id == id).firstOrNull;
    if (t != null) {
      if (t.status == DownloadStatus.failed ||
          t.status == DownloadStatus.completed) {
        dismissTask(id);
        return;
      }

      if (Platform.isAndroid) {
        _repository
            .getTaskSavePath(t)
            .then((path) => _repository.removeOngoingPath(path));
        _channel.invokeMethod('cancelDownload', {'taskId': id.toString()});
      }
    }
    _updateTaskState(id, status: DownloadStatus.failed, error: 'Cancelled');
  }

  void dismissTask(int id) {
    state = state.copyWith(
      ongoingTasks: state.ongoingTasks.where((t) => t.id != id).toList(),
    );
  }

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

    state = state.copyWith(ongoingTasks: [...state.ongoingTasks, task]);

    if (Platform.isAndroid) {
      final savePath = await _repository.getTaskSavePath(task);
      _repository.addOngoingPath(savePath);

      // Resolve duration for more accurate progress bar in notification
      double? totalDuration;
      if (url.contains('.m3u8')) {
        totalDuration = await _repository.resolvePlaylistDuration(url);
      }

      _channel.invokeMethod('startDownload', {
        'taskId': id.toString(),
        'animeTitle': animeTitle,
        'episodeNumber': episodeNumber,
        'url': url,
        'savePath': savePath,
        'totalDuration': totalDuration,
      });
    } else if (Platform.isIOS) {
      // Delegate to background service for iOS
      _getService()?.invoke('start_download', {
        'task': task.toJson(),
      });
    }
  }

  void _updateTaskState(
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
    final updatedTasks = state.ongoingTasks.map((t) {
      if (t.id == id) {
        return t.copyWith(
          filePath: filePath,
          progress: progress,
          bytesReceived: bytesReceived ?? t.bytesReceived,
          totalBytes: totalBytes ?? t.totalBytes,
          speedBytesPerSec: speedBytesPerSec ?? t.speedBytesPerSec,
          subtitles: subtitles ?? t.subtitles,
          status: status ?? t.status,
          error: error ?? t.error,
        );
      }
      return t;
    }).toList();

    state = state.copyWith(ongoingTasks: updatedTasks);
  }

  FlutterBackgroundService? _getService() {
    if (Platform.isAndroid || Platform.isIOS) {
      return FlutterBackgroundService();
    }
    return null;
  }

  @override
  void dispose() {
    _notificationTapController.close();
    super.dispose();
  }
}
