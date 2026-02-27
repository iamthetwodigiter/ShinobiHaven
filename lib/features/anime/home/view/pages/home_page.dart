import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shinobihaven/core/theme/app_theme.dart';
import 'package:shinobihaven/features/anime/common/view/widgets/anime_card.dart';
import 'package:shinobihaven/features/anime/discovery/view/pages/search_page.dart';
import 'package:shinobihaven/features/anime/home/dependency_injection/home_provider.dart';
import 'package:shinobihaven/core/utils/library_box_functions.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shinobihaven/features/anime/details/view/pages/anime_details_page.dart';
import 'package:shinobihaven/features/anime/home/model/home.dart';
import 'package:shinobihaven/features/anime/home/view/widgets/spotlight_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _isScrolling = false;
  Timer? _scrollTimer;

  @override
  void dispose() {
    _scrollTimer?.cancel();
    super.dispose();
  }

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
      body: homePageData.when(
        loading: () => _buildLoadingState(),
        error: (err, stack) => _buildErrorState(),
        data: (data) => _buildMainContent(data, size),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildFAB() {
    return ValueListenableBuilder(
      valueListenable: Hive.box(
        'library',
      ).listenable(keys: ['lastPlayedAnime']),
      builder: (context, box, child) {
        final lastPlayedData = LibraryBoxFunction.getLastPlayedAnimeData();
        if (lastPlayedData == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 80),
          child: FloatingActionButton.extended(
            isExtended: !_isScrolling,
            onPressed: () {
              final anime = lastPlayedData['anime'];
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AnimeDetailsPage(animeSlug: anime.slug),
                ),
              );
            },
            backgroundColor: AppTheme.gradient1,
            extendedIconLabelSpacing: 8,
            extendedPadding: const EdgeInsets.symmetric(horizontal: 16),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(18)),
            ),
            elevation: 8,
            icon: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 28,
            ),
            label: const Text(
              'Resume Watching',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainContent(HomePageData data, Size size) {
    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        if (notification.direction != ScrollDirection.idle) {
          _scrollTimer?.cancel();
          if (!_isScrolling) {
            setState(() {
              _isScrolling = true;
            });
          }
        } else if (notification.direction == ScrollDirection.idle) {
          _scrollTimer?.cancel();
          _scrollTimer = Timer(const Duration(milliseconds: 900), () {
            if (_isScrolling && mounted) {
              setState(() {
                _isScrolling = false;
              });
            }
          });
        }
        return false;
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: size.width > 900 ? 700 : 400,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: SpotlightCard(spotlightAnimes: data.spotlightAnimes),
            ),
            actions: [_buildSearchAction()],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 0, 0).copyWith(
                bottom: Platform.isAndroid || Platform.isIOS ? 120 : 60,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('Trending Now', data.trendingAnimes),
                  _buildSection('Most Popular', data.mostPopularAnimes),
                  _buildSection('Fan Favorites', data.mostFavoriteAnimes),
                  _buildSection('Just Completed', data.latestCompletedAnimes),
                  _buildSection('New Episodes', data.latestEpisodesAnimes),
                  _buildSection('Top 10 Globally', data.topTenAnimes),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAction() {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: IconButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SearchPage()),
        ),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(100),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withAlpha(50)),
          ),
          child: const Icon(Icons.search_rounded, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List animes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_sectionHeader(title), _animeHorizontalList(animes)],
    );
  }

  Widget _buildLoadingState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Shimmer.fromColors(
        baseColor: isDark ? Colors.white10 : Colors.grey[200]!,
        highlightColor: AppTheme.gradient1.withAlpha(50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie_filter_rounded,
              size: 80,
              color: isDark ? Colors.white : Colors.grey[300],
            ),
            const SizedBox(height: 20),
            Text(
              'ShinobiHaven',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: Colors.redAccent,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'Connection Lost',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () =>
                ref.read(homeViewModelProvider.notifier).loadHomePageData(),
            child: const Text('Retry'),
          ),
        ],
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
    final isDesktop = MediaQuery.sizeOf(context).width > 900;
    return SizedBox(
      height: isDesktop ? 320 : 250,
      child: ListView.separated(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: animes.length,
        separatorBuilder: (_, _) => SizedBox(width: isDesktop ? 20 : 12),
        itemBuilder: (context, index) {
          final anime = animes.elementAt(index);
          return AnimeCard(
            anime: anime,
            size: isDesktop ? const Size(180, 260) : const Size(140, 200),
          );
        },
      ),
    );
  }
}
