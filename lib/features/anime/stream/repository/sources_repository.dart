import 'dart:convert';
import 'package:shinobihaven/core/config/config.dart';
import 'package:shinobihaven/features/anime/stream/model/sources.dart';
import 'package:http/http.dart' as http;

class SourcesRepository {
  final String _baseURL = Config.apiBaseUrl;
  Future<Sources> getSources(String serverID) async {
    try {
      final response = await http.get(Uri.parse('$_baseURL/sources/$serverID'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Sources.fromMap(data);
      } else {
        throw Exception("Error occured while fetching data");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<VidSrcSource> getVidSrcSources(String dataID, String key) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseURL/vidsrc/sources?data_id=$dataID&combined_key=$key'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final vidSrc = VidSrcSource.fromMap(data);
        if (vidSrc.sources.isEmpty) {
          throw Exception("No video sources available. Please try another episode or server.");
        }
        return vidSrc;
      } else {
        throw Exception("Error occurred while fetching data");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Future<StreamSources> getStreams(String baseURL) async {
  //   try {
  //     final response = await http.get(
  //       Uri.parse(
  //         '$_baseURL/m3u8/process?m3u8_url=$baseURL&preferred_quality=best',
  //       ),
  //     );
  //     print(response.body);
  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       return StreamSources.fromMap(data);
  //     } else {
  //       throw Exception("Error occured while fetching data");
  //     }
  //   } catch (e, stack) {
  //     print(stack);
  //     throw Exception(e.toString());
  //   }
  // }
}
