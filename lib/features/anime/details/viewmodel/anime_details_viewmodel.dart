import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinobihaven/features/anime/details/model/anime_details.dart';
import 'package:shinobihaven/features/anime/details/repository/anime_details_repository.dart';

class AnimeDetailsViewmodel extends StateNotifier<AsyncValue<AnimeDetails>> {
  final AnimeDetailsRepository _repo;
  AnimeDetailsViewmodel(this._repo) : super(AsyncValue.loading());

  Future<void> getAnimeDetailsData(String animeSlug) async {
    state = AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.getAnimeDetails(animeSlug));
  }
}