import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shinobihaven/features/anime/episodes/model/episodes.dart';
import 'package:shinobihaven/features/anime/episodes/repository/episodes_repository.dart';
import 'package:shinobihaven/features/anime/episodes/viewmodel/episode_viewmodel.dart';

final episodesRepositoryProvider = Provider((ref) => EpisodesRepository());

final episodesViewModelProvider =
    StateNotifierProvider<EpisodeViewmodel, AsyncValue<List<Episodes>>>((ref) {
      final episodesRepository = ref.watch(episodesRepositoryProvider);
      return EpisodeViewmodel(episodesRepository);
    });
