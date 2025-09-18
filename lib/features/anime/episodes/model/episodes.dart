class Episodes {
  final String episodeNumber;
  final String title;
  final String jname;
  final String episodeID;
  final String link;

  Episodes({
    required this.episodeNumber,
    required this.title,
    required this.jname,
    required this.episodeID,
    required this.link,
  });

  Episodes copyWith({
    String? episodeNumber,
    String? title,
    String? jname,
    String? episodeID,
    String? link,
  }) {
    return Episodes(
      episodeNumber: episodeNumber ?? this.episodeNumber,
      title: title ?? this.title,
      jname: jname ?? this.jname,
      episodeID: episodeID ?? this.episodeID,
      link: link ?? this.link,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'episodeNumber': episodeNumber,
      'title': title,
      'jname': jname,
      'episodeID': episodeID,
      'link': link,
    };
  }

  factory Episodes.fromMap(Map<String, dynamic> map) {
    return Episodes(
      episodeNumber: map['episode_number'] as String,
      title: map['title'] as String,
      jname: map['jname'] as String,
      episodeID: map['episode_id'] as String,
      link: map['watch_url'] as String,
    );
  }
}