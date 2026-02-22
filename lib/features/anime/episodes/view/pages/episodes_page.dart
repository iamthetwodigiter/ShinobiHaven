import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:shinobihaven/core/theme/app_theme.dart';
import 'package:shinobihaven/core/utils/favorites_box_functions.dart';
import 'package:shinobihaven/core/utils/library_box_functions.dart';
import 'package:shinobihaven/core/utils/toast.dart';
import 'package:shinobihaven/features/anime/common/model/anime.dart';
import 'package:shinobihaven/features/anime/episodes/dependency_injection/episodes_provider.dart';
import 'package:shinobihaven/features/anime/episodes/model/episodes.dart';
import 'package:shinobihaven/features/anime/stream/view/pages/sources_page.dart';
import 'package:toastification/toastification.dart';

class EpisodesPage extends ConsumerStatefulWidget {
  final Anime anime;
  const EpisodesPage({super.key, required this.anime});

  @override
  ConsumerState<EpisodesPage> createState() => _EpisodesPageState();
}

class _EpisodesPageState extends ConsumerState<EpisodesPage> {
  late final TextEditingController _searchController;

  List<Episodes> _episodes = [];
  List<Episodes> _allEpisodes = [];
  List<String> _watchedEpisodes = [];
  bool _isSearchEnabled = false;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _isFavorite = FavoritesBoxFunctions.isFavorite(widget.anime.slug);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEpisodes();
      _loadLibraryAnimes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadLibraryAnimes();
  }

  void _loadLibraryAnimes() {
    if (LibraryBoxFunction.animeExistsInLibrary(widget.anime)) {
      _watchedEpisodes = LibraryBoxFunction.getEpisodeIDBySlug(
        widget.anime.slug,
      );
    }
  }

  void _loadEpisodes() {
    setState(() {
      _allEpisodes = [];
      _episodes = [];
    });
    ref
        .read(episodesViewModelProvider.notifier)
        .loadEpisodes(widget.anime.slug);
  }

  void _searchEpisodes(String search) {
    if (_allEpisodes.isEmpty) return;
    if (search.isEmpty) {
      setState(() {
        _episodes = List.from(_allEpisodes);
      });
      return;
    }
    List<Episodes> searchResult = [];
    for (var episode in _allEpisodes) {
      if (episode.episodeNumber.contains(search) ||
          episode.title.toLowerCase().contains(search.toLowerCase())) {
        searchResult.add(episode);
      }
    }
    setState(() {
      _episodes = searchResult;
    });
  }

  void _playEpisode(Episodes selectedEpisode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SourcesPage(
          anime: widget.anime,
          episodes: _allEpisodes,
          currentEpisode: selectedEpisode,
        ),
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      sliver: SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withAlpha(30), width: 1),
          ),
          child: Row(
            children: [
              Hero(
                tag: 'anime_poster_${widget.anime.slug}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: widget.anime.image,
                    height: 120,
                    width: 85,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.anime.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (widget.anime.type != null) ...[
                          _buildBadge(
                            widget.anime.type!.toUpperCase(),
                            AppTheme.gradient1,
                          ),
                          const SizedBox(width: 8),
                        ],
                        _buildBadge(
                          '${_watchedEpisodes.length}/${_allEpisodes.length} EP',
                          Colors.white.withAlpha(30),
                          textColor: Colors.white70,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(
    String text,
    Color color, {
    Color textColor = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return SliverAppBar(
      pinned: true,
      toolbarHeight: 80,
      backgroundColor: AppTheme.primaryBlack,
      automaticallyImplyLeading: false,
      elevation: 0,
      title: Container(
        height: 55,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isSearchEnabled
                ? AppTheme.gradient1.withAlpha(100)
                : Colors.white.withAlpha(20),
            width: 1,
          ),
        ),
        child: TextField(
          controller: _searchController,
          cursorColor: AppTheme.gradient1,
          onChanged: (value) {
            setState(() => _isSearchEnabled = value.isNotEmpty);
            _searchEpisodes(value);
          },
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Search episode...',
            hintStyle: TextStyle(
              color: Colors.white.withAlpha(100),
              fontSize: 16,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: _isSearchEnabled
                  ? AppTheme.gradient1
                  : Colors.white.withAlpha(100),
            ),
            suffixIcon: _isSearchEnabled
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () {
                      _searchController.clear();
                      _searchEpisodes('');
                      setState(() => _isSearchEnabled = false);
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildEpisodeTile(Episodes episode) {
    final watched = _watchedEpisodes.contains(episode.episodeID);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () => _playEpisode(episode),
        child: Container(
          decoration: BoxDecoration(
            color: watched
                ? AppTheme.gradient1.withAlpha(20)
                : Colors.white.withAlpha(10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: watched
                  ? AppTheme.gradient1.withAlpha(100)
                  : Colors.white.withAlpha(20),
              width: 1,
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(19),
                        ),
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(widget.anime.image),
                          fit: BoxFit.cover,
                          opacity: 0.6,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.play_circle_filled_rounded,
                      color: AppTheme.gradient1,
                      size: 32,
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Episode ${episode.episodeNumber}',
                          style: TextStyle(
                            color: AppTheme.gradient1,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          episode.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                if (watched)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.primaryGreen,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final episodesData = ref.watch(episodesViewModelProvider);
    _isFavorite = FavoritesBoxFunctions.isFavorite(widget.anime.slug);

    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: ValueListenableBuilder(
        valueListenable: Hive.box('library').listenable(),
        builder: (context, value, child) {
          _loadLibraryAnimes();
          return episodesData.when(
            data: (episodes) {
              if (_allEpisodes.isEmpty) {
                _allEpisodes = List.from(episodes);
                _episodes = List.from(episodes);
              }
              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    expandedHeight: 180,
                    pinned: true,
                    backgroundColor: AppTheme.primaryBlack,
                    leading: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(200),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    actions: [
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(200),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            !_isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_outline_rounded,
                            color: !_isFavorite
                                ? AppTheme.gradient1
                                : Colors.white,
                            size: 24,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            FavoritesBoxFunctions.addToFavorites(widget.anime);
                          });
                          if (_isFavorite) {
                            Toast(
                              context: context,
                              title: 'Added',
                              description:
                                  '${widget.anime.title} added to favorites',
                              type: ToastificationType.success,
                            );
                          } else {
                            Toast(
                              context: context,
                              title: 'Removed',
                              description:
                                  '${widget.anime.title} removed from favorites',
                              type: ToastificationType.warning,
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 10),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: widget.anime.image,
                            fit: BoxFit.cover,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: const [0.0, 0.4, 0.9, 1.0],
                                colors: [
                                  AppTheme.primaryBlack.withAlpha(150),
                                  Colors.transparent,
                                  AppTheme.primaryBlack.withAlpha(200),
                                  AppTheme.primaryBlack,
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildSliverHeader(),
                  _buildSearchBar(),
                  _episodes.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 64,
                                  color: AppTheme.gradient1.withAlpha(100),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No episodes found',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.only(bottom: 30),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) =>
                                  _buildEpisodeTile(_episodes[index]),
                              childCount: _episodes.length,
                            ),
                          ),
                        ),
                ],
              );
            },
            error: (err, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load episodes',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadEpisodes,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.gradient1,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            loading: () => Center(
              child: CircularProgressIndicator(color: AppTheme.gradient1),
            ),
          );
        },
      ),
    );
  }
}
