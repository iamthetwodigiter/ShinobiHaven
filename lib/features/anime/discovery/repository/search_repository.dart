import 'dart:convert';
import 'package:shinobihaven/core/config/config.dart';
import 'package:shinobihaven/features/anime/common/model/anime.dart';
import 'package:shinobihaven/features/anime/discovery/model/search.dart';
import 'package:http/http.dart' as http;

class SearchRepository {
  final String _baseURL = '${Config.apiBaseUrl}filter/anime';
  Future<Search> searchAnime(
    String query, {
    String? type,
    String? status,
    String? rating,
    String? score,
    String? season,
    String? language,
    String? sort,
    String? genres,
    int page = 1,
  }) async {
    try {
      String url = '$_baseURL?query=${query.replaceAll(" ", "%20")}';
      print(url);
      if (type != null) url += '&type=$type';
      if (status != null) url += '&status=$status';
      if (rating != null) url += '&rating=$rating';
      if (score != null) url += '&score=$score';
      if (season != null) url += '&season=$season';
      if (language != null) url += '&language=$language';
      if (sort != null) url += '&sort=$sort';
      if (genres != null) url += '&genres=$genres';
      url += '&page=$page';
      final response = await http.get(Uri.parse(url));
      print(response.body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Search.fromMap(data);
      }
      throw Exception("Error occured while fetching data");
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<List<Anime>> getSearchSuggestions() async {
    try {
      String url = '${Config.apiBaseUrl}/trending';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['trending'] as List)
            .map((anime) => Anime.fromMap(anime))
            .toList();
      } else {
        throw Exception("Error occured while fetching data");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
