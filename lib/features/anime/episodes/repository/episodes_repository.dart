import 'dart:convert';

import 'package:shinobihaven/core/config/config.dart';
import 'package:shinobihaven/features/anime/episodes/model/episodes.dart';
import 'package:http/http.dart' as http;

class EpisodesRepository {
  final String _baseURL = '${Config.apiBaseUrl}/episodes';
  Future<List<Episodes>> loadEpisodes(String animeSlug) async {
    try {
      final response = await http.get(Uri.parse('$_baseURL/$animeSlug'));
      if(response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['episodes'];
        final episodes = data.map((episode) => Episodes.fromMap(episode)).toList();
        return episodes;
      } else {
        throw Exception("Error occured while fetching data");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}