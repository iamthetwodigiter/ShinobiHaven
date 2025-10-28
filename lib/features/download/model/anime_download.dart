import 'package:hive_flutter/hive_flutter.dart';
part 'anime_download.g.dart';

@HiveType(typeId: 5)
class AnimeDownload {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String animeSlug;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String image;

  @HiveField(4)
  final String? type;

  @HiveField(5)
  final List<EpisodeDownload> episodes;

  @HiveField(6)
  final DateTime createdAt;

  AnimeDownload({
    required this.id,
    required this.animeSlug,
    required this.title,
    required this.image,
    this.type,
    required this.episodes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  AnimeDownload copyWith({
    String? id,
    String? animeSlug,
    String? title,
    String? image,
    String? type,
    List<EpisodeDownload>? episodes,
    DateTime? createdAt,
  }) {
    return AnimeDownload(
      id: id ?? this.id,
      animeSlug: animeSlug ?? this.animeSlug,
      title: title ?? this.title,
      image: image ?? this.image,
      type: type ?? this.type,
      episodes: episodes ?? this.episodes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

@HiveType(typeId: 6)
class EpisodeDownload {
  @HiveField(0)
  final String episodeID;

  @HiveField(1)
  final String episodeNumber;

  @HiveField(2)
  final String title;

  @HiveField(3)
  String filePath;

  @HiveField(4)
  String? serverID;

  @HiveField(5)
  String? quality;

  @HiveField(6)
  DownloadStatus status;

  @HiveField(7)
  double progress;

  @HiveField(8)
  int? totalBytes;

  EpisodeDownload({
    required this.episodeID,
    required this.episodeNumber,
    required this.title,
    this.filePath = '',
    this.serverID,
    this.quality,
    this.status = DownloadStatus.queued,
    this.progress = 0.0,
    this.totalBytes,
  });

  EpisodeDownload copyWith({
    String? episodeID,
    String? episodeNumber,
    String? title,
    String? filePath,
    String? serverID,
    String? quality,
    DownloadStatus? status,
    double? progress,
    int? totalBytes,
  }) {
    return EpisodeDownload(
      episodeID: episodeID ?? this.episodeID,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      serverID: serverID ?? this.serverID,
      quality: quality ?? this.quality,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      totalBytes: totalBytes ?? this.totalBytes,
    );
  }
}

@HiveType(typeId: 7)
enum DownloadStatus {
  @HiveField(0)
  queued,
  @HiveField(1)
  downloading,
  @HiveField(2)
  paused,
  @HiveField(3)
  completed,
  @HiveField(4)
  failed,
  @HiveField(5)
  cancelled,
}