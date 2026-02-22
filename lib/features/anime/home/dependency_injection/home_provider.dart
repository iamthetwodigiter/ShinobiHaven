import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shinobihaven/features/anime/home/model/home.dart';
import 'package:shinobihaven/features/anime/home/repository/home_repository.dart';
import 'package:shinobihaven/features/anime/home/viewmodel/home_viewmodel.dart';

final homeRepositoryProvider = Provider((ref) => HomeRepository());

final homeViewModelProvider =
    StateNotifierProvider<HomeViewModel, AsyncValue<HomePageData>>((ref) {
      final homeRepository = ref.watch(homeRepositoryProvider);
      return HomeViewModel(homeRepository);
    });
