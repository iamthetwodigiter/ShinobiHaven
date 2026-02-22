import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shinobihaven/features/anime/common/model/anime.dart';
import 'package:shinobihaven/features/anime/discovery/model/search.dart';
import 'package:shinobihaven/features/anime/discovery/repository/search_repository.dart';
import 'package:shinobihaven/features/anime/discovery/viewmodel/search_viewmodel.dart';

final searchRepositoryProvider = Provider((ref) => SearchRepository());

final searchViewModelProvider =
    StateNotifierProvider<SearchViewModel, AsyncValue<Search>>((ref) {
      final searchRepository = ref.watch(searchRepositoryProvider);
      return SearchViewModel(searchRepository);
    });

final searchSuggestionsViewModelProvider =
    StateNotifierProvider<SearchSuggestionsViewModel, AsyncValue<List<Anime>>>((
      ref,
    ) {
      final searchRepository = ref.watch(searchRepositoryProvider);
      return SearchSuggestionsViewModel(searchRepository);
    });
