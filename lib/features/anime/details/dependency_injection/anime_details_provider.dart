import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shinobihaven/features/anime/details/model/anime_details.dart';
import 'package:shinobihaven/features/anime/details/repository/anime_details_repository.dart';
import 'package:shinobihaven/features/anime/details/viewmodel/anime_details_viewmodel.dart';

final animeDetailsRepositoryProvider = Provider(
  (ref) => AnimeDetailsRepository(),
);

final animeDetailsViewModelProvider =
    StateNotifierProvider<AnimeDetailsViewmodel, AsyncValue<AnimeDetails>>((
      ref,
    ) {
      final animeDetailsRepository = ref.watch(animeDetailsRepositoryProvider);
      return AnimeDetailsViewmodel(animeDetailsRepository);
    });
