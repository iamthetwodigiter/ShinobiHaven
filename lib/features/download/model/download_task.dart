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

  Map<String, dynamic> toJson() => {
    'language': language,
    'url': url,
    'localPath': localPath,
  };

  factory DownloadedSubtitle.fromJson(Map<String, dynamic> json) =>
      DownloadedSubtitle(
        language: json['language'],
        url: json['url'],
        localPath: json['localPath'],
      );
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'animeSlug': animeSlug,
    'animeTitle': animeTitle,
    'episodeId': episodeId,
    'episodeNumber': episodeNumber,
    'title': title,
    'serverId': serverId,
    'url': url,
    'posterUrl': posterUrl,
    'filePath': filePath,
    'progress': progress,
    'bytesReceived': bytesReceived,
    'totalBytes': totalBytes,
    'speedBytesPerSec': speedBytesPerSec,
    'subtitles': subtitles.map((s) => s.toJson()).toList(),
    'status': status.index,
    'error': error,
  };

  factory DownloadTask.fromJson(Map<String, dynamic> json) => DownloadTask(
    id: json['id'],
    animeSlug: json['animeSlug'],
    animeTitle: json['animeTitle'],
    episodeId: json['episodeId'],
    episodeNumber: json['episodeNumber'],
    title: json['title'],
    serverId: json['serverId'],
    url: json['url'],
    posterUrl: json['posterUrl'],
    filePath: json['filePath'],
    progress: (json['progress'] ?? 0.0).toDouble(),
    bytesReceived: json['bytesReceived'] ?? 0,
    totalBytes: json['totalBytes'],
    speedBytesPerSec: (json['speedBytesPerSec'] ?? 0.0).toDouble(),
    subtitles: (json['subtitles'] as List)
        .map((s) => DownloadedSubtitle.fromJson(s))
        .toList(),
    status: DownloadStatus.values[json['status'] ?? 0],
    error: json['error'],
  );
}
