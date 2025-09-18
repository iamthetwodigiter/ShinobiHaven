import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:shinobihaven/core/theme/app_theme.dart';
import 'package:shinobihaven/features/anime/common/model/anime.dart';
import 'package:shinobihaven/features/anime/details/view/pages/anime_details_page.dart';

class SpotlightCard extends StatelessWidget {
  final List<Anime> spotlightAnimes;
  const SpotlightCard({super.key, required this.spotlightAnimes});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return CarouselSlider.builder(
      itemCount: spotlightAnimes.length,
      itemBuilder: (context, pageIndex, itemIndex) {
        final anime = spotlightAnimes.elementAt(pageIndex);
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AnimeDetailsPage(animeSlug: anime.slug),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              alignment: Alignment.bottomLeft,
              children: [
                CachedNetworkImage(
                  imageUrl: anime.image,
                  height: 400,
                  width: size.width,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 400,
                    width: size.width,
                    color: AppTheme.transparentColor,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: size.width,
                    height: 400,
                    color: AppTheme.transparentColor,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 48),
                          SizedBox(height: 8),
                          Text(
                            'Image not available',
                            style: TextStyle(color: AppTheme.gradient1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 400,
                  width: size.width,
                  decoration: BoxDecoration(
                    color: AppTheme.blackGradient.withAlpha(166),
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        anime.title,
                        style: TextStyle(
                          color: AppTheme.whiteGradient,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: AppTheme.blackGradient.withAlpha(120),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 10),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          if (anime.dubCount != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.mic, size: 16, color: AppTheme.whiteGradient),
                                SizedBox(width: 4),
                                Text(
                                  anime.dubCount ?? '',
                                  style: TextStyle(
                                    color: AppTheme.whiteGradient,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          if (anime.subCount != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.closed_caption, size: 16, color: AppTheme.whiteGradient),
                                SizedBox(width: 4),
                                Text(
                                  anime.subCount ?? '',
                                  style: TextStyle(
                                    color: AppTheme.whiteGradient,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          if (anime.type != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.play_circle, size: 16, color: AppTheme.whiteGradient),
                                SizedBox(width: 4),
                                Text(
                                  anime.type ?? '',
                                  style: TextStyle(
                                    color: AppTheme.whiteGradient,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          if (anime.duration != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.timelapse_rounded, size: 16, color: AppTheme.whiteGradient),
                                SizedBox(width: 4),
                                Text(
                                  anime.duration ?? '',
                                  style: TextStyle(
                                    color: AppTheme.whiteGradient,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        anime.description ?? '',
                        style: TextStyle(
                          color: AppTheme.whiteGradient,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      options: CarouselOptions(
        height: 400,
        viewportFraction: 1,
        aspectRatio: 5 / 3,
        autoPlay: true,
        autoPlayInterval: Duration(seconds: 5),
      ),
    );
  }
}