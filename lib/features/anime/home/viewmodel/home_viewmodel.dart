import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinobihaven/features/anime/home/model/home.dart';
import 'package:shinobihaven/features/anime/home/repository/home_repository.dart';

class HomeViewModel extends StateNotifier<AsyncValue<HomePageData>> {
  final HomeRepository _repository;
  HomeViewModel(this._repository) : super(const AsyncValue.loading());

  Future<void> loadHomePageData() async {
    state = AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.fetchHomePageData());
  }
}