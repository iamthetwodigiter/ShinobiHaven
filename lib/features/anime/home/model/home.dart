import 'package:shinobihaven/features/anime/common/model/anime.dart';

class HomePageData {
  final List<Anime> spotlightAnimes;
  final List<Anime> trendingAnimes;
  final List<Anime> mostPopularAnimes;
  final List<Anime> mostFavoriteAnimes;
  final List<Anime> latestCompletedAnimes;
  final List<Anime> latestEpisodesAnimes;
  final List<Anime> topTenAnimes;

  HomePageData({
    required this.spotlightAnimes,
    required this.trendingAnimes,
    required this.mostPopularAnimes,
    required this.mostFavoriteAnimes,
    required this.latestCompletedAnimes,
    required this.latestEpisodesAnimes,
    required this.topTenAnimes,
  });

  HomePageData copyWith({
    List<Anime>? spotlightAnimes,
    List<Anime>? trendingAnimes,
    List<Anime>? mostPopularAnimes,
    List<Anime>? mostFavoriteAnimes,
    List<Anime>? latestCompletedAnimes,
    List<Anime>? latestEpisodesAnimes,
    List<Anime>? topTenAnimes,
  }) {
    return HomePageData(
      spotlightAnimes: spotlightAnimes ?? this.spotlightAnimes,
      trendingAnimes: trendingAnimes ?? this.trendingAnimes,
      mostPopularAnimes: mostPopularAnimes ?? this.mostPopularAnimes,
      mostFavoriteAnimes: mostFavoriteAnimes ?? this.mostFavoriteAnimes,
      latestCompletedAnimes:
          latestCompletedAnimes ?? this.latestCompletedAnimes,
      latestEpisodesAnimes: latestEpisodesAnimes ?? this.latestEpisodesAnimes,
      topTenAnimes: topTenAnimes ?? this.topTenAnimes,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'spotlightAnimes': spotlightAnimes.map((x) => x.toMap()).toList(),
      'trendingAnimes': trendingAnimes.map((x) => x.toMap()).toList(),
      'mostPopularAnimes': mostPopularAnimes.map((x) => x.toMap()).toList(),
      'mostFavoriteAnimes': mostFavoriteAnimes.map((x) => x.toMap()).toList(),
      'latestCompletedAnimes': latestCompletedAnimes
          .map((x) => x.toMap())
          .toList(),
      'latestEpisodesAnimes': latestEpisodesAnimes
          .map((x) => x.toMap())
          .toList(),
      'topTenAnimes': topTenAnimes.map((x) => x.toMap()).toList(),
    };
  }

  factory HomePageData.fromMap(Map<String, dynamic> map) {
    return HomePageData(
      spotlightAnimes: List<Anime>.from(
        (map['spotlight'] as List<dynamic>).map<Anime>(
          (x) => Anime.fromMap(x as Map<String, dynamic>),
        ),
      ),
      trendingAnimes: List<Anime>.from(
        (map['trending'] as List<dynamic>).map<Anime>(
          (x) => Anime.fromMap(x as Map<String, dynamic>),
        ),
      ),
      mostPopularAnimes: List<Anime>.from(
        (map['most_popular'] as List<dynamic>).map<Anime>(
          (x) => Anime.fromMap(x as Map<String, dynamic>),
        ),
      ),
      mostFavoriteAnimes: List<Anime>.from(
        (map['most_favorite'] as List<dynamic>).map<Anime>(
          (x) => Anime.fromMap(x as Map<String, dynamic>),
        ),
      ),
      latestCompletedAnimes: List<Anime>.from(
        (map['latest_completed'] as List<dynamic>).map<Anime>(
          (x) => Anime.fromMap(x as Map<String, dynamic>),
        ),
      ),
      latestEpisodesAnimes: List<Anime>.from(
        (map['latest_episode'] as List<dynamic>).map<Anime>(
          (x) => Anime.fromMap(x as Map<String, dynamic>),
        ),
      ),
      topTenAnimes: List<Anime>.from(
        (map['top_10'] as List<dynamic>).map<Anime>(
          (x) => Anime.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }
}
