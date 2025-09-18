import 'package:hive_flutter/hive_flutter.dart';

part 'anime.g.dart';

@HiveType(typeId: 0)
class Anime {
  @HiveField(0)
  final String slug;
  @HiveField(1)
  final String link;
  @HiveField(2)
  final String title;
  @HiveField(3)
  final String jname;
  @HiveField(4)
  final String image;
  @HiveField(5)
  final String? type;
  @HiveField(6)
  final String? description;
  @HiveField(7)
  final String? rank;
  @HiveField(8)
  final String? duration;
  @HiveField(9)
  final String? subCount;
  @HiveField(10)
  final String? dubCount;
  @HiveField(11)
  final String? episodeCount;

  Anime({
    required this.slug,
    required this.link,
    required this.title,
    required this.jname,
    required this.image,
    required this.type,
    this.description,
    this.rank,
    this.duration,
    this.subCount,
    this.dubCount,
    this.episodeCount,
  });

  Anime copyWith({
    String? slug,
    String? link,
    String? title,
    String? jname,
    String? image,
    String? type,
    String? description,
    String? rank,
    String? duration,
    String? subCount,
    String? dubCount,
    String? episodeCount,
  }) {
    return Anime(
      slug: slug ?? this.slug,
      link: link ?? this.link,
      title: title ?? this.title,
      jname: jname ?? this.jname,
      image: image ?? this.image,
      type: type ?? this.type,
      description: description ?? this.description,
      rank: rank ?? this.rank,
      duration: duration ?? this.duration,
      subCount: subCount ?? this.subCount,
      dubCount: dubCount ?? this.dubCount,
      episodeCount: episodeCount ?? this.episodeCount,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'slug': slug,
      'link': link,
      'title': title,
      'jname': jname,
      'image': image,
      'type': type,
      'description': description,
      'rank': rank,
      'duration': duration,
      'subCount': subCount,
      'dubCount': dubCount,
      'episodeCount': episodeCount,
    };
  }

  factory Anime.fromMap(Map<String, dynamic> map) {
    return Anime(
      slug: map['slug'] as String,
      link: (map['link'] ?? map['url']) as String,
      title: map['title'] as String,
      jname: map['jname'] as String,
      image: map['image'] as String,
      type: map['type'] as String?,
      description: map['description'] as String?,
      rank: map['rank'] as String?,
      duration: map['duration'] as String?,
      subCount: map['sub_count'] as String?,
      dubCount: map['dub_count'] as String?,
      episodeCount: map['episode_count'] as String?,
    );
  }
}
