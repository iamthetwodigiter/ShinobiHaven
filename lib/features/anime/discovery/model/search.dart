import 'package:shinobihaven/features/anime/common/model/anime.dart';
import 'package:shinobihaven/features/anime/discovery/model/pagination.dart';

class Search {
  final Map<String, dynamic>? appliedFilters;
  final String query;
  final int page;
  final List<Anime> animes;
  final Pagination pagination;

  Search({
    required this.appliedFilters,
    required this.query,
    required this.page,
    required this.animes,
    required this.pagination,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'appliedFilters': appliedFilters,
      'query': query,
      'page': page,
      'animes': animes.map((x) => x.toMap()).toList(),
      'pagination': pagination,
    };
  }

  factory Search.fromMap(Map<String, dynamic> map) {
    return Search(
      appliedFilters: Map<String, dynamic>.from(
        (map['applied_filters'] as Map<String, dynamic>),
      ),
      query: map['query'] as String,
      page: map['page'] as int,
      animes: List<Anime>.from(
        (map['anime_list'] as List<dynamic>).map<Anime>(
          (x) => Anime.fromMap(x as Map<String, dynamic>),
        ),
      ),
      pagination: Pagination.fromMap(map['pagination'] as Map<String, dynamic>),
    );
  }
}
