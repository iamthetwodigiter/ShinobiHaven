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
import 'package:shimmer/shimmer.dart';
import 'package:toastification/toastification.dart';

class EpisodesPage extends ConsumerStatefulWidget {
  final Anime anime;
  const EpisodesPage({super.key, required this.anime});

  @override
  ConsumerState<EpisodesPage> createState() => _EpisodesPageState();
}

class _EpisodesPageState extends ConsumerState<EpisodesPage> {
  late final TextEditingController _searchController;
  final OutlineInputBorder _border = OutlineInputBorder(
    borderSide: BorderSide(color: AppTheme.gradient1),
    borderRadius: BorderRadius.circular(15),
  );
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
    // Add to library when episode is selected
    LibraryBoxFunction.addToLibrary(widget.anime, selectedEpisode.episodeID);

    // Navigate directly to SourcesPage with all episodes
    // Don't pass serverID so it will auto-select the first available server
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SourcesPage(
          anime: widget.anime,
          episodes: _allEpisodes,
          currentEpisode: selectedEpisode,
          // serverID: null, // Let it auto-select first server
        ),
      ),
    );
  }

  Widget _animeHeader(BuildContext context, Size size) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.brightnessOf(context) == Brightness.dark
                ? AppTheme.primaryBlack
                : AppTheme.whiteGradient,
            AppTheme.gradient1.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.gradient1.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.gradient1.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: CachedNetworkImage(
              imageUrl: widget.anime.image,
              height: 150,
              width: 100,
              fit: BoxFit.cover,
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: AppTheme.blackGradient,
                highlightColor: AppTheme.gradient1.withValues(alpha: 0.3),
                child: Container(
                  height: 120,
                  width: 90,
                  color: AppTheme.blackGradient,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.anime.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.gradient1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                if (widget.anime.dubCount != null)
                  Text(
                    'Dubbed: ${widget.anime.dubCount}',
                    style: TextStyle(
                      color: AppTheme.whiteGradient,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (widget.anime.subCount != null)
                  Text(
                    'Subbed: ${widget.anime.subCount}',
                    style: TextStyle(
                      color: AppTheme.whiteGradient,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (widget.anime.type != null)
                  Text(
                    'Type: ${widget.anime.type}',
                    style: TextStyle(color: AppTheme.whiteGradient),
                  ),
                if (widget.anime.duration != null)
                  Text(
                    'Avg Duration: ${widget.anime.duration}',
                    style: TextStyle(color: AppTheme.whiteGradient),
                  ),
                SizedBox(height: 8),
                Text(
                  'Watched: ${_watchedEpisodes.length} Episodes',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar(BuildContext context, Size size) {
    return Container(
      width: size.width,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.brightnessOf(context) == Brightness.dark
          ? AppTheme.primaryBlack
          : AppTheme.whiteGradient,
      child: _isSearchEnabled
          ? TextField(
              controller: _searchController,
              cursorColor: AppTheme.gradient1,
              onChanged: (value) {
                _searchEpisodes(value);
              },
              onSubmitted: (value) {
                _searchEpisodes(value);
              },
              decoration: InputDecoration(
                hintText: 'Search Episode',
                hintStyle: TextStyle(
                  color: AppTheme.whiteGradient.withValues(alpha: 0.6),
                ),
                border: _border,
                enabledBorder: _border,
                focusedBorder: _border,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _isSearchEnabled = false;
                      _searchController.clear();
                      _searchEpisodes('');
                    });
                  },
                  icon: Icon(Icons.close, color: AppTheme.gradient1),
                ),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Episodes',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.gradient1,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isSearchEnabled = true;
                    });
                  },
                  icon: Icon(Icons.search, color: AppTheme.gradient1),
                ),
              ],
            ),
    );
  }

  Widget _episodeTile(Episodes episode) {
    final watched = _watchedEpisodes.contains(episode.episodeID);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Material(
        color: watched
            ? AppTheme.gradient1.withValues(alpha: 0.15)
            : AppTheme.blackGradient,
        borderRadius: BorderRadius.circular(12),
        elevation: watched ? 2 : 0,
        child: ListTile(
          titleAlignment: ListTileTitleAlignment.top,
          enableFeedback: true,
          splashColor: AppTheme.gradient1.withValues(alpha: 0.1),
          tileColor: Theme.brightnessOf(context) == Brightness.dark
              ? AppTheme.primaryBlack
              : AppTheme.whiteGradient,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppTheme.gradient1, width: 0.25),
          ),
          onTap: () {
            _playEpisode(episode); // Direct navigation to video player
          },
          leading: Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: widget.anime.image,
                  fit: BoxFit.cover,
                  height: 75,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: AppTheme.blackGradient,
                    highlightColor: AppTheme.gradient1.withValues(alpha: 0.3),
                    child: Container(
                      width: 48,
                      height: 48,
                      color: AppTheme.blackGradient,
                    ),
                  ),
                ),
              ),
              Icon(
                Icons.play_circle_fill_rounded,
                size: 22,
                color: AppTheme.gradient1,
              ),
            ],
          ),
          title: Text(
            episode.title,
            style: TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Episode ${episode.episodeNumber}',
                style: TextStyle(
                  color: AppTheme.gradient1,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (watched)
                Row(
                  children: [
                    Icon(
                      Icons.done_all_rounded,
                      color: AppTheme.primaryGreen,
                      size: 20,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Watched',
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final episodesData = ref.watch(episodesViewModelProvider);
    _isFavorite = FavoritesBoxFunctions.isFavorite(widget.anime.slug);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.brightnessOf(context) == Brightness.dark
            ? AppTheme.primaryBlack
            : AppTheme.whiteGradient,
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: Icon(Icons.arrow_back_ios, color: AppTheme.gradient1),
        ),
        title: Text(
          'Watching ${widget.anime.title}',
          style: TextStyle(
            fontSize: 18,
            color: AppTheme.gradient1,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actionsPadding: EdgeInsets.only(right: 15),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                bool isAdded = FavoritesBoxFunctions.addToFavorites(
                  widget.anime,
                );
                if (isAdded) {
                  Toast(
                    context: context,
                    title: 'Success',
                    description: '${widget.anime.title} added to Favorites',
                    type: ToastificationType.success,
                  );
                } else {
                  Toast(
                    context: context,
                    title: 'Well as you wish',
                    description: '${widget.anime.title} removed from Favorites',
                    type: ToastificationType.success,
                  );
                }
              });
            },
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border_rounded,
              color: AppTheme.gradient1,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: Hive.box('library').listenable(),
          builder: (context, value, child) {
            _loadLibraryAnimes();
            return episodesData.when(
              data: (episodes) {
                if (_allEpisodes.isEmpty) {
                  _allEpisodes = List.from(episodes);
                  _episodes = List.from(episodes);
                }
                return Column(
                  children: [
                    _animeHeader(context, size),
                    _searchBar(context, size),
                    Expanded(
                      child: _episodes.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 48,
                                    color: AppTheme.gradient1,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'No episodes found.',
                                    style: TextStyle(
                                      color: AppTheme.whiteGradient,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _episodes.length,
                              itemBuilder: (context, index) {
                                final episode = _episodes.elementAt(index);
                                return _episodeTile(episode);
                              },
                            ),
                    ),
                  ],
                );
              },
              error: (err, stack) => Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: AppTheme.gradient1, size: 48),
                    SizedBox(height: 16),
                    Text(
                      'Error occured while fetching the data.\nPlease check your internet connection or try again later.',
                      style: TextStyle(
                        color: AppTheme.gradient1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.gradient1,
                        foregroundColor: AppTheme.whiteGradient,
                      ),
                      onPressed: () {
                        ref
                            .read(episodesViewModelProvider.notifier)
                            .loadEpisodes(widget.anime.slug);
                      },
                      icon: Icon(Icons.refresh),
                      label: Text('Retry'),
                    ),
                  ],
                ),
              ),
              loading: () => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Shimmer.fromColors(
                      baseColor: AppTheme.blackGradient,
                      highlightColor: AppTheme.gradient1.withValues(alpha: 0.3),
                      child: Icon(Icons.movie, size: 64),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading...',
                      style: TextStyle(fontSize: 18, color: AppTheme.gradient1),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}