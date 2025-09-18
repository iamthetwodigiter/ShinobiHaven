class Server {
  final String serverName;
  final String serverID;
  final String dataID;
  final String type;

  Server({
    required this.serverName,
    required this.serverID,
    required this.dataID,
    required this.type,
  });

  Server copyWith({
    String? serverName,
    String? serverID,
    String? dataID,
    String? type,
  }) {
    return Server(
      serverName: serverName ?? this.serverName,
      serverID: serverID ?? this.serverID,
      dataID: dataID ?? this.dataID,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'serverName': serverName,
      'serverID': serverID,
      'dataID': dataID,
      'type': type,
    };
  }

  factory Server.fromMap(Map<String, dynamic> map) {
    return Server(
      serverName: map['server_name'] as String,
      serverID: map['server_id'] as String,
      dataID: map['data_id'] as String,
      type: map['type'] as String,
    );
  }
}

class ServersData {
  final List<Server> sub;
  final List<Server> dub;
  final List<Server> raw;

  ServersData({required this.sub, required this.dub, required this.raw});

  ServersData copyWith({
    List<Server>? sub,
    List<Server>? dub,
    List<Server>? raw,
  }) {
    return ServersData(
      sub: sub ?? this.sub,
      dub: dub ?? this.dub,
      raw: raw ?? this.raw,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'sub': sub.map((x) => x.toMap()).toList(),
      'dub': dub.map((x) => x.toMap()).toList(),
      'raw': raw.map((x) => x.toMap()).toList(),
    };
  }

  factory ServersData.fromMap(Map<String, dynamic> map) {
    return ServersData(
      sub: List<Server>.from(
        (map['sub'] as List<dynamic>).map<Server>(
          (x) => Server.fromMap(x as Map<String, dynamic>),
        ),
      ),
      dub: List<Server>.from(
        (map['dub'] as List<dynamic>).map<Server>(
          (x) => Server.fromMap(x as Map<String, dynamic>),
        ),
      ),
      raw: List<Server>.from(
        (map['raw'] as List<dynamic>).map<Server>(
          (x) => Server.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }
}
