import 'package:hive_flutter/hive_flutter.dart';
import 'package:shinobihaven/features/anime/common/model/anime.dart';

class CollectionsBoxFunction {
  CollectionsBoxFunction._internal();
  static final CollectionsBoxFunction _instance = CollectionsBoxFunction._internal();
  factory CollectionsBoxFunction() => _instance;

  static Box get _collectionsBox => Hive.box('collections');
  // contains two keys
  // 1. anime [entire anime model]
  // 2. collection data [slug with date]

  static bool animeExistsInCollections(Anime anime) {
    return _collectionsBox.containsKey(anime.slug);
  }

  
}
