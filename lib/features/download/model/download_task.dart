enum DownloadStatus { queued, downloading, completed, failed, canceled }

class DownloadedSubtitle {
  final String language;
  final String url;
  final String? localPath;
  DownloadedSubtitle({
    required this.language,
    required this.url,
    this.localPath,
  });

  DownloadedSubtitle copyWith({String? localPath}) {
    return DownloadedSubtitle(
      language: language,
      url: url,
      localPath: localPath ?? this.localPath,
    );
  }
}

class DownloadTask {
  final int id;
  final String animeSlug;
  final String animeTitle;
  final String episodeId;
  final String episodeNumber;
  final String title;
  final String serverId;
  final String url;
  final String? posterUrl;

  String? filePath;

  double progress;
  int bytesReceived;
  int? totalBytes;
  double speedBytesPerSec;

  final List<DownloadedSubtitle> subtitles;

  DownloadStatus status;
  String? error;

  DownloadTask({
    required this.id,
    required this.animeSlug,
    required this.animeTitle,
    required this.episodeId,
    required this.episodeNumber,
    required this.title,
    required this.serverId,
    required this.url,
    this.posterUrl,
    this.filePath,
    this.progress = 0.0,
    this.bytesReceived = 0,
    this.totalBytes,
    this.speedBytesPerSec = 0.0,
    this.subtitles = const [],
    this.status = DownloadStatus.queued,
    this.error,
  });

  DownloadTask copyWith({
    String? filePath,
    double? progress,
    int? bytesReceived,
    int? totalBytes,
    double? speedBytesPerSec,
    List<DownloadedSubtitle>? subtitles,
    DownloadStatus? status,
    String? error,
  }) {
    return DownloadTask(
      id: id,
      animeSlug: animeSlug,
      animeTitle: animeTitle,
      episodeId: episodeId,
      episodeNumber: episodeNumber,
      title: title,
      serverId: serverId,
      url: url,
      filePath: filePath ?? this.filePath,
      progress: progress ?? this.progress,
      bytesReceived: bytesReceived ?? this.bytesReceived,
      totalBytes: totalBytes ?? this.totalBytes,
      speedBytesPerSec: speedBytesPerSec ?? this.speedBytesPerSec,
      subtitles: subtitles ?? this.subtitles,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }

  String get suggestedFileName {
    final safeTitle = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final ext = url.split('?').first.split('.').last;
    final fileExt = url.toLowerCase().contains('.m3u8') ? 'ts' : ext;
    return '${animeSlug}_EP${episodeNumber}_$safeTitle.$fileExt';
  }
}
