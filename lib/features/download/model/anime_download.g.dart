// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anime_download.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AnimeDownloadAdapter extends TypeAdapter<AnimeDownload> {
  @override
  final int typeId = 5;

  @override
  AnimeDownload read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AnimeDownload(
      id: fields[0] as String,
      animeSlug: fields[1] as String,
      title: fields[2] as String,
      image: fields[3] as String,
      type: fields[4] as String?,
      episodes: (fields[5] as List).cast<EpisodeDownload>(),
      createdAt: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, AnimeDownload obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.animeSlug)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.image)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.episodes)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnimeDownloadAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EpisodeDownloadAdapter extends TypeAdapter<EpisodeDownload> {
  @override
  final int typeId = 6;

  @override
  EpisodeDownload read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EpisodeDownload(
      episodeID: fields[0] as String,
      episodeNumber: fields[1] as String,
      title: fields[2] as String,
      filePath: fields[3] as String,
      serverID: fields[4] as String?,
      quality: fields[5] as String?,
      status: fields[6] as DownloadStatus,
      progress: fields[7] as double,
      totalBytes: fields[8] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, EpisodeDownload obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.episodeID)
      ..writeByte(1)
      ..write(obj.episodeNumber)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.filePath)
      ..writeByte(4)
      ..write(obj.serverID)
      ..writeByte(5)
      ..write(obj.quality)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.progress)
      ..writeByte(8)
      ..write(obj.totalBytes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EpisodeDownloadAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DownloadStatusAdapter extends TypeAdapter<DownloadStatus> {
  @override
  final int typeId = 7;

  @override
  DownloadStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DownloadStatus.queued;
      case 1:
        return DownloadStatus.downloading;
      case 2:
        return DownloadStatus.paused;
      case 3:
        return DownloadStatus.completed;
      case 4:
        return DownloadStatus.failed;
      case 5:
        return DownloadStatus.cancelled;
      default:
        return DownloadStatus.queued;
    }
  }

  @override
  void write(BinaryWriter writer, DownloadStatus obj) {
    switch (obj) {
      case DownloadStatus.queued:
        writer.writeByte(0);
        break;
      case DownloadStatus.downloading:
        writer.writeByte(1);
        break;
      case DownloadStatus.paused:
        writer.writeByte(2);
        break;
      case DownloadStatus.completed:
        writer.writeByte(3);
        break;
      case DownloadStatus.failed:
        writer.writeByte(4);
        break;
      case DownloadStatus.cancelled:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
