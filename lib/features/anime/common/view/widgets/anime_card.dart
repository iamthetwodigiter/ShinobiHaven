import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shinobihaven/core/theme/app_theme.dart';
import 'package:shinobihaven/features/anime/common/model/anime.dart';
import 'package:shinobihaven/features/anime/details/view/pages/anime_details_page.dart';

class AnimeCard extends StatefulWidget {
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
  State<AnimeCard> createState() => _AnimeCardState();
}

class _AnimeCardState extends State<AnimeCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final double cardWidth = widget.size?.width ?? (widget.showAdditionalInfo ? 150 : 130);
    final isDesktop = MediaQuery.sizeOf(context).width > 900;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnimeDetailsPage(animeSlug: widget.anime.slug),
            ),
          );
        },
        child: AnimatedScale(
          scale: _isHovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: cardWidth,
                margin: widget.size == null ? EdgeInsets.zero : const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: _isHovered && isDesktop
                      ? [
                          BoxShadow(
                            color: AppTheme.gradient1.withAlpha(80),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        ]
                      : [],
                ),
                child: AspectRatio(
                  aspectRatio: 0.7,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: CachedNetworkImage(
                      imageUrl: widget.anime.image,
                      fit: BoxFit.cover,
                      memCacheHeight: 400,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator.adaptive()),
                      errorWidget: (context, url, error) => _buildError(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: SizedBox(
                  width: cardWidth,
                  child: Text(
                    widget.anime.title,
                    style: (widget.textStyle ?? const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)).copyWith(
                      color: _isHovered ? AppTheme.gradient1 : null,
                    ),
                    maxLines: widget.twoLineTitle ? 2 : 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (widget.showAdditionalInfo) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (widget.anime.dubCount != null) _badge(Icons.mic, widget.anime.dubCount!),
                      if (widget.anime.subCount != null) _badge(Icons.closed_caption, widget.anime.subCount!),
                      if (widget.anime.type != null) _badge(Icons.play_circle, widget.anime.type!),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error, color: AppTheme.gradient1),
        const SizedBox(height: 8),
        const Text('Image not found', style: TextStyle(fontWeight: FontWeight.w400, fontSize: 10)),
      ],
    );
  }

  Widget _badge(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: AppTheme.gradient1),
        const SizedBox(width: 2),
        Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
