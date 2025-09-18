// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anime.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AnimeAdapter extends TypeAdapter<Anime> {
  @override
  final int typeId = 0;

  @override
  Anime read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Anime(
      slug: fields[0] as String,
      link: fields[1] as String,
      title: fields[2] as String,
      jname: fields[3] as String,
      image: fields[4] as String,
      type: fields[5] as String?,
      description: fields[6] as String?,
      rank: fields[7] as String?,
      duration: fields[8] as String?,
      subCount: fields[9] as String?,
      dubCount: fields[10] as String?,
      episodeCount: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Anime obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.slug)
      ..writeByte(1)
      ..write(obj.link)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.jname)
      ..writeByte(4)
      ..write(obj.image)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.rank)
      ..writeByte(8)
      ..write(obj.duration)
      ..writeByte(9)
      ..write(obj.subCount)
      ..writeByte(10)
      ..write(obj.dubCount)
      ..writeByte(11)
      ..write(obj.episodeCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnimeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
