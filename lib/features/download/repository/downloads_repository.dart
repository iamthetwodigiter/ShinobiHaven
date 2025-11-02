import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shinobihaven/core/constants/app_details.dart';
import 'package:shinobihaven/features/download/model/download_task.dart';
import 'package:ffmpeg_kit_flutter_new_https/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_https/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_https/return_code.dart';
import 'package:shinobihaven/core/services/notification_service.dart';

typedef ProgressCallback =
    void Function(int received, int? total, double speed);
typedef SubtitleSavedCallback =
    void Function(String language, String localPath);

class HlsVariant {
  final String uri;
  final int? bandwidth;
  final String? resolution;
  final String? name;
  HlsVariant({required this.uri, this.bandwidth, this.resolution, this.name});
  @override
  String toString() =>
      'HlsVariant(uri=$uri, bw=$bandwidth, res=$resolution, name=$name)';
}

class DownloadsRepository {
  static DownloadsRepository? _instance;
  final Dio _dio = Dio();

  final Map<String, Map<String, dynamic>> _activeDownloads = {};
  final ValueNotifier<List<Map<String, dynamic>>> activeDownloads =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  DownloadsRepository._internal();
  factory DownloadsRepository() {
    _instance ??= DownloadsRepository._internal();
    return _instance!;
  }

  void _emitActive() =>
      activeDownloads.value = _activeDownloads.values.toList(growable: false);

  Future<String> _getDownloadDirectoryPath() async {
    if (Platform.isAndroid) {
      final dir = Directory(AppDetails.appDownloadsDirectory);
      if (!dir.existsSync()) dir.createSync(recursive: true);
      return dir.path;
    }
    final appDoc = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDoc.path, 'Downloads'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir.path;
  }

  Future<bool> ensureStoragePermission() async {
    if (Platform.isAndroid) {
      final st = await Permission.storage.request();
      final ex = await Permission.manageExternalStorage.request();
      if ((st.isDenied || st.isPermanentlyDenied) &&
          (ex.isDenied || ex.isPermanentlyDenied)) {
        return false;
      }
      return true;
    }
    return true;
  }

  String _sanitizeFileName(String input) {
    final sanitized = input.replaceAll(RegExp(r'[\/\\\:\*\?"<>\|]'), '').trim();
    return sanitized.replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<void> downloadFile({
    required DownloadTask task,
    required ProgressCallback onProgress,
    required VoidCallback onComplete,
    required void Function(String error) onError,
    required SubtitleSavedCallback onSubtitleSaved,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    final int progressNotificationId =
        NotificationIds.episodeDownload + (id.hashCode & 0x3FF);
    final int completeNotificationId =
        NotificationIds.episodeComplete + ((id.hashCode >> 1) & 0x3FF);
    final int failedNotificationId =
        NotificationIds.episodeFailed + ((id.hashCode >> 2) & 0x3FF);

    _activeDownloads[id] = {
      'id': id,
      'animeTitle': task.animeTitle,
      'episodeNumber': task.episodeNumber,
      'title': task.title,
      'progress': 0,
      'received': 0,
      'total': null,
      'speed': 0.0,
      'eta': null,
      'filePath': null,
      'status': 'running',
      'notificationId': progressNotificationId,
    };
    _emitActive();

    try {
      await NotificationServiceExtensions.showDownloadStarted(
        id: progressNotificationId,
        itemName: '${task.animeTitle} • Ep ${task.episodeNumber} ${task.title}',
        channel: NotificationChannel.downloads,
      );
    } catch (_) {}

    try {
      final hasPerm = await ensureStoragePermission();
      if (!hasPerm) {
        _activeDownloads[id]?['status'] = 'failed';
        _emitActive();
        try {
          await NotificationServiceExtensions.showDownloadFailed(
            id: failedNotificationId,
            itemName: '${task.animeTitle} • Ep ${task.episodeNumber}',
            channel: NotificationChannel.downloads,
            error: 'Storage permission denied',
            progressNotificationId: progressNotificationId,
          );
        } catch (_) {}
        onError('Storage permission denied');
        return;
      }

      final dirPath = await _getDownloadDirectoryPath();
      final animeFolderName = _sanitizeFileName(
        task.animeTitle.isNotEmpty ? task.animeTitle : 'Unknown Anime',
      );
      final animeDir = Directory(p.join(dirPath, animeFolderName));
      if (!animeDir.existsSync()) animeDir.createSync(recursive: true);

      String? posterPath;
      try {
        final posterUrl = (task as dynamic).posterUrl != null
            ? (task as dynamic).posterUrl as String?
            : null;
        if (posterUrl != null && posterUrl.isNotEmpty) {
          final resp = await _dio.get<List<int>>(
            posterUrl,
            options: Options(
              responseType: ResponseType.bytes,
              followRedirects: true,
            ),
          );
          if (resp.data != null) {
            final ct = resp.headers.value('content-type') ?? '';
            String ext = '.jpg';
            if (posterUrl.toLowerCase().contains('.png') ||
                ct.contains('png')) {
              ext = '.png';
            } else if (posterUrl.toLowerCase().contains('.webp') ||
                ct.contains('webp')) {
              ext = '.webp';
            } else if (posterUrl.toLowerCase().contains('.jpeg') ||
                ct.contains('jpeg')) {
              ext = '.jpg';
            }
            final pf = File(p.join(animeDir.path, 'poster$ext'));
            await pf.writeAsBytes(resp.data!);
            posterPath = pf.path;
          }
        }
      } catch (_) {}

      final safeBase = _sanitizeFileName('${task.episodeNumber}_${task.title}');
      String outExt;
      if (task.url.toLowerCase().contains('.m3u8')) {
        outExt = '.mp4';
      } else {
        try {
          final urlPath = Uri.parse(task.url).path;
          final ext = p.extension(urlPath);
          outExt = ext.isNotEmpty ? ext : '.mp4';
        } catch (_) {
          outExt = '.mp4';
        }
      }

      final savePath = p.join(animeDir.path, '$safeBase$outExt');
      _activeDownloads[id]?['filePath'] = savePath;
      _emitActive();

      final List<Map<String, String>> downloadedSubs = [];
      for (final sub in task.subtitles) {
        try {
          final resp = await _dio.get<List<int>>(
            sub.url,
            options: Options(
              responseType: ResponseType.bytes,
              followRedirects: true,
            ),
          );
          if (resp.data != null) {
            String? ext;
            final urlLower = sub.url.toLowerCase();
            if (urlLower.contains('.srt')) {
              ext = 'srt';
            } else if (urlLower.contains('.vtt')) {
              ext = 'vtt';
            }

            final bytes = resp.data!;
            final contentStr = utf8
                .decode(bytes, allowMalformed: true)
                .trimLeft();

            if (ext == null) {
              final ct = resp.headers.value('content-type') ?? '';
              if (ct.contains('vtt') || contentStr.startsWith('WEBVTT')) {
                ext = 'vtt';
              } else if (ct.contains('subrip') ||
                  RegExp(
                    r'^\d+\s*\r?\n\d{2}:\d{2}:\d{2},\d{3}',
                  ).hasMatch(contentStr)) {
                ext = 'srt';
              } else {
                ext = 'vtt';
              }
            }

            final subFile = File(
              p.join(
                animeDir.path,
                'EP${task.episodeNumber}_${_sanitizeFileName(sub.language)}.$ext',
              ),
            );
            await subFile.writeAsBytes(bytes);
            downloadedSubs.add({'path': subFile.path, 'lang': sub.language});
            onSubtitleSaved(sub.language, subFile.path);
          }
        } catch (_) {}
      }

      void localProgress(int received, int? total, double speed) {
        final entry = _activeDownloads[id];
        if (entry == null) return;
        entry['received'] = received;
        entry['total'] = total;
        entry['speed'] = speed;
        if (total != null && speed > 0) {
          final remaining = (total - received).clamp(0, total);
          entry['eta'] = (remaining / speed).toDouble();
        } else {
          entry['eta'] = null;
        }

        int percent = 0;
        if (total != null && total > 0) {
          percent = ((received / total) * 100).clamp(0, 100).toInt();
        }
        entry['progress'] = percent;
        entry['status'] = 'running';
        _emitActive();

        try {
          final recStr = NotificationService.formatFileSize(received);
          final totStr = total != null
              ? NotificationService.formatFileSize(total)
              : 'Unknown';
          final speedStr = speed > 0
              ? '${NotificationService.formatFileSize(speed.toInt())}/s'
              : '—';
          final desc = '$recStr / $totStr • $speedStr • $percent%';
          NotificationService.showProgressNotification(
            id: progressNotificationId,
            title: '${task.animeTitle} • Ep ${task.episodeNumber}',
            description: desc,
            channel: NotificationChannel.downloads,
            progress: percent,
            maxProgress: 100,
            ongoing: true,
            showProgress: true,
            silent: true,
          );
        } catch (_) {}

        try {
          onProgress(received, total, speed);
        } catch (_) {}
      }

      if (task.url.toLowerCase().contains('.m3u8')) {
        await _downloadHls(task.url, savePath, localProgress);

        if (downloadedSubs.isNotEmpty) {
          try {
            final finalMp4 = await _embedSubtitlesIntoMp4(
              savePath,
              downloadedSubs,
            );
            await _recordCompletedDownload(
              finalMp4,
              task,
              posterPath: posterPath,
            );
            _activeDownloads.remove(id);
            _emitActive();
            try {
              await NotificationServiceExtensions.showDownloadCompleted(
                id: completeNotificationId,
                itemName: '${task.animeTitle} • Ep ${task.episodeNumber}',
                channel: NotificationChannel.downloads,
                description:
                    '${task.animeTitle} • Ep ${task.episodeNumber} - ${task.title}',
                filePath: finalMp4,
                progressNotificationId: progressNotificationId,
              );
            } catch (_) {}
          } catch (e) {
            await _recordCompletedDownload(
              savePath,
              task,
              posterPath: posterPath,
            );
            _activeDownloads.remove(id);
            _emitActive();
            try {
              await NotificationServiceExtensions.showDownloadFailed(
                id: failedNotificationId,
                itemName: '${task.animeTitle} • Ep ${task.episodeNumber}',
                channel: NotificationChannel.downloads,
                error: e.toString(),
                progressNotificationId: progressNotificationId,
              );
            } catch (_) {}
          }
        } else {
          await _recordCompletedDownload(
            savePath,
            task,
            posterPath: posterPath,
          );
          _activeDownloads.remove(id);
          _emitActive();
          try {
            await NotificationServiceExtensions.showDownloadCompleted(
              id: completeNotificationId,
              itemName: '${task.animeTitle} • Ep ${task.episodeNumber}',
              channel: NotificationChannel.downloads,
              description:
                  '${task.animeTitle} • Ep ${task.episodeNumber} - ${task.title}',
              filePath: savePath,
              progressNotificationId: progressNotificationId,
            );
          } catch (_) {}
        }
      } else {
        DateTime lastTick = DateTime.now();
        int lastReceived = 0;
        _dio.options.followRedirects = true;
        await _dio.download(
          task.url,
          savePath,
          onReceiveProgress: (received, total) {
            final now = DateTime.now();
            final deltaSec = now.difference(lastTick).inMilliseconds / 1000.0;
            final deltaBytes = received - lastReceived;
            final speed = deltaSec > 0 ? (deltaBytes / deltaSec) : 0.0;
            lastReceived = received;
            lastTick = now;
            localProgress(received, total == -1 ? null : total, speed);
          },
          options: Options(receiveTimeout: Duration(seconds: 0)),
        );

        if (downloadedSubs.isNotEmpty) {
          try {
            final finalMp4 = await _embedSubtitlesIntoMp4(
              savePath,
              downloadedSubs,
            );
            await _recordCompletedDownload(
              finalMp4,
              task,
              posterPath: posterPath,
            );
            _activeDownloads.remove(id);
            _emitActive();
            try {
              await NotificationServiceExtensions.showDownloadCompleted(
                id: completeNotificationId,
                itemName: '${task.animeTitle} • Ep ${task.episodeNumber}',
                channel: NotificationChannel.downloads,
                description:
                    '${task.animeTitle} • Ep ${task.episodeNumber} - ${task.title}',
                filePath: finalMp4,
                progressNotificationId: progressNotificationId,
              );
            } catch (_) {}
          } catch (e) {
            await _recordCompletedDownload(
              savePath,
              task,
              posterPath: posterPath,
            );
            _activeDownloads.remove(id);
            _emitActive();
            try {
              await NotificationServiceExtensions.showDownloadFailed(
                id: failedNotificationId,
                itemName: '${task.animeTitle} • Ep ${task.episodeNumber}',
                channel: NotificationChannel.downloads,
                error: e.toString(),
                progressNotificationId: progressNotificationId,
              );
            } catch (_) {}
          }
        } else {
          await _recordCompletedDownload(
            savePath,
            task,
            posterPath: posterPath,
          );
          _activeDownloads.remove(id);
          _emitActive();
          try {
            await NotificationServiceExtensions.showDownloadCompleted(
              id: completeNotificationId,
              itemName: '${task.animeTitle} • Ep ${task.episodeNumber}',
              channel: NotificationChannel.downloads,
              description:
                  '${task.animeTitle} • Ep ${task.episodeNumber} - ${task.title}',
              filePath: savePath,
              progressNotificationId: progressNotificationId,
            );
          } catch (_) {}
        }
      }

      onComplete();
    } catch (e) {
      final entry = _activeDownloads[id];
      if (entry != null) entry['status'] = 'failed';
      _emitActive();

      try {
        await NotificationServiceExtensions.showDownloadFailed(
          id: NotificationIds.episodeFailed,
          itemName: '${task.animeTitle} • Ep ${task.episodeNumber}',
          channel: NotificationChannel.downloads,
          error: e.toString(),
          progressNotificationId: progressNotificationId,
        );
      } catch (_) {}

      onError(e.toString());
    }
  }

  Future<double?> _resolvePlaylistDuration(String url) async {
    try {
      final probeSession = await FFprobeKit.getMediaInformation(url);
      final info = probeSession.getMediaInformation();
      if (info != null) {
        final durStr = info.getDuration();
        if (durStr != null && durStr.isNotEmpty) {
          final v = double.tryParse(durStr);
          if (v != null && v > 0) return v;
        }
      }
    } catch (_) {}
    try {
      final resp = await _dio.get<String>(
        url,
        options: Options(responseType: ResponseType.plain),
      );
      final body = resp.data ?? '';
      final dur = _sumExtinfDurations(body);
      if (dur > 0) return dur;
      final lines = body
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      for (final line in lines) {
        if (!line.startsWith('#') && line.toLowerCase().endsWith('.m3u8')) {
          final resolved = _resolveUri(url, line);
          if (resolved != null) {
            final resp2 = await _dio.get<String>(
              resolved,
              options: Options(responseType: ResponseType.plain),
            );
            final dur2 = _sumExtinfDurations(resp2.data ?? '');
            if (dur2 > 0) return dur2;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  double _sumExtinfDurations(String playlistText) {
    final regex = RegExp(r'#EXTINF:([0-9.]+)', multiLine: true);
    final matches = regex.allMatches(playlistText);
    double total = 0.0;
    for (final m in matches) {
      final s = m.group(1);
      if (s != null) {
        final v = double.tryParse(s);
        if (v != null) total += v;
      }
    }
    return total;
  }

  String? _resolveUri(String base, String ref) {
    try {
      final baseUri = Uri.parse(base);
      final resolved = baseUri.resolve(ref).toString();
      return resolved;
    } catch (_) {
      return null;
    }
  }

  void _cleanupPlaylists(String dirPath) {
    try {
      final d = Directory(dirPath);
      if (!d.existsSync()) return;
      for (final ent in d.listSync(recursive: true)) {
        if (ent is File) {
          final ext = p.extension(ent.path).toLowerCase();
          if (ext == '.m3u8') {
            try {
              ent.deleteSync();
            } catch (_) {}
          }
        }
      }
    } catch (_) {}
  }

  int? _estimateTotalFromBitrate(num? bitrateValue, double totalDurationSec) {
    if (bitrateValue == null) return null;
    final bitrate = bitrateValue.toDouble();
    if (bitrate <= 0) return null;
    double bytesPerSec;
    if (bitrate > 1e6) {
      bytesPerSec = bitrate / 8.0;
    } else {
      bytesPerSec = (bitrate * 1000.0) / 8.0;
    }
    final est = (bytesPerSec * totalDurationSec).toInt();
    return est > 0 ? est : null;
  }

  Future<void> _downloadHls(
    String playlistUrl,
    String savePath,
    ProgressCallback onProgress,
  ) async {
    final outFile = File(savePath);
    final parent = outFile.parent;
    if (!parent.existsSync()) parent.createSync(recursive: true);

    final tempPath = savePath;
    double? totalDurationSec = await _resolvePlaylistDuration(playlistUrl);

    final escapedUrl = playlistUrl.replaceAll('"', '\\"');
    final escapedOut = savePath.replaceAll('"', '\\"');
    final cmd =
        '-y -protocol_whitelist "file,http,https,tcp,tls" -i "$escapedUrl" -map 0 -bsf:a aac_adtstoasc -c copy "$escapedOut"';

    final completer = Completer<void>();
    Timer? pollTimer;
    final stopwatch = Stopwatch()..start();
    int lastBytesSample = 0;
    int lastSampleTime = stopwatch.elapsedMilliseconds;

    try {
      FFmpegKit.executeAsync(
        cmd,
        (session) async {
          try {
            final rc = await session.getReturnCode();
            final failTrace = await session.getFailStackTrace();

            pollTimer?.cancel();
            stopwatch.stop();
            if (ReturnCode.isSuccess(rc)) {
              _cleanupPlaylists(parent.path);
              completer.complete();
            } else {
              try {
                if (File(tempPath).existsSync()) File(tempPath).deleteSync();
              } catch (_) {}
              final codeVal = rc?.getValue();
              completer.completeError(
                'FFmpeg failed (rc=$codeVal) ${failTrace ?? ''}',
              );
            }
          } catch (e) {
            pollTimer?.cancel();
            stopwatch.stop();

            completer.completeError(e.toString());
          }
        },
        (log) {},
        (statistics) {
          try {
            final timeMs = statistics.getTime();
            final size = statistics.getSize();
            final bitrate = statistics.getBitrate();

            if (totalDurationSec != null && totalDurationSec > 0) {
              final timeSec = timeMs / 1000.0;
              final percent = (timeSec / totalDurationSec).clamp(0.0, 1.0);
              if (size > 0) {
                final estimatedTotal = (size / (percent > 0 ? percent : 1.0))
                    .toInt();
                final elapsedSec =
                    max(1, stopwatch.elapsedMilliseconds) / 1000.0;
                final speed = size / elapsedSec;
                onProgress(size.toInt(), estimatedTotal, speed);
              } else {
                final estTotal = _estimateTotalFromBitrate(
                  bitrate,
                  totalDurationSec,
                );
                if (estTotal != null) {
                  final received = (percent * estTotal).toInt();
                  final speed =
                      (estTotal /
                      (totalDurationSec > 0 ? totalDurationSec : 1.0));
                  onProgress(received, estTotal, speed);
                } else {
                  onProgress(0, null, 0.0);
                }
              }
            } else if (size != 0) {
              final elapsedSec = max(1, stopwatch.elapsedMilliseconds) / 1000.0;
              final speed = size / elapsedSec;
              onProgress(size.toInt(), null, speed);
            }
          } catch (_) {}
        },
      );

      if (totalDurationSec == null || totalDurationSec <= 0) {
        pollTimer = Timer.periodic(Duration(milliseconds: 500), (_) {
          try {
            final tmp = File(tempPath);
            if (!tmp.existsSync()) return;
            final current = tmp.lengthSync();
            final now = stopwatch.elapsedMilliseconds;
            final dt = max(1, now - lastSampleTime);
            final delta = current - lastBytesSample;
            final speed = delta / (dt / 1000.0);
            lastBytesSample = current;
            lastSampleTime = now;
            onProgress(current, null, speed);
          } catch (_) {}
        });
      }

      await completer.future;
    } finally {
      pollTimer?.cancel();
      stopwatch.stop();
    }
  }

  Future<String> _embedSubtitlesIntoMp4(
    String inputPath,
    List<Map<String, String>> subs,
  ) async {
    if (subs.isEmpty) return inputPath;
    final dir = p.dirname(inputPath);
    final baseName = p.basenameWithoutExtension(inputPath);
    final finalMp4 = p.join(dir, '${baseName}_with_subs.mp4');

    final converted = <Map<String, String>>[];
    for (final s in subs) {
      final orig = s['path']!;
      final ext = p.extension(orig).toLowerCase();
      if (ext == '.vtt') {
        final conv = orig.replaceAll(
          RegExp(r'\.vtt$', caseSensitive: false),
          '.srt',
        );
        try {
          final cmd =
              '-y -f webvtt -i "${orig.replaceAll('"', '\\"')}" "${conv.replaceAll('"', '\\"')}"';
          final session = await FFmpegKit.execute(cmd);
          final rc = await session.getReturnCode();
          if (ReturnCode.isSuccess(rc)) {
            try {
              File(orig).deleteSync();
            } catch (_) {}
            converted.add({'path': conv, 'lang': s['lang']!});
          } else {
            converted.add({'path': orig, 'lang': s['lang']!});
          }
        } catch (e) {
          converted.add({'path': orig, 'lang': s['lang']!});
        }
      } else {
        converted.add({'path': orig, 'lang': s['lang']!});
      }
    }

    final inputs = StringBuffer();
    inputs.write('-i "${inputPath.replaceAll('"', '\\"')}" ');
    for (final s in converted) {
      inputs.write('-i "${s['path']!.replaceAll('"', '\\"')}" ');
    }

    final maps = StringBuffer();
    maps.write('-map 0:v? -map 0:a? ');
    for (int i = 0; i < converted.length; i++) {
      maps.write('-map ${i + 1} ');
    }

    final metadata = StringBuffer();
    for (int i = 0; i < converted.length; i++) {
      final lang = converted[i]['lang'] ?? 'und';
      metadata.write('-metadata:s:s:$i language=$lang ');
    }

    final cmd =
        '-y ${inputs.toString()} ${maps.toString()} -c:v copy -c:a copy -c:s mov_text ${metadata.toString()} "${finalMp4.replaceAll('"', '\\"')}"';

    final completer = Completer<void>();

    FFmpegKit.executeAsync(
      cmd,
      (session) async {
        final rc = await session.getReturnCode();
        if (ReturnCode.isSuccess(rc)) {
          completer.complete();
        } else {
          final failTrace = await session.getFailStackTrace();
          final logs = await session.getAllLogsAsString();
          debugPrint(
            '[_embedSubtitlesIntoMp4] FFmpeg failed: rc=${rc?.getValue()}',
          );
          debugPrint('[_embedSubtitlesIntoMp4] Logs: $logs');
          debugPrint('[_embedSubtitlesIntoMp4] Stack: ${failTrace ?? 'none'}');
          completer.completeError(
            'embed failed rc=${rc?.getValue()} ${failTrace ?? ''}',
          );
        }
      },
      (log) {
        debugPrint('[FFmpeg] ${log.getMessage()}');
      },
      (stats) {},
    );

    try {
      await completer.future;

      try {
        final origFile = File(inputPath);
        if (origFile.existsSync()) {
          origFile.deleteSync();
        }
      } catch (e) {
        debugPrint('[_embedSubtitlesIntoMp4] Failed to delete original: $e');
      }

      try {
        final finalFile = File(finalMp4);
        if (finalFile.existsSync()) {
          await finalFile.rename(inputPath);
        }
      } catch (e) {
        debugPrint('[_embedSubtitlesIntoMp4] Failed to rename: $e');
        for (final s in converted) {
          try {
            final f = File(s['path']!);
            if (f.existsSync()) f.deleteSync();
          } catch (_) {}
        }
        return finalMp4;
      }

      for (final s in converted) {
        try {
          final f = File(s['path']!);
          if (f.existsSync()) f.deleteSync();
        } catch (_) {}
      }

      return inputPath;
    } catch (e) {
      debugPrint('[_embedSubtitlesIntoMp4] Error: $e');

      try {
        final finalFile = File(finalMp4);
        if (finalFile.existsSync()) finalFile.deleteSync();
      } catch (_) {}

      for (final s in converted) {
        try {
          final f = File(s['path']!);
          if (f.existsSync()) f.deleteSync();
        } catch (_) {}
      }

      rethrow;
    }
  }

  Future<void> _recordCompletedDownload(
    String filePath,
    DownloadTask task, {
    String? posterPath,
  }) async {
    try {
      final appDoc = (Platform.isAndroid || Platform.isIOS)
          ? await getApplicationDocumentsDirectory()
          : Directory(AppDetails.basePath);
      final indexFile = File(p.join(appDoc.path, 'downloads_index.json'));
      List<Map<String, dynamic>> list = [];
      if (indexFile.existsSync()) {
        try {
          final txt = await indexFile.readAsString();
          final decoded = json.decode(txt);
          if (decoded is List) list = List<Map<String, dynamic>>.from(decoded);
        } catch (_) {}
      }
      final stat = await File(filePath).stat();
      final entry = {
        'animeSlug': task.animeSlug,
        'animeTitle': task.animeTitle,
        'episodeId': task.episodeId,
        'episodeNumber': task.episodeNumber,
        'title': task.title,
        'filePath': filePath,
        'posterPath': posterPath,
        'size': stat.size,
        'downloadedAt': DateTime.now().toIso8601String(),
      };
      list.removeWhere((e) => e['filePath'] == filePath);
      list.add(entry);
      await indexFile.writeAsString(json.encode(list), flush: true);
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> loadDownloadsIndex() async {
    try {
      await _syncIndexWithDisk();
      final appDoc = (Platform.isAndroid || Platform.isIOS)
          ? await getApplicationDocumentsDirectory()
          : Directory(AppDetails.basePath);
      final indexFile = File(p.join(appDoc.path, 'downloads_index.json'));
      if (!indexFile.existsSync()) return [];
      final txt = await indexFile.readAsString();
      final decoded = json.decode(txt);
      if (decoded is List) return List<Map<String, dynamic>>.from(decoded);
    } catch (_) {}
    return [];
  }

  Future<void> _syncIndexWithDisk() async {
    try {
      final dirPath = await _getDownloadDirectoryPath();
      final baseDir = Directory(dirPath);
      final appDoc = (Platform.isAndroid || Platform.isIOS)
          ? await getApplicationDocumentsDirectory()
          : Directory(AppDetails.basePath);
      final indexFile = File(p.join(appDoc.path, 'downloads_index.json'));

      List<Map<String, dynamic>> indexList = [];
      if (indexFile.existsSync()) {
        try {
          final txt = await indexFile.readAsString();
          final decoded = json.decode(txt);
          if (decoded is List) {
            indexList = List<Map<String, dynamic>>.from(decoded);
          }
        } catch (_) {}
      }

      final Map<String, Map<String, dynamic>> indexByPath = {
        for (var e in indexList) (e['filePath'] as String): e,
      };
      final extensions = ['.mp4', '.mkv', '.webm', '.avi', '.mov'];
      final foundFiles = <String>{};

      if (baseDir.existsSync()) {
        for (final entity in baseDir.listSync(recursive: true)) {
          if (entity is File) {
            final ext = p.extension(entity.path).toLowerCase();
            if (!extensions.contains(ext)) continue;
            foundFiles.add(entity.path);
            final stat = await entity.stat();
            if (indexByPath.containsKey(entity.path)) {
              final existing = indexByPath[entity.path]!;
              if ((existing['size'] as int?) != stat.size) {
                existing['size'] = stat.size;
                existing['downloadedAt'] = DateTime.now().toIso8601String();
              }
              if (existing['posterPath'] == null) {
                final parentDir = p.dirname(entity.path);
                String? foundPoster;
                try {
                  for (final f in Directory(parentDir).listSync()) {
                    if (f is File) {
                      final pe = p.extension(f.path).toLowerCase();
                      if (['.jpg', '.jpeg', '.png', '.webp'].contains(pe)) {
                        final name = p
                            .basenameWithoutExtension(f.path)
                            .toLowerCase();
                        if (name.startsWith('poster')) {
                          foundPoster = f.path;
                          break;
                        }
                        foundPoster ??= f.path;
                      }
                    }
                  }
                } catch (_) {}
                if (foundPoster != null) existing['posterPath'] = foundPoster;
              }
            } else {
              final animeTitle = p.basename(p.dirname(entity.path));
              final filename = p.basenameWithoutExtension(entity.path);
              String episodeNumber = '';
              String title = filename;
              final parts = filename.split('_');
              if (parts.length >= 2 && RegExp(r'^\d+$').hasMatch(parts.first)) {
                episodeNumber = parts.first;
                title = parts.sublist(1).join('_');
              }
              String? foundPoster;
              try {
                final parentDir = p.dirname(entity.path);
                for (final f in Directory(parentDir).listSync()) {
                  if (f is File) {
                    final pe = p.extension(f.path).toLowerCase();
                    if (['.jpg', '.jpeg', '.png', '.webp'].contains(pe)) {
                      final name = p
                          .basenameWithoutExtension(f.path)
                          .toLowerCase();
                      if (name.startsWith('poster')) {
                        foundPoster = f.path;
                        break;
                      }
                      foundPoster ??= f.path;
                    }
                  }
                }
              } catch (_) {}
              indexList.add({
                'animeSlug': null,
                'animeTitle': animeTitle,
                'episodeId': null,
                'episodeNumber': episodeNumber,
                'title': title,
                'filePath': entity.path,
                'posterPath': foundPoster,
                'size': stat.size,
                'downloadedAt': DateTime.now().toIso8601String(),
              });
            }
          }
        }
      }

      indexList.removeWhere((e) {
        final path = e['filePath'] as String?;
        if (path == null) return true;
        return !foundFiles.contains(path);
      });

      await indexFile.writeAsString(json.encode(indexList), flush: true);
    } catch (_) {}
  }

  Future<List<HlsVariant>> listHlsVariants(String masterUrl) async {
    try {
      final resp = await _dio.get<String>(
        masterUrl,
        options: Options(responseType: ResponseType.plain),
      );
      final body = resp.data ?? '';
      final lines = body
          .split(RegExp(r'\r?\n'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final variants = <HlsVariant>[];
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.startsWith('#EXT-X-STREAM-INF')) {
          final attrLine = line.substring('#EXT-X-STREAM-INF:'.length);
          final attrs = <String, String>{};
          for (final part in attrLine.split(',')) {
            final kv = part.split('=');
            if (kv.length >= 2) {
              attrs[kv[0].trim()] = kv
                  .sublist(1)
                  .join('=')
                  .replaceAll('"', '')
                  .trim();
            }
          }
          String? uri;
          for (int j = i + 1; j < lines.length; j++) {
            if (!lines[j].startsWith('#')) {
              uri = lines[j];
              break;
            }
          }
          if (uri != null) {
            final resolved = _resolveUri(masterUrl, uri) ?? uri;
            final bw = attrs.containsKey('BANDWIDTH')
                ? int.tryParse(attrs['BANDWIDTH']!)
                : null;
            final res = attrs['RESOLUTION'];
            final name = attrs['NAME'] ?? attrs['VIDEO'];
            variants.add(
              HlsVariant(
                uri: resolved,
                bandwidth: bw,
                resolution: res,
                name: name,
              ),
            );
          }
        }
      }
      return variants;
    } catch (e) {
      return [];
    }
  }

  Future<void> downloadHlsVariant(
    String variantUrl,
    String savePath,
    ProgressCallback onProgress,
  ) async {
    return _downloadHls(variantUrl, savePath, onProgress);
  }
}
