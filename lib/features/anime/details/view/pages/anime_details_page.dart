import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shinobihaven/core/theme/app_theme.dart';
import 'package:shinobihaven/core/utils/favorites_box_functions.dart';
import 'package:shinobihaven/core/utils/library_box_functions.dart';
import 'package:shinobihaven/core/utils/toast.dart';
import 'package:shinobihaven/features/anime/common/model/anime.dart';
import 'package:shinobihaven/features/anime/common/view/widgets/anime_card.dart';
import 'package:shinobihaven/features/anime/details/dependency_injection/anime_details_provider.dart';
import 'package:shinobihaven/features/anime/details/model/anime_details.dart';
import 'package:shinobihaven/features/anime/episodes/view/pages/episodes_page.dart';
import 'package:shinobihaven/features/anime/episodes/dependency_injection/episodes_provider.dart';
import 'package:shinobihaven/features/anime/episodes/model/episodes.dart';
import 'package:shinobihaven/features/anime/stream/view/pages/sources_page.dart';
import 'package:toastification/toastification.dart';

class AnimeDetailsPage extends ConsumerStatefulWidget {
  final String animeSlug;
  const AnimeDetailsPage({super.key, required this.animeSlug});

  @override
  ConsumerState<AnimeDetailsPage> createState() => _AnimeDetailsPageState();
}

class _AnimeDetailsPageState extends ConsumerState<AnimeDetailsPage> {
  int _currentTabIndex = 0;
  bool _isFavorite = false;
  Anime? _anime;
  List<Episodes> _episodes = [];

  late final TextEditingController _nameController;

  final bool _isDesktop = !(Platform.isAndroid || Platform.isIOS);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _isFavorite = FavoritesBoxFunctions.isFavorite(widget.animeSlug);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnimeDetails();
      _loadEpisodes();
    });
  }

  void _loadAnimeDetails() {
    ref
        .read(animeDetailsViewModelProvider.notifier)
        .getAnimeDetailsData(widget.animeSlug);
  }

  void _loadEpisodes() {
    ref.read(episodesViewModelProvider.notifier).loadEpisodes(widget.animeSlug);
  }

  Anime _toAnime(AnimeDetails details) {
    return Anime(
      slug: widget.animeSlug,
      link: '',
      title: details.title,
      jname: details.jname,
      image: details.image,
      type: details.type,
      duration: details.duration,
      subCount: details.subCount,
      dubCount: details.dubCount,
      episodeCount: details.episodeCount,
      description: details.description,
    );
  }

  void _handleWatchNow() {
    if (_anime == null || _episodes.isEmpty) {
      _showLoadingDialog();
      return;
    }

    final lastWatchedEpisode = LibraryBoxFunction.getLastWatchedEpisodeObject(
      widget.animeSlug,
      _episodes,
    );
    final episodeToPlay =
        lastWatchedEpisode ?? LibraryBoxFunction.getFirstEpisode(_episodes);

    if (episodeToPlay != null) {
      LibraryBoxFunction.addToLibrary(_anime!, episodeToPlay.episodeID);
      LibraryBoxFunction.markLastWatchedEpisode(
        widget.animeSlug,
        episodeToPlay.episodeNumber,
      );

      final sectionInfo = '${_anime!.type}-${_anime!.image.hashCode}';
      final uniqueKey =
          '${_anime!.slug}-${episodeToPlay.episodeID}-$sectionInfo-${DateTime.now().millisecondsSinceEpoch}';

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SourcesPage(
                key: ValueKey(uniqueKey),
                anime: _anime!,
                episodes: _episodes,
                currentEpisode: episodeToPlay,
              ),
            ),
          ).then((_) {
            if (mounted) setState(() {});
          });
        }
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EpisodesPage(anime: _anime!)),
      );
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.blackGradient,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.gradient1),
            const SizedBox(height: 16),
            const Text(
              'Loading episodes...',
              style: TextStyle(color: AppTheme.whiteGradient, fontSize: 16),
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pop();
        if (_episodes.isNotEmpty) {
          _handleWatchNow();
        } else if (_anime != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EpisodesPage(anime: _anime!),
            ),
          );
        }
      }
    });
  }

  void _showFullDescription(String description) {
    showModalBottomSheet(
      backgroundColor: AppTheme.blackGradient,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                description,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[300],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addUserList() {
      final OutlineInputBorder border = OutlineInputBorder(
    borderSide: BorderSide(color: AppTheme.whiteGradient),
    borderRadius: BorderRadius.circular(15),
  );
  final OutlineInputBorder focusedBorder = OutlineInputBorder(
    borderSide: BorderSide(color: AppTheme.gradient1),
    borderRadius: BorderRadius.circular(15),
  );

    showAdaptiveDialog(
      context: context,
      builder: (_) => AlertDialog.adaptive(
        title: const Text('New Collection'),
        content: TextField(
          controller: _nameController,
          autofocus: true,
          cursorColor: AppTheme.gradient1,
          decoration: InputDecoration(
            hintText: 'Collection Name',
            border: border,
            enabledBorder: border,
            focusedBorder: focusedBorder,
          ),
        ),
        actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.gradient1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (_anime == null || _nameController.text.isEmpty) return;
                LibraryBoxFunction.createCustomCollectionInLibrary(_nameController.text);
                LibraryBoxFunction.addAnimeToCollection(_nameController.text, _anime!);
                Toast(
                  context: context,
                  title: 'Added',
                  description: '${_anime!.title} has been added to ${_nameController.text}',
                  type: ToastificationType.success,
                );
                Navigator.pop(context);
              },
              child: const Text(
                'Yes',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
      ),
    );
  }

  void _shareAnime(String title) {
    SharePlus.instance.share(
      ShareParams(
        text:
            'Check out $title on ShinobiHaven: https://shinobihaven.com/anime/${widget.animeSlug}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final animeDetailsData = ref.watch(animeDetailsViewModelProvider);
    final episodesData = ref.watch(episodesViewModelProvider);

    return Scaffold(
      body: animeDetailsData.when(
        data: (anime) {
          _anime = _toAnime(anime);
          _episodes = episodesData.maybeWhen(
            data: (eps) => eps,
            orElse: () => [],
          );

          if (_isDesktop) return _buildDesktopLayout(anime);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(anime),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildActionButtons(),
                      const SizedBox(height: 30),
                      _buildTabsControl(),
                      const SizedBox(height: 20),
                      _buildSelectedTabContent(anime),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => _buildLoadingState(),
        error: (err, stack) => _buildErrorState(),
      ),
    );
  }

  Widget _buildSliverAppBar(AnimeDetails anime) {
    return SliverAppBar(
      expandedHeight: 500,
      pinned: true,
      backgroundColor: AppTheme.primaryBlack,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(200),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withAlpha(50), width: 0.5),
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
        _buildCircleAction(
          icon: _isFavorite
              ? Icons.favorite_rounded
              : Icons.favorite_outline_rounded,
          color: _isFavorite ? AppTheme.gradient1 : Colors.white,
          onTap: () {
            FavoritesBoxFunctions.addToFavorites(_toAnime(anime));
            setState(() => _isFavorite = !_isFavorite);
            if (_isFavorite) {
              Toast(
                context: context,
                title: 'Added to Favorites',
                description: '${anime.title} added to favorites',
                type: ToastificationType.success,
              );
            } else {
              Toast(
                context: context,
                title: 'Removed from Favorites',
                description: '${anime.title} removed from favorites',
                type: ToastificationType.warning,
              );
            }
          },
        ),
        const SizedBox(width: 10),
        _buildCircleAction(
          icon: Icons.share_rounded,
          onTap: () {
            try {
              _shareAnime(anime.title);
            } catch (e) {
              Toast(
                context: context,
                title: 'Error',
                description: 'Failed to share anime',
                type: ToastificationType.error,
              );
            }
          },
        ),
        const SizedBox(width: 15),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(imageUrl: anime.image, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.4, 0.8, 1.0],
                  colors: [
                    AppTheme.primaryBlack.withAlpha(150),
                    AppTheme.primaryBlack.withValues(alpha: 0.4),
                    AppTheme.primaryBlack.withAlpha(200),
                    AppTheme.primaryBlack,
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.gradient1,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.gradient1.withAlpha(100),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          anime.type.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withAlpha(50),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          anime.status.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withAlpha(50),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            if (anime.score != '?') ...[
                              _buildStatItem(
                                Icons.star_rounded,
                                anime.score,
                                Colors.amber,
                              ),
                              const SizedBox(width: 6),
                              _buildStatDivider(),
                            ],
                            _buildStatItem(
                              Icons.closed_caption_rounded,
                              anime.subCount ?? '?',
                              Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            _buildStatDivider(),
                            _buildStatItem(
                              Icons.mic_rounded,
                              anime.dubCount ?? '?',
                              Colors.white70,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    anime.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      height: 1.1,
                      shadows: [
                        Shadow(
                          blurRadius: 20,
                          color: Colors.black,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 2,
      children: [
        Icon(icon, color: color, size: 20),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(height: 30, width: 1, color: Colors.white.withAlpha(30));
  }

  Widget _buildCircleAction({
    required IconData icon,
    Color color = Colors.white,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(200),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withAlpha(50), width: 0.5),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: GestureDetector(
            onTap: _handleWatchNow,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.gradient1,
                    AppTheme.gradient1.withAlpha(180),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.gradient1.withAlpha(80),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded, size: 32, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    'WATCH NOW',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        _buildSquareAction(
          icon: Icons.bookmark_add_rounded,
          onTap: () => _showCollectionsModal(),
        ),
        const SizedBox(width: 12),
        _buildSquareAction(
          icon: Icons.format_list_bulleted_rounded,
          onTap: () {
            if (_anime != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EpisodesPage(anime: _anime!),
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildSquareAction({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(30), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }

  void _showCollectionsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlack,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Collections',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _addUserList();
                  },
                  icon: Icon(
                    Icons.create_new_folder_rounded,
                    color: AppTheme.gradient1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildCollectionsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionsList() {
    final collections = LibraryBoxFunction.getCollections();
    if (collections.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Text(
            'No collections yet.',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }
    return SizedBox(
      height: 300,
      child: ListView.builder(
        itemCount: collections.length,
        itemBuilder: (context, index) {
          final title = collections[index];
          return ListTile(
            leading: Icon(Icons.folder_rounded, color: AppTheme.gradient1),
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            onTap: () {
              if (_anime != null) {
                LibraryBoxFunction.addAnimeToCollection(title, _anime!);
                Navigator.pop(context);
                Toast(
                  context: context,
                  title: 'Success',
                  description: 'Added to $title',
                  type: ToastificationType.success,
                );
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildTabsControl() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppTheme.gradient1.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _buildTabItem(0, 'Overview'),
          _buildTabItem(1, 'Seasons'),
          _buildTabItem(2, 'Others'),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String title) {
    bool isSelected = _currentTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.gradient1 : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.gradient1.withValues(alpha: 0.3),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTabContent(AnimeDetails anime) {
    switch (_currentTabIndex) {
      case 0:
        return _buildOverviewTab(anime);
      case 1:
        return _buildSeasonsTab(anime);
      case 2:
        return _buildOthersTab(anime);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildOverviewTab(AnimeDetails anime) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          anime.description,
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey[400], height: 1.6, fontSize: 15),
        ),
        TextButton(
          onPressed: () => _showFullDescription(anime.description),
          child: Text(
            'Read More',
            style: TextStyle(
              color: AppTheme.gradient1,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildInfoGrid(anime),
        const SizedBox(height: 20),
        const Text(
          'Genres',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: anime.genres
              .map(
                (g) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: AppTheme.premiumCard(context, radius: 10)
                      .copyWith(
                        border: Border.all(
                          color: AppTheme.gradient1.withAlpha(50),
                          width: 0.5,
                        ),
                      ),
                  child: Text(
                    g.name,
                    style: TextStyle(
                      color: AppTheme.gradient1,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildInfoGrid(AnimeDetails anime) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.premiumCard(context, radius: 20).copyWith(
        border: Border.all(color: AppTheme.gradient1.withAlpha(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _infoRow('Japanese', anime.japanese ?? 'N/A'),
          _infoRow('Status', anime.status),
          _infoRow('Aired', anime.aired ?? 'N/A'),
          _infoRow('Premiered', anime.premiered ?? 'N/A'),
          _infoRow('Rating', anime.rating),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonsTab(AnimeDetails anime) {
    if (anime.seasons.isEmpty) return _emptyState('No other seasons found.');
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: anime.seasons.length,
        itemBuilder: (context, index) {
          final season = anime.seasons[index];
          return GestureDetector(
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => AnimeDetailsPage(animeSlug: season.slug),
              ),
            ),
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: CachedNetworkImage(
                      imageUrl: season.image,
                      height: 180,
                      width: 140,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    season.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOthersTab(AnimeDetails anime) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (anime.recommended.isNotEmpty) ...[
          const Text(
            'Recommended',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          _horizontalAnimeList(anime.recommended),
        ],
        if (anime.related.isNotEmpty) ...[
          const SizedBox(height: 30),
          const Text(
            'Related',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          _horizontalAnimeList(anime.related),
        ],
      ],
    );
  }

  Widget _horizontalAnimeList(List<Anime> animes) {
    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: animes.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 15),
          child: AnimeCard(
            anime: animes[index],
            showAdditionalInfo: false,
            twoLineTitle: true,
            size: const Size(130, 180),
          ),
        ),
      ),
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 50),
        child: Text(
          message,
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(AnimeDetails anime) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: Row(
        children: [
          // Left cinematic poster
          Expanded(
            flex: 4,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: 'anime-image-${anime.title}',
                  child: CachedNetworkImage(
                    imageUrl: anime.image,
                    fit: BoxFit.cover,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        AppTheme.primaryBlack.withAlpha(200),
                        AppTheme.primaryBlack,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 40,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(150),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withAlpha(50)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Right detail pane
          Expanded(
            flex: 6,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(60),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.gradient1,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              anime.type.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          _buildStatItem(Icons.star_rounded, anime.score, Colors.amber),
                          const SizedBox(width: 20),
                          _buildStatItem(Icons.closed_caption_rounded, anime.subCount ?? '?', Colors.white70),
                          const SizedBox(width: 20),
                          _buildStatItem(Icons.mic_rounded, anime.dubCount ?? '?', Colors.white70),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        anime.title,
                        style: const TextStyle(
                          fontSize: 54,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        anime.japanese ?? '',
                        style: TextStyle(
                          fontSize: 24,
                          color: AppTheme.gradient1.withAlpha(180),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildActionButtons(),
                      const SizedBox(height: 50),
                      _buildTabsControl(),
                      const SizedBox(height: 30),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _buildSelectedTabContent(anime),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.gradient1),
          const SizedBox(height: 16),
          Text(
            'Summoning Info...',
            style: TextStyle(
              color: AppTheme.gradient1,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          const Text(
            'Failed to load details',
            style: TextStyle(
              color: Colors.red,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please check your connection',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadAnimeDetails,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.gradient1,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
