import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shinobihaven/core/theme/app_theme.dart';
import 'package:shinobihaven/features/anime/common/view/widgets/anime_card.dart';
import 'package:shinobihaven/features/anime/home/dependency_injection/home_provider.dart';
import 'package:shinobihaven/features/anime/home/view/widgets/spotlight_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchHomePageData();
    });
  }

  void _fetchHomePageData() {
    ref.read(homeViewModelProvider.notifier).loadHomePageData();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final homePageData = ref.watch(homeViewModelProvider);

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppTheme.transparentColor,
        actionsPadding: EdgeInsets.symmetric(horizontal: 25),
        actions: [
          // InkWell(
          //   child: Container(
          //     padding: EdgeInsets.all(5),
          //     margin: EdgeInsets.only(left: 10),
          //     decoration: BoxDecoration(
          //       color: AppTheme.blackGradient.withValues(alpha: 0.35),
          //       shape: BoxShape.circle,
          //     ),
          //     child: Icon(Icons.settings, color: AppTheme.whiteGradient),
          //   ),
          // ),
          // Expanded(
          //   child: SwitchListTile.adaptive(
          //     value: _isAnimeMode,
          //     enableFeedback: true,
          //     contentPadding: EdgeInsets.zero,
          //     activeTrackColor: AppTheme.gradient1,
          //     inactiveThumbColor: AppTheme.blackGradient,
          //     onChanged: (val) {
          //       setState(() {
          //         _isAnimeMode = val;
          //       });
          //     },
          //     title: Text(
          //       'Anime Mode',
          //       style: TextStyle(
          //         color: AppTheme.whiteGradient,
          //         fontSize: 18,
          //         fontWeight: FontWeight.bold,
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
      body: homePageData.when(
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Shimmer.fromColors(
                baseColor: AppTheme.blackGradient,
                highlightColor: AppTheme.gradient1.withAlpha(77),
                child: Icon(
                  Icons.movie,
                  size: 72,
                  color: AppTheme.whiteGradient,
                ),
              ),
              SizedBox(height: 18),
              Shimmer.fromColors(
                baseColor: AppTheme.blackGradient,
                highlightColor: AppTheme.gradient1.withAlpha(77),
                child: Text(
                  'Loading...',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.whiteGradient,
                  ),
                ),
              ),
            ],
          ),
        ),
        error: (err, stack) => Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.gradient1,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error, color: AppTheme.gradient1, size: 48),
              ),
              SizedBox(height: 16),
              Text(
                'Error occured while fetching the data.\nPlease check your internet connection or try again later.',
                style: TextStyle(
                  color: AppTheme.gradient1,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gradient1,
                  foregroundColor: AppTheme.whiteGradient,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  ref.read(homeViewModelProvider.notifier).loadHomePageData();
                },
                icon: Icon(Icons.refresh),
                label: Text(
                  'Retry',
                  style: TextStyle(color: AppTheme.whiteGradient),
                ),
              ),
            ],
          ),
        ),
        data: (data) => SizedBox(
          height: size.height,
          width: size.width,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: SpotlightCard(spotlightAnimes: data.spotlightAnimes),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader('Trending Animes'),
                      _animeHorizontalList(data.trendingAnimes),
                      _sectionHeader('Most Popular Animes'),
                      _animeHorizontalList(data.mostPopularAnimes),
                      _sectionHeader('Most Favorite Animes'),
                      _animeHorizontalList(data.mostFavoriteAnimes),
                      _sectionHeader('Latest Completed Animes'),
                      _animeHorizontalList(data.latestCompletedAnimes),
                      _sectionHeader('Latest Episodes'),
                      _animeHorizontalList(data.latestEpisodesAnimes),
                      _sectionHeader('Top 10 Animes'),
                      _animeHorizontalList(data.topTenAnimes),
                      SizedBox(height: 15),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 20, bottom: 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.gradient1,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: AppTheme.gradient1.withAlpha(51),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _animeHorizontalList(List animes) {
    return SizedBox(
      height: 250,
      child: ListView.separated(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: animes.length,
        separatorBuilder: (_, __) => SizedBox(width: 12),
        itemBuilder: (context, index) {
          final anime = animes.elementAt(index);
          return AnimeCard(anime: anime);
        },
      ),
    );
  }
}
