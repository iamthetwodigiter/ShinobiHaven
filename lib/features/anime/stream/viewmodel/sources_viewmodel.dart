import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shinobihaven/features/anime/stream/model/sources.dart';
import 'package:shinobihaven/features/anime/stream/repository/sources_repository.dart';

class SourcesViewmodel extends StateNotifier<AsyncValue<Sources>> {
  final SourcesRepository _repo;
  SourcesViewmodel(this._repo) : super(AsyncValue.loading());

  Future<void> getSources(String serverID) async {
    state = AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.getSources(serverID));
  }
}

class VidSrcSourceViewModel extends StateNotifier<AsyncValue<VidSrcSource>> {
  final SourcesRepository _repo;
  VidSrcSourceViewModel(this._repo) : super(AsyncValue.loading());

  Future<void> getVidSrcSources(String dataID, String key) async {
    state = AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.getVidSrcSources(dataID, key));
  }
}

// class StreamViewModel extends StateNotifier<AsyncValue<StreamSources>> {
//   final SourcesRepository _repo;
//   StreamViewModel(this._repo) : super(AsyncValue.loading());

//   Future<void> getStreams(String baseURL) async {
//     state = AsyncValue.loading();
//     state = await AsyncValue.guard(() => _repo.getStreams(baseURL));
//   }
// }
