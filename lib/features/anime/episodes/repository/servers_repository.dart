import 'dart:convert';

import 'package:shinobihaven/core/config/config.dart';
import 'package:shinobihaven/features/anime/episodes/model/servers.dart';
import 'package:http/http.dart' as http;

class ServersRepository {
  final String _baseURL = '${Config.apiBaseUrl}/servers';
  Future<ServersData> fetchServers(String episodeID) async {
    try {
      final response = await http.get(Uri.parse('$_baseURL/$episodeID'));
      if (response.statusCode == 200) {
        final servers = jsonDecode(response.body)['servers'];
        return ServersData.fromMap(servers);
      } else {
        throw Exception("Failed to fetch servers. Try again later");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
