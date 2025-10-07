import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shinobihaven/core/theme/app_theme.dart';
import 'package:shinobihaven/core/utils/favorites_box_functions.dart';
import 'package:shinobihaven/core/utils/toast.dart';
import 'package:shinobihaven/features/anime/common/model/anime.dart';
import 'package:shinobihaven/features/anime/details/view/pages/anime_details_page.dart';
import 'package:toastification/toastification.dart';

class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  void _popUpDeleteConfirmation(Anime anime) {
    showAdaptiveDialog(
      context: context,
      builder: (context) {
        return AlertDialog.adaptive(
          title: Text(
            "Are you sure you want to remove '${anime.title}' from Favorites?",
            style: TextStyle(fontSize: 18),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.gradient1,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.gradient1,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                FavoritesBoxFunctions.addToFavorites(anime);
                Toast(
                  context: context,
                  title: 'All Right...',
                  description: '${anime.title} has been removed from Favorites',
                  type: ToastificationType.success,
                );
                Navigator.pop(context);
              },
              child: Text(
                'Yes',
                style: TextStyle(
                  color: AppTheme.whiteGradient,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Favorites', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () => setState(() {}),
            icon: Icon(Icons.refresh),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box('favorites').listenable(),
        builder: (context, _, __) {
          final List<Anime> animes = FavoritesBoxFunctions.listFavorites();

          if (animes.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite, color: AppTheme.gradient1, size: 84),
                    SizedBox(height: 16),
                    Text(
                      'No favorites added yet.',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.gradient1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Tap the heart icon on any anime details to add it to your favorites',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              itemCount: animes.length,
              itemBuilder: (context, index) {
                final anime = animes[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AnimeDetailsPage(animeSlug: anime.slug),
                      ),
                    );
                  },
                  child: Container(
                    height: 100,
                    width: size.width,
                    margin: EdgeInsets.symmetric(horizontal: 15),
                    padding: EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 5,
                    ).copyWith(right: 0),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(imageUrl: anime.image),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                anime.title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                spacing: 10,
                                children: [
                                  if (anime.dubCount != null)
                                    Row(
                                      children: [
                                        Icon(Icons.mic, size: 12),
                                        Text(
                                          anime.dubCount ?? '',
                                          style: TextStyle(
                                            // color: AppTheme.whiteGradient,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (anime.subCount != null)
                                    Row(
                                      children: [
                                        Icon(Icons.closed_caption, size: 12),
                                        Text(
                                          anime.subCount ?? '',
                                          style: TextStyle(
                                            // color: AppTheme.whiteGradient,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (anime.type != null)
                                    Row(
                                      children: [
                                        Icon(Icons.play_circle, size: 12),
                                        Text(
                                          anime.type ?? '',
                                          style: TextStyle(
                                            // color: AppTheme.whiteGradient,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),

                                  if (anime.duration != null)
                                    Row(
                                      children: [
                                        Icon(Icons.timelapse_rounded, size: 12),
                                        Text(
                                          anime.duration ?? '',
                                          style: TextStyle(
                                            // color: AppTheme.whiteGradient,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            _popUpDeleteConfirmation(anime);
                          },
                          icon: Icon(
                            Icons.delete_rounded,
                            size: 20,
                            color: AppTheme.gradient1,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
