import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinobihaven/features/anime/common/model/anime.dart';
import 'package:shinobihaven/features/anime/discovery/model/search.dart';
import 'package:shinobihaven/features/anime/discovery/repository/search_repository.dart';

class SearchViewModel extends StateNotifier<AsyncValue<Search>> {
  final SearchRepository _repo;
  SearchViewModel(this._repo) : super(AsyncValue.loading());

  Future<void> searchAnime(
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
    state = AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.searchAnime(
        query,
        type: type,
        status: status,
        rating: rating,
        score: score,
        season: season,
        language: language,
        sort: sort,
        genres: genres,
        page: page,
      ),
    );
  }
}

class SearchSuggestionsViewModel
    extends StateNotifier<AsyncValue<List<Anime>>> {
  final SearchRepository _repo;
  SearchSuggestionsViewModel(this._repo) : super(AsyncValue.loading());

  Future<void> getSearchSuggestions() async {
    state = AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.getSearchSuggestions());
  }
}
