import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shinobihaven/features/anime/common/model/anime.dart';
import 'package:shinobihaven/features/anime/details/view/pages/anime_details_page.dart';

class AnimeCard extends StatelessWidget {
  final Anime anime;
  final bool showAdditionalInfo;
  final Size? size;
  const AnimeCard({
    super.key,
    required this.anime,
    this.showAdditionalInfo = true,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
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
            height: size?.height ?? 200,
            width: size?.width ?? 150,
            margin: EdgeInsets.only(right: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: CachedNetworkImage(
                imageUrl: anime.image,
                fit: BoxFit.cover,
                placeholder: (context, url) {
                  return Center(child: CircularProgressIndicator.adaptive());
                },
              ),
            ),
          ),
          SizedBox(height: 5),
          SizedBox(
            width: 150,
            child: Text(
              anime.title,
              style: TextStyle(
                // color: AppTheme.whiteGradient,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: 5),
          if (showAdditionalInfo)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 10,
              children: [
                if (anime.dubCount != null)
                  Row(
                    children: [
                      Icon(Icons.mic, size: 10),
                      Text(
                        anime.dubCount ?? '',
                        style: TextStyle(
                          // color: AppTheme.whiteGradient,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                if (anime.subCount != null)
                  Row(
                    children: [
                      Icon(Icons.closed_caption, size: 10),
                      Text(
                        anime.subCount ?? '',
                        style: TextStyle(
                          // color: AppTheme.whiteGradient,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                if (anime.type != null)
                  Row(
                    children: [
                      Icon(Icons.play_circle, size: 10),
                      Text(
                        anime.type ?? '',
                        style: TextStyle(
                          // color: AppTheme.whiteGradient,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                if (anime.duration != null)
                  Row(
                    children: [
                      Icon(Icons.timelapse_rounded, size: 10),
                      Text(
                        anime.duration ?? '',
                        style: TextStyle(
                          // color: AppTheme.whiteGradient,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
