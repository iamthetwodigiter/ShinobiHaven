import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinobihaven/features/anime/stream/model/sources.dart';
import 'package:shinobihaven/features/anime/stream/repository/sources_repository.dart';
import 'package:shinobihaven/features/anime/stream/viewmodel/sources_viewmodel.dart';

final sourcesRepositoryProvider = Provider((ref) => SourcesRepository());

final sourcesViewModelProvider =
    StateNotifierProvider<SourcesViewmodel, AsyncValue<Sources>>((ref) {
      final sourcesRepository = ref.watch(sourcesRepositoryProvider);
      return SourcesViewmodel(sourcesRepository);
    });

final vidSrcSourcesProvider =
    StateNotifierProvider.family<
      VidSrcSourceViewModel,
      AsyncValue<VidSrcSource>,
      String
    >((ref, cacheKey) {
      final sourcesRepository = ref.watch(sourcesRepositoryProvider);
      return VidSrcSourceViewModel(sourcesRepository);
    });

// final streamProvider =
//     StateNotifierProvider<StreamViewModel, AsyncValue<StreamSources>>((ref) {
    //   final sourcesRepository = ref.watch(sourcesRepositoryProvider);
    //   return StreamViewModel(sourcesRepository);
    // });
