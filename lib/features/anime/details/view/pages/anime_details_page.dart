import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinobihaven/core/theme/app_theme.dart';
import 'package:shinobihaven/core/utils/favorites_box_functions.dart';
import 'package:shinobihaven/core/utils/library_box_functions.dart';
import 'package:shinobihaven/core/utils/toast.dart';
import 'package:shinobihaven/features/anime/common/model/anime.dart';
import 'package:shinobihaven/features/anime/common/view/widgets/anime_card.dart';
import 'package:shinobihaven/features/anime/details/dependency_injection/anime_details_provider.dart';
import 'package:shinobihaven/features/anime/details/model/anime_details.dart';
import 'package:shinobihaven/features/anime/episodes/view/pages/episodes_page.dart';
import 'package:shimmer/shimmer.dart';
import 'package:toastification/toastification.dart'; // Add shimmer package for image loading

class AnimeDetailsPage extends ConsumerStatefulWidget {
  final String animeSlug;
  const AnimeDetailsPage({super.key, required this.animeSlug});

  @override
  ConsumerState<AnimeDetailsPage> createState() => _AnimeDetailsPageState();
}

class _AnimeDetailsPageState extends ConsumerState<AnimeDetailsPage> {
  // int _currentBottomBarIndex = 0;
  int _currentTabIndex = 0;
  bool _isFavorite = false;
  Anime? _anime;

  @override
  void initState() {
    super.initState();
    _isFavorite = FavoritesBoxFunctions.isFavorite(widget.animeSlug);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnimeDetails();
    });
  }

  void _loadAnimeDetails() {
    ref
        .read(animeDetailsViewModelProvider.notifier)
        .getAnimeDetailsData(widget.animeSlug);
  }

  void _showFullDescription(String description) {
    showModalBottomSheet(
      backgroundColor: AppTheme.blackGradient,
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20).copyWith(top: 0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Close',
                        style: TextStyle(
                          color: AppTheme.gradient1,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  description,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tabItems(int index, String title) {
    final isSelected = _currentTabIndex == index;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          setState(() {
            _currentTabIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      AppTheme.gradient1.withValues(alpha: 0.75),
                      AppTheme.gradient2.withValues(alpha: 0.75),
                    ],
                  )
                : null,
            // color: isSelected ? null : AppTheme.blackGradient,
            borderRadius: BorderRadius.circular(15),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.gradient1.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.whiteGradient : AppTheme.gradient1,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _richText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: 15,
            color: Theme.brightnessOf(context) == Brightness.light
                ? AppTheme.blackGradient
                : AppTheme.whiteGradient,
          ),
          children: [
            TextSpan(
              text: value,
              style: TextStyle(
                color: AppTheme.gradient1,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _generalDetailsTab(AnimeDetails anime) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              margin: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.brightnessOf(context) == Brightness.dark
                        ? AppTheme.blackGradient
                        : AppTheme.whiteGradient,
                    AppTheme.gradient2.withValues(alpha: 0.2),
                  ],
                ),
                border: Border.all(color: AppTheme.gradient1),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.gradient1.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                anime.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            Positioned(
              top: 0,
              right: 5,
              child: IconButton(
                onPressed: () {
                  _showFullDescription(anime.description);
                },
                icon: Icon(
                  Icons.info_rounded,
                  size: 22,
                  color: AppTheme.gradient1,
                ),
                tooltip: "Show full description",
              ),
            ),
          ],
        ),
        Container(
          padding: EdgeInsets.all(12),
          margin: EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.brightnessOf(context) == Brightness.dark
                    ? AppTheme.blackGradient
                    : AppTheme.whiteGradient,
                AppTheme.gradient2.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppTheme.gradient1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (anime.subCount != null)
                _infoChip(Icons.closed_caption, 'Subbed', anime.subCount!),
              if (anime.dubCount != null)
                _infoChip(Icons.mic, 'Dubbed', anime.dubCount!),
              _infoChip(Icons.hd, 'Quality', anime.quality),
              _infoChip(Icons.timelapse_rounded, 'Duration', anime.duration),
              _infoChip(Icons.question_mark_rounded, 'Type', anime.type),
            ],
          ),
        ),
        SizedBox(height: 15),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: List.generate(anime.genres.length, (index) {
            final genre = anime.genres.elementAt(index);
            return Chip(
              label: Text(
                genre.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.gradient1,
                ),
              ),
              // backgroundColor: AppTheme.blackGradient,
              shape: StadiumBorder(side: BorderSide(color: AppTheme.gradient1)),
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            );
          }),
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          margin: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _richText('Anime Score: ', anime.score),
              if (anime.japanese != null)
                _richText('Japanese Name: ', anime.japanese!),
              if (anime.synonyms != null)
                _richText('Synonyms: ', anime.synonyms!),
              if (anime.aired != null) _richText('Aired: ', anime.aired!),
              if (anime.premiered != null)
                _richText('Premiered: ', anime.premiered!),
              _richText('Status: ', anime.status),
              _richText('Rating: ', anime.rating),
            ],
          ),
        ),
        SizedBox(height: 30),
      ],
    );
  }

  Widget _infoChip(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.gradient1, size: 22),
        SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.gradient1,
          ),
        ),
      ],
    );
  }

  Widget _producersDetailsTab(AnimeDetails anime) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(anime.producers.length, (index) {
        final producer = anime.producers.elementAt(index);
        return Chip(
          avatar: CircleAvatar(
            backgroundColor: AppTheme.gradient1,
            child: Text(
              '${index + 1}',
              style: TextStyle(color: AppTheme.whiteGradient, fontSize: 12),
            ),
          ),
          label: Text(
            producer.name,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          // backgroundColor: AppTheme.blackGradient,
          shape: StadiumBorder(side: BorderSide(color: AppTheme.gradient1)),
        );
      }),
    );
  }

  Widget _seasonsDetailsTab(AnimeDetails anime) {
    // return Wrap(
    //   spacing: 8,
    //   runSpacing: 8,
    //   children: List.generate(anime.seasons.length, (index) {
    //     final season = anime.seasons.elementAt(index);
    //     return GestureDetector(
    //       onTap: () {
    //         Navigator.push(
    //           context,
    //           MaterialPageRoute(
    //             builder: (context) => AnimeDetailsPage(animeSlug: season.slug),
    //           ),
    //         );
    //       },
    //       child: SizedBox(
    //         height: 200,
    //         width: 120,
    //         child: Column(
    //           children: [
    //             ClipRRect(
    //               borderRadius: BorderRadius.circular(12),
    //               child: CachedNetworkImage(
    //                 imageUrl: season.image,
    //                 height: 150,
    //                 width: 120,
    //                 fit: BoxFit.fitWidth,
    //                 placeholder: (context, url) => Shimmer.fromColors(
    //                   baseColor: AppTheme.blackGradient,
    //                   highlightColor: AppTheme.gradient1.withValues(alpha: 0.3),
    //                   child: Container(
    //                     height: 150,
    //                     width: 120,
    //                     color: AppTheme.blackGradient,
    //                   ),
    //                 ),
    //               ),
    //             ),
    //             SizedBox(height: 6),
    //             Text(
    //               season.title,
    //               maxLines: 2,
    //               textAlign: TextAlign.center,
    //               style: TextStyle(fontWeight: FontWeight.bold),
    //             ),
    //           ],
    //         ),
    //       ),
    //     );
    //   }),
    // );
    return anime.seasons.isNotEmpty
        ? Container(
            height: 250,
            padding: EdgeInsets.only(left: 15),
            child: ListView.builder(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              itemCount: anime.seasons.length,
              itemBuilder: (context, index) {
                final season = anime.seasons.elementAt(index);
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AnimeDetailsPage(animeSlug: season.slug),
                      ),
                    );
                  },
                  child: Container(
                    height: 220,
                    width: 150,
                    padding: EdgeInsets.only(right: 10),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: CachedNetworkImage(
                            imageUrl: season.image,
                            height: 175,
                            width: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Text(
                          season.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 50),
              Text(
                'Nothing to watch here.\nTry searching something',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          );
  }

  Widget _otherAnimesTab(AnimeDetails anime) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (anime.related.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Related Animes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.gradient1,
                    ),
                  ),
                  SizedBox(height: 15),
                  SizedBox(
                    height: 250,
                    child: ListView.builder(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: anime.related.length,
                      itemBuilder: (context, index) {
                        final relatedAnime = anime.related.elementAt(index);
                        return Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: AnimeCard(anime: relatedAnime),
                        );
                      },
                    ),
                  ),
                ],
              ),
            if (anime.recommended.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recommended Animes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.gradient1,
                    ),
                  ),
                  SizedBox(height: 15),
                  SizedBox(
                    height: 250,
                    child: ListView.builder(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: anime.recommended.length,
                      itemBuilder: (context, index) {
                        final recommendedAnime = anime.recommended.elementAt(
                          index,
                        );
                        return Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: AnimeCard(anime: recommendedAnime),
                        );
                      },
                    ),
                  ),
                ],
              ),
            if (anime.related.isEmpty && anime.recommended.isEmpty)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 50),
                  Text(
                    'Nothing to watch here.\nTry searching something',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final animeDetailsData = ref.watch(animeDetailsViewModelProvider);

    _isFavorite = FavoritesBoxFunctions.isFavorite(widget.animeSlug);

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: Icon(Icons.arrow_back_ios, color: AppTheme.gradient1),
        ),
        elevation: 0,
        actionsPadding: EdgeInsets.only(right: 15),
        actions: animeDetailsData.maybeWhen(
          data: (_) => [
            IconButton(
              onPressed: () {
                if (_anime != null) {
                  bool isAdded = FavoritesBoxFunctions.addToFavorites(_anime!);

                  if (isAdded) {
                    Toast(
                      context: context,
                      title: 'Success',
                      description: '${_anime!.title} added to Favorites',
                      type: ToastificationType.success,
                    );
                  } else {
                    Toast(
                      context: context,
                      title: 'Well as you wish',
                      description: '${_anime!.title} removed from Favorites',
                      type: ToastificationType.success,
                    );
                  }
                  setState(() {
                    _isFavorite = FavoritesBoxFunctions.isFavorite(
                      widget.animeSlug,
                    );
                  });
                }
              },
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border_rounded,
                color: AppTheme.gradient1,
                // : AppTheme.whiteGradient,
                size: 28,
              ),
              tooltip: _isFavorite
                  ? "Remove from favorites"
                  : "Add to favorites",
            ),
            IconButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    final collections = LibraryBoxFunction.getCollections();

                    return Container(
                      width: size.width,
                      padding: EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Collections',
                            style: TextStyle(
                              color: AppTheme.gradient1,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          collections.isEmpty
                              ? Container(
                                  width: size.width,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 30,
                                  ),
                                  child: Text(
                                    'No Collections found.\nCreate new collections from Library Page',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : Column(
                                  children: List.generate(collections.length, (
                                    index,
                                  ) {
                                    final title = collections.elementAt(index);
                                    final count =
                                        LibraryBoxFunction.getAnimesInCollection(
                                          title,
                                        ).length;
                                    // return ListTile(
                                    //   onTap: () {
                                    //     if (_anime != null) {
                                    //       LibraryBoxFunction.addAnimeToCollection(
                                    //         title,
                                    //         _anime!,
                                    //       );
                                    //       Navigator.pop(context, true);
                                    //     }
                                    //   },
                                    //   title: Text(
                                    //     title,
                                    //     style: TextStyle(
                                    //       color: AppTheme.gradient1,
                                    //       fontWeight: FontWeight.bold,
                                    //     ),
                                    //   ),
                                    // );
                                    return ListTile(
                                      onTap: () {
                                        if (_anime != null) {
                                          LibraryBoxFunction.addAnimeToCollection(
                                            title,
                                            _anime!,
                                          );
                                          Toast(
                                            context: context,
                                            title: 'Success',
                                            description:
                                                "${_anime!.title} added to collection $title",
                                            type: ToastificationType.success,
                                          );
                                          Navigator.pop(context, true);
                                        }
                                      },
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      leading: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          color: AppTheme.gradient1.withAlpha(
                                            30,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            (title.isNotEmpty
                                                ? title[0].toUpperCase()
                                                : ''),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        title,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        '$count item${count == 1 ? '' : 's'}',
                                        style: TextStyle(
                                          color: AppTheme.gradient1.withAlpha(
                                            150,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                        ],
                      ),
                    );
                  },
                );
              },
              icon: Icon(
                Icons.add,
                color: AppTheme.gradient1,
                // : AppTheme.whiteGradient,
                size: 28,
              ),
            ),
          ],
          orElse: () => [],
        ),
      ),
      body: animeDetailsData.when(
        data: (anime) {
          _anime = Anime(
            slug: widget.animeSlug,
            link: '',
            title: anime.title,
            jname: anime.jname,
            image: anime.image,
            type: anime.type,
            duration: anime.duration,
            subCount: anime.subCount,
            dubCount: anime.dubCount,
          );

          return SafeArea(
            child: SizedBox(
              height: size.height,
              width: size.width,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 16),
                    Container(
                      height: 300,
                      width: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.blackGradient,
                            AppTheme.gradient2.withValues(alpha: 0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.gradient1.withValues(alpha: 0.2),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: CachedNetworkImage(
                          imageUrl: anime.image,
                          height: 300,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: AppTheme.blackGradient,
                            highlightColor: AppTheme.gradient1.withValues(
                              alpha: 0.3,
                            ),
                            child: Container(
                              height: 300,
                              width: 200,
                              color: AppTheme.blackGradient,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      anime.title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.gradient1,
                        shadows: [
                          Shadow(
                            color: AppTheme.gradient2.withValues(alpha: 0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EpisodesPage(anime: _anime!),
                          ),
                        );
                        setState(() {
                          _isFavorite = FavoritesBoxFunctions.isFavorite(
                            widget.animeSlug,
                          );
                        });
                      },
                      child: Container(
                        width: size.width,
                        padding: EdgeInsets.all(12),
                        margin: EdgeInsets.symmetric(horizontal: 15),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: LinearGradient(
                            colors: [AppTheme.gradient1, AppTheme.gradient2],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.gradient1.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.play_arrow_rounded,
                              color: AppTheme.whiteGradient,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Watch Now',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.whiteGradient,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 18),
                    Container(
                      height: 50,
                      width: size.width,
                      margin: EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        // color: AppTheme.blackGradient,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.gradient1.withValues(alpha: 0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          _tabItems(0, 'General'),
                          _tabItems(1, 'Producers'),
                          _tabItems(2, 'Seasons'),
                          _tabItems(3, 'Other'),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    if (_currentTabIndex == 0) _generalDetailsTab(anime),
                    if (_currentTabIndex == 1) _producersDetailsTab(anime),
                    if (_currentTabIndex == 2) _seasonsDetailsTab(anime),
                    if (_currentTabIndex == 3) _otherAnimesTab(anime),
                    SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          );
        },
        error: (err, stack) => Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: AppTheme.gradient2, size: 64),
              SizedBox(height: 16),
              Text(
                'Error occured while fetching the data.\nPlease check your internet connection or try again later.',
                style: TextStyle(
                  color: AppTheme.gradient2,
                  fontWeight: FontWeight.bold,
                ),
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
                  ref
                      .read(animeDetailsViewModelProvider.notifier)
                      .getAnimeDetailsData(widget.animeSlug);
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
      ),
    );
  }
}
