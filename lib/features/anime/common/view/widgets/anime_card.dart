import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shinobihaven/core/theme/app_theme.dart';
import 'package:shinobihaven/features/anime/common/model/anime.dart';
import 'package:shinobihaven/features/anime/details/view/pages/anime_details_page.dart';

class AnimeCard extends StatelessWidget {
  final Anime anime;
  final bool showAdditionalInfo;
  final Size? size;
  final bool twoLineTitle;
  final TextStyle? textStyle;
  const AnimeCard({
    super.key,
    required this.anime,
    this.showAdditionalInfo = true,
    this.size,
    this.twoLineTitle = false,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    // Determine responsive width
    final double cardWidth = size?.width ?? (showAdditionalInfo ? 150 : 130);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return AnimeDetailsPage(animeSlug: anime.slug);
            },
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: cardWidth,
            margin: size == null
                ? EdgeInsets.zero
                : const EdgeInsets.only(right: 10),
            child: AspectRatio(
              aspectRatio: 0.7,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: CachedNetworkImage(
                  imageUrl: anime.image,
                  fit: BoxFit.cover,
                  memCacheHeight: 400,
                  placeholder: (context, url) {
                    return const Center(
                      child: CircularProgressIndicator.adaptive(),
                    );
                  },
                  errorWidget: (context, url, error) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: AppTheme.gradient1),
                        const SizedBox(height: 8),
                        const Text(
                          'Image not found',
                          style: TextStyle(fontWeight: FontWeight.w400),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SizedBox(
              width: cardWidth,
              child: Text(
                anime.title,
                style:
                    textStyle ??
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                maxLines: twoLineTitle ? 2 : 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 4),
          if (showAdditionalInfo)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (anime.dubCount != null)
                    _badge(Icons.mic, anime.dubCount!),
                  if (anime.subCount != null)
                    _badge(Icons.closed_caption, anime.subCount!),
                  if (anime.type != null)
                    _badge(Icons.play_circle, anime.type!),
                  if (anime.duration != null)
                    _badge(Icons.timelapse_rounded, anime.duration!),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _badge(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: AppTheme.gradient1),
        const SizedBox(width: 2),
        Text(
          text,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
