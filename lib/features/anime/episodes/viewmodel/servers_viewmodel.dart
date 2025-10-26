import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinobihaven/features/anime/episodes/model/servers.dart';
import 'package:shinobihaven/features/anime/episodes/repository/servers_repository.dart';

class ServersViewmodel extends StateNotifier<AsyncValue<ServersData>> {
  final ServersRepository _repo;
  ServersViewmodel(this._repo) : super(AsyncValue.loading());

  Future<void> fetchServers(String episodeID) async {
    state = AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.fetchServers(episodeID));
  }
}
