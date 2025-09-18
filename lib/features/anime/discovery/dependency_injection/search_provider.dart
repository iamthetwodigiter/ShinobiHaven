import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinobihaven/features/anime/discovery/model/search.dart';
import 'package:shinobihaven/features/anime/discovery/repository/search_repository.dart';
import 'package:shinobihaven/features/anime/discovery/viewmodel/search_viewmodel.dart';

final searchRepositoryProvider = Provider((ref) => SearchRepository());

final searchViewModelProvider =
    StateNotifierProvider<SearchViewModel, AsyncValue<Search>>((ref) {
      final searchRepository = ref.watch(searchRepositoryProvider);
      return SearchViewModel(searchRepository);
    });
