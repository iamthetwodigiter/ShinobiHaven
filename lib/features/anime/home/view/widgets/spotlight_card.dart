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
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              alignment: Alignment.bottomLeft,
              children: [
                CachedNetworkImage(
                  imageUrl: anime.image,
                  height: 400,
                  width: size.width,
                  fit: BoxFit.cover,
                  memCacheHeight: 800,
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
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withAlpha(50),
                        Colors.black.withAlpha(200),
                        Colors.black,
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 30,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if(anime.rank != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.gradient1,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          anime.rank!,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        anime.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (anime.subCount != null) ...[
                            _infoBadge(Icons.closed_caption, anime.subCount!),
                            const SizedBox(width: 12),
                          ],
                          if (anime.dubCount != null) ...[
                            _infoBadge(Icons.mic, anime.dubCount!),
                            const SizedBox(width: 12),
                          ],
                          if (anime.type != null) ...[
                            _infoBadge(Icons.play_arrow_rounded, anime.type!),
                            const SizedBox(width: 12),
                          ],
                          if (anime.duration != null)
                            _infoBadge(Icons.timer_outlined, anime.duration!),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        anime.description ?? '',
                        style: TextStyle(
                          color: Colors.white.withAlpha(180),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 8),
        autoPlayCurve: Curves.fastOutSlowIn,
      ),
    );
  }

  Widget _infoBadge(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.gradient1),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
