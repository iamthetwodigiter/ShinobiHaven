import 'dart:convert';

import 'package:shinobihaven/core/config/config.dart';
import 'package:shinobihaven/features/anime/home/model/home.dart';
import 'package:http/http.dart' as http;

class HomeRepository {
  final String _baseURL = '${Config.apiBaseUrl}/home';
  Future<HomePageData> fetchHomePageData() async {
    try {
      final response = await http.get(Uri.parse(_baseURL));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final homePageData = HomePageData.fromMap(data);
        return homePageData;
      }
      throw Exception("Error occured while fetching data");
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
