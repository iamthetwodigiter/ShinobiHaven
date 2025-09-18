import 'dart:convert';

import 'package:shinobihaven/core/config/config.dart';
import 'package:shinobihaven/features/anime/details/model/anime_details.dart';
import 'package:http/http.dart' as http;

class AnimeDetailsRepository {
  final String _baseURL = '${Config.apiBaseUrl}/anime';
  Future<AnimeDetails> getAnimeDetails(String animeSlug) async {
    try {
      final response = await http.get(Uri.parse('$_baseURL/$animeSlug'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final animeDetailsData = AnimeDetails.fromMap(data);
        return animeDetailsData;
      }
      throw Exception("Error occured while fetching data");
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
