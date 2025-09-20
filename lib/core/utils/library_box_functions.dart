import 'package:hive_flutter/hive_flutter.dart';
import 'package:shinobihaven/features/anime/common/model/anime.dart';
import 'package:shinobihaven/features/anime/episodes/model/episodes.dart';

class LibraryBoxFunction {
  LibraryBoxFunction._internal();
  static final LibraryBoxFunction _instance = LibraryBoxFunction._internal();
  factory LibraryBoxFunction() => _instance;

  static Box get _libraryBox => Hive.box('library');

  static void clearLibrary() {
    _libraryBox.clear();
  }

  static String? getLastWatchedEpisode(String animeSlug) {
    final lastWatchedMap = _libraryBox.get('lastWatched');
    if (lastWatchedMap is Map) {
      return lastWatchedMap[animeSlug]?.toString();
    }
    return null;
  }

  static void markLastWatchedEpisode(String animeSlug, String episodeNumber) {
    final existingData = _libraryBox.get('lastWatched');
    final Map<String, String> lastWatchedMap = {};

    if (existingData is Map) {
      existingData.forEach((key, value) {
        lastWatchedMap[key.toString()] = value.toString();
      });
    }
    lastWatchedMap[animeSlug] = episodeNumber;
    _libraryBox.put('lastWatched', lastWatchedMap);
  }

  static Episodes? getLastWatchedEpisodeObject(
    String animeSlug,
    List<Episodes> episodes,
  ) {
    final lastWatchedEpisodeNumber = getLastWatchedEpisode(animeSlug);
    if (lastWatchedEpisodeNumber == null) return null;
    try {
      final foundEpisode = episodes.firstWhere(
        (episode) => episode.episodeNumber == lastWatchedEpisodeNumber,
      );
      return foundEpisode;
    } catch (e) {
      return null;
    }
  }

  static Episodes? getFirstEpisode(List<Episodes> episodes) {
    if (episodes.isEmpty) return null;
    return episodes.first;
  }

  static List<Map<String, List<String>>> _getLibraryList() {
    final raw = _libraryBox.get('library_list');
    if (raw is List) {
      return raw
          .map<Map<String, List<String>>>((e) {
            if (e is Map) {
              final mapped = <String, List<String>>{};
              e.forEach((k, v) {
                if (v is List) {
                  mapped[k.toString()] = v.cast<String>().toList();
                } else {
                  mapped[k.toString()] = <String>[];
                }
              });
              return mapped;
            }
            return <String, List<String>>{};
          })
          .where((m) => m.isNotEmpty)
          .toList();
    }
    return <Map<String, List<String>>>[];
  }

  static void _saveLibraryList(List<Map<String, List<String>>> list) {
    _libraryBox.put('library_list', list);
  }

  static bool animeExistsInLibrary(Anime anime) {
    final list = _getLibraryList();
    for (final map in list) {
      if (map.containsKey(anime.slug)) return true;
    }
    return false;
  }

  static void addWatchCount(Anime anime, String episodeID) {
    final raw = _libraryBox.get('watched');
    final Map<String, dynamic> watchedMap = (raw is Map)
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};

    final dynamic existing = watchedMap[anime.slug];
    final Map<String, int> episodeMap = <String, int>{};

    if (existing is Map) {
      if (existing.containsKey('episodes')) {
        final episodesRaw = existing['episodes'];
        if (episodesRaw is Map) {
          episodesRaw.forEach((k, v) {
            final key = k.toString();
            final val = (v is int) ? v : int.tryParse(v.toString()) ?? 0;
            episodeMap[key] = val;
          });
        } else if (episodesRaw is List) {
          for (final e in episodesRaw) {
            final key = e.toString();
            episodeMap[key] = (episodeMap[key] ?? 0) + 1;
          }
        } else if (episodesRaw != null) {
          final key = episodesRaw.toString();
          episodeMap[key] = (episodeMap[key] ?? 0) + 1;
        }
      } else {
        existing.forEach((k, v) {
          final key = k.toString();
          final val = (v is int) ? v : int.tryParse(v.toString()) ?? 0;
          episodeMap[key] = val;
        });
      }
    } else if (existing is List) {
      for (final e in existing) {
        final key = e.toString();
        episodeMap[key] = (episodeMap[key] ?? 0) + 1;
      }
    } else if (existing != null) {
      final key = existing.toString();
      episodeMap[key] = (episodeMap[key] ?? 0) + 1;
    }

    episodeMap[episodeID] = (episodeMap[episodeID] ?? 0) + 1;

    watchedMap[anime.slug] = {'anime': anime, 'episodes': episodeMap};

    _libraryBox.put('watched', watchedMap);
  }

  static void addToLibrary(Anime anime, String episodeID) {
    final list = _getLibraryList();
    bool updated = false;

    for (var map in list) {
      if (map.containsKey(anime.slug)) {
        final episodes = map[anime.slug]!;
        if (!episodes.contains(episodeID)) episodes.add(episodeID);
        updated = true;
        break;
      }
    }

    if (!updated) {
      list.add({
        anime.slug: [episodeID],
      });
    }

    _saveLibraryList(list);

    final existing = _libraryBox.get(anime.slug);
    if (existing is Map) {
      final episodes = (existing['episodes'] is List<String>)
          ? List<String>.from(existing['episodes'])
          : <String>[];
      if (!episodes.contains(episodeID)) episodes.add(episodeID);
      _libraryBox.put(anime.slug, {'anime': anime, 'episodes': episodes});
    } else {
      _libraryBox.put(anime.slug, {
        'anime': anime,
        'episodes': [episodeID],
      });
    }

    addWatchCount(anime, episodeID);
  }

  static void removeFromLibrary(Anime anime) {
    final list = _getLibraryList();
    list.removeWhere((map) => map.containsKey(anime.slug));
    _saveLibraryList(list);

    if (_libraryBox.containsKey(anime.slug)) {
      _libraryBox.delete(anime.slug);
    }
  }

  static Map<String, Map<String, dynamic>> getWatchedMap() {
    final raw = _libraryBox.get('watched');
    final Map<String, Map<String, dynamic>> out = {};

    if (raw is Map) {
      raw.forEach((k, v) {
        final slug = k.toString();
        Anime? animeObj;
        final Map<String, int> episodeMap = {};

        if (v is Map && v.containsKey('anime') && v['anime'] is Anime) {
          animeObj = v['anime'] as Anime;
        } else {
          animeObj = getAnimeBySlug(slug);
        }

        if (v is Map) {
          final episodesRaw = v.containsKey('episodes') ? v['episodes'] : v;
          if (episodesRaw is Map) {
            episodesRaw.forEach((ek, ev) {
              final eid = ek.toString();
              final count = (ev is int) ? ev : int.tryParse(ev.toString()) ?? 0;
              episodeMap[eid] = count;
            });
          } else if (episodesRaw is List) {
            for (final e in episodesRaw) {
              final eid = e.toString();
              episodeMap[eid] = (episodeMap[eid] ?? 0) + 1;
            }
          } else if (episodesRaw != null) {
            episodeMap[episodesRaw.toString()] =
                (episodeMap[episodesRaw.toString()] ?? 0) + 1;
          }
        } else if (v is List) {
          for (final e in v) {
            final eid = e.toString();
            episodeMap[eid] = (episodeMap[eid] ?? 0) + 1;
          }
        } else if (v != null) {
          episodeMap[v.toString()] = (episodeMap[v.toString()] ?? 0) + 1;
        }

        out[slug] = {'anime': animeObj, 'episodes': episodeMap};
      });
    }

    return out;
  }

  static Map<String, int> getWatchedForAnime(String slug) {
    final raw = getWatchedMap();
    final entry = raw[slug];
    if (entry == null) return <String, int>{};

    if (entry is Map<String, int>) {
      return Map<String, int>.from(entry);
    }

    final dynamic episodesRaw = entry.containsKey('episodes')
        ? entry['episodes']
        : entry;
    if (episodesRaw is Map) {
      final Map<String, int> out = {};
      episodesRaw.forEach((k, v) {
        out[k.toString()] = (v is int) ? v : int.tryParse(v.toString()) ?? 0;
      });
      return out;
    }

    return <String, int>{};
  }

  static int getEpisodeWatchCount(String slug, String episodeID) {
    final animeMap = getWatchedForAnime(slug);
    return animeMap[episodeID] ?? 0;
  }

  static int getTotalWatchCountForAnime(String slug) {
    final animeMap = getWatchedForAnime(slug);
    return animeMap.values.fold(0, (prev, v) => prev + v);
  }

  static Map<Anime, Map<String, int>> getWatchedAsObjects() {
    final raw = _libraryBox.get('watched');
    final Map<Anime, Map<String, int>> out = {};

    if (raw is Map) {
      raw.forEach((k, v) {
        final slug = k.toString();
        Anime? animeObj;
        Map<String, int> episodeMap = {};

        if (v is Map && v.containsKey('anime') && v['anime'] is Anime) {
          animeObj = v['anime'] as Anime;
          final episodesRaw = v['episodes'];
          if (episodesRaw is Map) {
            episodesRaw.forEach((ek, ev) {
              final eid = ek.toString();
              final count = (ev is int) ? ev : int.tryParse(ev.toString()) ?? 0;
              episodeMap[eid] = count;
            });
          } else if (episodesRaw is List) {
            for (final e in episodesRaw) {
              final eid = e.toString();
              episodeMap[eid] = (episodeMap[eid] ?? 0) + 1;
            }
          }
        } else {
          final resolved = getAnimeBySlug(slug);
          if (resolved != null) {
            animeObj = resolved;
          }
          if (v is Map) {
            v.forEach((ek, ev) {
              final eid = ek.toString();
              final count = (ev is int) ? ev : int.tryParse(ev.toString()) ?? 0;
              episodeMap[eid] = count;
            });
          } else if (v is List) {
            for (final e in v) {
              final eid = e.toString();
              episodeMap[eid] = (episodeMap[eid] ?? 0) + 1;
            }
          } else if (v != null) {
            episodeMap[v.toString()] = (episodeMap[v.toString()] ?? 0) + 1;
          }
        }

        if (animeObj != null) {
          out[animeObj] = episodeMap;
        }
      });
    }

    return out;
  }

  static void createCustomCollectionInLibrary(String collectionName) {
    final collections = _getCollectionsMap();
    if (!collections.containsKey(collectionName)) {
      collections[collectionName] = <String>[];
      _saveCollectionsMap(collections);
    }
  }

  static void deleteCollection(String collectionName) {
    final collections = _getCollectionsMap();
    if (collections.containsKey(collectionName)) {
      collections.remove(collectionName);
      _saveCollectionsMap(collections);
    }
  }

  static Map<String, List<String>> _getCollectionsMap() {
    final raw = _libraryBox.get('collections');
    if (raw is Map) {
      final Map<String, List<String>> out = {};
      raw.forEach((k, v) {
        if (v is List) {
          out[k.toString()] = v.cast<String>().toList();
        } else if (v is String) {
          out[k.toString()] = [v];
        } else {
          out[k.toString()] = <String>[];
        }
      });
      return out;
    }
    if (raw is List) {
      final Map<String, List<String>> out = {};
      for (final e in raw) {
        if (e is Map) {
          e.forEach((k, v) {
            out[k.toString()] = (v is List)
                ? v.cast<String>().toList()
                : <String>[];
          });
        }
      }
      return out;
    }

    return <String, List<String>>{};
  }

  static void _saveCollectionsMap(Map<String, List<String>> map) {
    _libraryBox.put('collections', map);
  }

  static List<String> getCollections() {
    return _getCollectionsMap().keys.toList();
  }

  static bool collectionExists(String name) {
    return _getCollectionsMap().containsKey(name);
  }

  static List<Anime> getAnimesInCollection(String collectionName) {
    final map = _getCollectionsMap();
    final slugs = map[collectionName] != null
        ? List<String>.from(map[collectionName]!)
        : <String>[];
    final List<Anime> animes = [];
    for (final slug in slugs) {
      final anime = getAnimeBySlug(slug);
      if (anime != null) {
        animes.add(anime);
      }
    }
    return animes;
  }

  static void addAnimeToCollection(String collectionName, Anime anime) {
    final map = _getCollectionsMap();
    final list = map.putIfAbsent(collectionName, () => <String>[]);
    if (!list.contains(anime.slug)) {
      list.add(anime.slug);
      _saveCollectionsMap(map);
    }

    final existing = _libraryBox.get(anime.slug);
    if (existing is! Map || existing['anime'] is! Anime) {
      _libraryBox.put(anime.slug, {'anime': anime, 'episodes': <String>[]});
    }
  }

  static void removeAnimeFromCollection(String collectionName, Anime anime) {
    final map = _getCollectionsMap();
    if (!map.containsKey(collectionName)) return;
    final list = map[collectionName]!;
    list.removeWhere((s) => s == anime.slug);
    if (list.isEmpty) {
      map.remove(collectionName);
    }
    _saveCollectionsMap(map);
  }

  static List<String> libraryBoxKeys() {
    final list = _getLibraryList();
    final keys = <String>[];
    for (final map in list) {
      keys.addAll(map.keys);
    }
    return keys;
  }

  static Anime? getAnimeBySlug(String slug) {
    final data = _libraryBox.get(slug);
    if (data is Map && data['anime'] is Anime) {
      return data['anime'] as Anime;
    }
    return null;
  }

  static List<String> getEpisodeIDBySlug(String slug) {
    final list = _getLibraryList();
    for (final map in list) {
      if (map.containsKey(slug)) {
        return List<String>.from(map[slug]!);
      }
    }

    final data = _libraryBox.get(slug);
    if (data is Map && data['episodes'] is List<String>) {
      return List<String>.from(data['episodes'] as List<String>);
    }

    return <String>[];
  }
}
