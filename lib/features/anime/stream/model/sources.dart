class Sources {
  final String key;
  final String dataID;
  final String serverID;

  Sources({required this.key, required this.dataID, required this.serverID});

  factory Sources.fromMap(Map<String, dynamic> map) {
    return Sources(
      key:
          map['megacloud_data']['is_th_key'] ??
          map['megacloud_data']['data_dpi'] as String,
      dataID: map['megacloud_data']['data_id'] as String,
      serverID: map['server_data_id'] as String,
    );
  }
}

class Captions {
  final String link;
  final String language;

  Captions({required this.link, required this.language});

  factory Captions.fromMap(Map<String, dynamic> map) {
    return Captions(
      link: map['file'] as String,
      language: map['label'] as String,
    );
  }
}

class TimeStamps {
  final int start;
  final int end;

  TimeStamps({required this.start, required this.end});

  factory TimeStamps.fromMap(Map<String, dynamic> map) {
    return TimeStamps(start: map['start'] as int, end: map['end'] as int);
  }
}

class SourceFile {
  final String fileURL;
  final String type;

  SourceFile({required this.fileURL, required this.type});

  factory SourceFile.fromMap(Map<String, dynamic> map) {
    return SourceFile(
      fileURL: map['file'] as String? ?? '',
      type: map['type'] as String? ?? '',
    );
  }
}

class VidSrcSource {
  final String dataID;
  final String combinedKey;
  final List<SourceFile> sources;
  final List<Captions> captions;
  final bool encrypted;
  final TimeStamps intro;
  final TimeStamps outro;
  final int server;

  VidSrcSource({
    required this.dataID,
    required this.combinedKey,
    required this.sources,
    required this.captions,
    required this.encrypted,
    required this.intro,
    required this.outro,
    required this.server,
  });

  factory VidSrcSource.fromMap(Map<String, dynamic> map) {
    return VidSrcSource(
      dataID: map['data_id'] as String? ?? '',
      combinedKey: map['combined_key'] as String? ?? '',
      sources: (map['sources'] as List<dynamic>? ?? [])
          .map((e) => SourceFile.fromMap(e as Map<String, dynamic>))
          .toList(),
      captions: (map['tracks'] as List<dynamic>? ?? [])
          .where((e) => (e as Map<String, dynamic>)['kind'] == 'captions')
          .map((e) => Captions.fromMap(e as Map<String, dynamic>))
          .toList(),
      encrypted: map['encrypted'] as bool? ?? false,
      intro: map['intro'] != null
          ? TimeStamps.fromMap(map['intro'] as Map<String, dynamic>)
          : TimeStamps(start: 0, end: 0),
      outro: map['outro'] != null
          ? TimeStamps.fromMap(map['outro'] as Map<String, dynamic>)
          : TimeStamps(start: 0, end: 0),
      server: map['server'] as int? ?? 0,
    );
  }
}

class Stream {
  final String quality;
  final int width;
  final int height;
  final int bandwidth;
  final String codecs;
  final double frameRate;
  final String url;

  Stream({
    required this.quality,
    required this.width,
    required this.height,
    required this.bandwidth,
    required this.codecs,
    required this.frameRate,
    required this.url,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'quality': quality,
      'width': width,
      'height': height,
      'bandwidth': bandwidth,
      'codecs': codecs,
      'frameRate': frameRate,
      'url': url,
    };
  }

  factory Stream.fromMap(Map<String, dynamic> map) {
    return Stream(
      quality: map['quality'] as String,
      width: map['width'] as int,
      height: map['height'] as int,
      bandwidth: map['bandwidth'] as int,
      codecs: map['codecs'] as String,
      frameRate: map['frame_rate'] as double,
      url: map['url'] as String,
    );
  }

}

class StreamSources {
  final String masterURL;
  final List<String> availableQualities;
  final List<Stream> streams;

  StreamSources({required this.masterURL, required this.availableQualities, required this.streams});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'masterURL': masterURL,
      'availableQualities': availableQualities,
      'streams': streams.map((x) => x.toMap()).toList(),
    };
  }

  factory StreamSources.fromMap(Map<String, dynamic> map) {
    return StreamSources(
      masterURL: map['master_url'] as String,
      availableQualities: List<String>.from((map['available_qualities'] as List<dynamic>)),
      streams: List<Stream>.from((map['all_streams'] as List<dynamic>).map<Stream>((x) => Stream.fromMap(x as Map<String,dynamic>),),),
    );
  }
}
