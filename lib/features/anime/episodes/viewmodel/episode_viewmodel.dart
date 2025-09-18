import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinobihaven/features/anime/episodes/model/episodes.dart';
import 'package:shinobihaven/features/anime/episodes/repository/episodes_repository.dart';

class EpisodeViewmodel extends StateNotifier<AsyncValue<List<Episodes>>> {
  final EpisodesRepository _repo;
  EpisodeViewmodel(this._repo) : super(AsyncValue.loading());

  Future<void> loadEpisodes(String animeSlug) async {
    state = AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.loadEpisodes(animeSlug));
  }
}