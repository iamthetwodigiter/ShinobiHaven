import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shinobihaven/features/download/model/downloads_state.dart';
import 'package:shinobihaven/features/download/repository/downloads_repository.dart';
import 'package:shinobihaven/features/download/viewmodel/downloads_viewmodel.dart';

final downloadsRepositoryProvider = Provider((ref) => DownloadsRepository());

final downloadsViewModelProvider =
    StateNotifierProvider<DownloadsViewModel, DownloadsState>((ref) {
      final repository = ref.watch(downloadsRepositoryProvider);
      return DownloadsViewModel(repository);
    });
