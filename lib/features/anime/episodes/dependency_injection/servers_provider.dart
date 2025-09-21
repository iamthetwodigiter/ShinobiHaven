import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinobihaven/features/anime/episodes/model/servers.dart';
import 'package:shinobihaven/features/anime/episodes/repository/servers_repository.dart';
import 'package:shinobihaven/features/anime/episodes/viewmodel/servers_viewmode.dart';

final serversRepositoryProvider = Provider((ref) => ServersRepository());

final serversViewModelProvider = StateNotifierProvider.family<ServersViewmode, AsyncValue<ServersData>, String>((ref, animeSlug) {
  final serversRepository = ref.watch(serversRepositoryProvider);
  return ServersViewmode(serversRepository);
});