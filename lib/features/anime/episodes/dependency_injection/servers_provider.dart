import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shinobihaven/features/anime/episodes/model/servers.dart';
import 'package:shinobihaven/features/anime/episodes/repository/servers_repository.dart';
import 'package:shinobihaven/features/anime/episodes/viewmodel/servers_viewmodel.dart';

final serversRepositoryProvider = Provider((ref) => ServersRepository());

final serversViewModelProvider = StateNotifierProvider.family<ServersViewmodel, AsyncValue<ServersData>, String>((ref, animeSlug) {
  final serversRepository = ref.watch(serversRepositoryProvider);
  return ServersViewmodel(serversRepository);
});