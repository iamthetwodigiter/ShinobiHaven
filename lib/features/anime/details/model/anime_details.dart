import 'package:shinobihaven/features/anime/common/model/anime.dart';

class MapValues {
  final String name;
  final String url;

  MapValues({required this.name, required this.url});

  MapValues copyWith({String? name, String? url}) {
    return MapValues(name: name ?? this.name, url: url ?? this.url);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'name': name, 'url': url};
  }

  factory MapValues.fromMap(Map<String, dynamic> map) {
    return MapValues(name: map['name'] as String, url: map['url'] as String);
  }
}

class Characters {
  final String characterName;
  final String characterUrl;
  final String characterImage;
  final String characterRole;
  final String voiceActorName;
  final String voiceActorUrl;
  final String voiceActorImage;
  final String voiceActorLanguage;

  Characters({
    required this.characterName,
    required this.characterUrl,
    required this.characterImage,
    required this.characterRole,
    required this.voiceActorName,
    required this.voiceActorUrl,
    required this.voiceActorImage,
    required this.voiceActorLanguage,
  });

  Characters copyWith({
    String? characterName,
    String? characterUrl,
    String? characterImage,
    String? characterRole,
    String? voiceActorName,
    String? voiceActorUrl,
    String? voiceActorImage,
    String? voiceActorLanguage,
  }) {
    return Characters(
      characterName: characterName ?? this.characterName,
      characterUrl: characterUrl ?? this.characterUrl,
      characterImage: characterImage ?? this.characterImage,
      characterRole: characterRole ?? this.characterRole,
      voiceActorName: voiceActorName ?? this.voiceActorName,
      voiceActorUrl: voiceActorUrl ?? this.voiceActorUrl,
      voiceActorImage: voiceActorImage ?? this.voiceActorImage,
      voiceActorLanguage: voiceActorLanguage ?? this.voiceActorLanguage,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'characterName': characterName,
      'characterUrl': characterUrl,
      'characterImage': characterImage,
      'characterRole': characterRole,
      'voiceActorName': voiceActorName,
      'voiceActorUrl': voiceActorUrl,
      'voiceActorImage': voiceActorImage,
      'voiceActorLanguage': voiceActorLanguage,
    };
  }

  factory Characters.fromMap(Map<String, dynamic> map) {
    final character = map['character'] as Map<String, dynamic>? ?? {};
    final voiceActor = map['voice_actor'] as Map<String, dynamic>? ?? {};
    return Characters(
      characterName: character['name'] as String? ?? '',
      characterUrl: character['url'] as String? ?? '',
      characterImage: character['image'] as String? ?? '',
      characterRole: character['role'] as String? ?? '',
      voiceActorName: voiceActor['name'] as String? ?? '',
      voiceActorUrl: voiceActor['url'] as String? ?? '',
      voiceActorImage: voiceActor['image'] as String? ?? '',
      voiceActorLanguage: voiceActor['language'] as String? ?? '',
    );
  }
}

class Seasons {
  final String title;
  final String url;
  final String slug;
  final String image;
  final bool active;

  Seasons({
    required this.title,
    required this.url,
    required this.slug,
    required this.image,
    required this.active,
  });

  Seasons copyWith({
    String? title,
    String? url,
    String? slug,
    String? image,
    bool? active,
  }) {
    return Seasons(
      title: title ?? this.title,
      url: url ?? this.url,
      slug: slug ?? this.slug,
      image: image ?? this.image,
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'url': url,
      'slug': slug,
      'image': image,
      'active': active,
    };
  }

  factory Seasons.fromMap(Map<String, dynamic> map) {
    return Seasons(
      title: map['title'] as String,
      url: map['url'] as String,
      slug: map['slug'] as String,
      image: map['image'] as String,
      active: map['active'] as bool,
    );
  }
}

class AnimeDetails {
  final String title;
  final String jname;
  final String image;
  final String description;
  final String type;
  final String status;
  final String duration;
  final String score;
  final List<MapValues> genres;
  final List<MapValues> studios;
  final List<MapValues> producers;
  final String? aired;
  final String? premiered;
  final String? synonyms;
  final String? japanese;
  final String? subCount;
  final String? dubCount;
  final String? episodeCount;
  final String quality;
  final String rating;
  final List<Characters> characters;
  final List<Seasons> seasons;
  final List<Anime> related;
  final List<Anime> recommended;

  AnimeDetails({
    required this.title,
    required this.jname,
    required this.image,
    required this.description,
    required this.type,
    required this.status,
    required this.duration,
    required this.score,
    required this.genres,
    required this.studios,
    required this.producers,
    required this.aired,
    required this.premiered,
    required this.synonyms,
    required this.japanese,
    required this.subCount,
    required this.dubCount,
    this.episodeCount,
    required this.quality,
    required this.rating,
    required this.characters,
    required this.seasons,
    required this.related,
    required this.recommended,
  });

  AnimeDetails copyWith({
    String? title,
    String? jname,
    String? image,
    String? description,
    String? type,
    String? status,
    String? duration,
    String? score,
    List<MapValues>? genres,
    List<MapValues>? studios,
    List<MapValues>? producers,
    String? aired,
    String? premiered,
    String? synonyms,
    String? japanese,
    String? subCount,
    String? dubCount,
    String? episodeCount,
    String? quality,
    String? rating,
    List<Characters>? characters,
    List<Seasons>? seasons,
    List<Anime>? related,
    List<Anime>? recommended,
  }) {
    return AnimeDetails(
      title: title ?? this.title,
      jname: jname ?? this.jname,
      image: image ?? this.image,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      duration: duration ?? this.duration,
      score: score ?? this.score,
      genres: genres ?? this.genres,
      studios: studios ?? this.studios,
      producers: producers ?? this.producers,
      aired: aired ?? this.aired,
      premiered: premiered ?? this.premiered,
      synonyms: synonyms ?? this.synonyms,
      japanese: japanese ?? this.japanese,
      subCount: subCount ?? this.subCount,
      dubCount: dubCount ?? this.dubCount,
      episodeCount: episodeCount ?? this.episodeCount,
      quality: quality ?? this.quality,
      rating: rating ?? this.rating,
      characters: characters ?? this.characters,
      seasons: seasons ?? this.seasons,
      related: related ?? this.related,
      recommended: recommended ?? this.recommended,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'jname': jname,
      'image': image,
      'description': description,
      'type': type,
      'status': status,
      'duration': duration,
      'score': score,
      'genres': genres.map((x) => x.toMap()).toList(),
      'studios': studios.map((x) => x.toMap()).toList(),
      'producers': producers.map((x) => x.toMap()).toList(),
      'aired': aired,
      'premiered': premiered,
      'synonyms': synonyms,
      'japanese': japanese,
      'subCount': subCount,
      'dubCount': dubCount,
      'episodeCount': episodeCount,
      'quality': quality,
      'rating': rating,
      'characters': characters.map((x) => x.toMap()).toList(),
      'seasons': seasons.map((x) => x.toMap()).toList(),
      'related': related.map((x) => x.toMap()).toList(),
      'recommended': recommended.map((x) => x.toMap()).toList(),
    };
  }

  factory AnimeDetails.fromMap(Map<String, dynamic> map) {
    return AnimeDetails(
      title: map['details']['title'] as String,
      jname: map['details']['jname'] as String,
      image: map['details']['image'] as String,
      description: map['details']['description'] as String,
      type: map['details']['type'] as String,
      status: map['details']['status'] as String,
      duration: map['details']['duration'] as String,
      score: map['details']['score'] as String,
      genres: List<MapValues>.from(
        (map['details']['genres'] as List<dynamic>).map<MapValues>(
          (x) => MapValues.fromMap(x as Map<String, dynamic>),
        ),
      ),
      studios: List<MapValues>.from(
        (map['details']['studios'] as List<dynamic>).map<MapValues>(
          (x) => MapValues.fromMap(x as Map<String, dynamic>),
        ),
      ),
      producers: List<MapValues>.from(
        (map['details']['producers'] as List<dynamic>).map<MapValues>(
          (x) => MapValues.fromMap(x as Map<String, dynamic>),
        ),
      ),
      aired: map['details']['aired'] as String?,
      premiered: map['details']['premiered'] as String?,
      synonyms: map['details']['synonyms'] as String?,
      japanese: map['details']['japanese'] as String?,
      subCount: map['details']['sub_count'] as String?,
      dubCount: map['details']['dub_count'] as String?,
      episodeCount: map['details']['episode_count'] as String?,
      quality: map['details']['quality'] as String,
      rating: map['details']['rating'] as String,
      characters: List<Characters>.from(
        (map['characters'] as List<dynamic>).map<Characters>(
          (x) => Characters.fromMap(x as Map<String, dynamic>),
        ),
      ),
      seasons: List<Seasons>.from(
        (map['seasons'] as List<dynamic>).map<Seasons>(
          (x) => Seasons.fromMap(x as Map<String, dynamic>),
        ),
      ),
      related: List<Anime>.from(
        (map['related'] as List<dynamic>).map<Anime>(
          (x) => Anime.fromMap(x as Map<String, dynamic>),
        ),
      ),
      recommended: List<Anime>.from(
        (map['recommended'] as List<dynamic>).map<Anime>(
          (x) => Anime.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }
}
