import 'package:hive_flutter/hive_flutter.dart';

class SearchHistoryBoxFunction {
  SearchHistoryBoxFunction._internal();
  static final SearchHistoryBoxFunction _instance = SearchHistoryBoxFunction._internal();
  factory SearchHistoryBoxFunction() => _instance;

  static final Box _historyBox = Hive.box('history');

  static bool historyExists(String query) {
    return _historyBox.containsKey(query);
  }

  static void saveHistory(String query) {
    if (!historyExists(query)) {
      _historyBox.put(query, query);
    }
  }

  static void deleteHistory(String query) {
    if (historyExists(query)) {
      _historyBox.delete(query);
    }
  }

  static List<String> loadHistory() {
    return _historyBox.values.whereType<String>().toList();
  }

  static void clearHistory() {
    _historyBox.clear();
  }
}
