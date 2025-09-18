import 'package:hive_flutter/hive_flutter.dart';
import 'package:shinobihaven/features/anime/common/model/anime.dart';

class FavoritesBoxFunctions {
  FavoritesBoxFunctions._internal();
  static final FavoritesBoxFunctions _instance = FavoritesBoxFunctions._internal();
  factory FavoritesBoxFunctions() => _instance;

  static final Box _favoritesBox = Hive.box('favorites');

  static bool isFavorite(String animeSlug) {
    return _favoritesBox.containsKey(animeSlug);
  }

  static bool addToFavorites(Anime anime) {
    if (!isFavorite(anime.slug)) {
      _favoritesBox.put(anime.slug, anime);
      return true;
    } else {
      _favoritesBox.delete(anime.slug);
      return false;
    }
  }

  static List<Anime> listFavorites() {
    return _favoritesBox.values.whereType<Anime>().toList();
  }
}
