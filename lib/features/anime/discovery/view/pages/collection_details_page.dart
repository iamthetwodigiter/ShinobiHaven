import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shinobihaven/core/theme/app_theme.dart';
import 'package:shinobihaven/core/utils/library_box_functions.dart';
import 'package:shinobihaven/features/anime/common/model/anime.dart';
import 'package:shinobihaven/features/anime/details/view/pages/anime_details_page.dart';

class CollectionDetailsPage extends StatefulWidget {
  final String title;
  final List<Anime> animes;

  const CollectionDetailsPage({
    super.key,
    required this.title,
    required this.animes,
  });

  @override
  State<CollectionDetailsPage> createState() => _CollectionDetailsPageState();
}

class _CollectionDetailsPageState extends State<CollectionDetailsPage> {
  late List<Anime> _items;

  @override
  void initState() {
    super.initState();
    _items = List<Anime>.from(widget.animes);
  }

  Future<void> _removeAnime(Anime anime) async {
    LibraryBoxFunction.removeAnimeFromCollection(widget.title, anime);
    setState(() {
      _items.removeWhere((a) => a.slug == anime.slug);
    });
  }

  Future<void> _deleteCollection() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete collection "${widget.title}"?'),
        content: Text('This will remove the collection and its references.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(backgroundColor: AppTheme.gradient2),
            child: Text('Delete', style: TextStyle(color: AppTheme.whiteGradient)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      LibraryBoxFunction.deleteCollection(widget.title);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Delete collection',
            onPressed: _deleteCollection,
            icon: Icon(Icons.delete, color: AppTheme.gradient2),
          ),
        ],
      ),
      body: _items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 72, color: AppTheme.gradient1),
                  SizedBox(height: 12),
                  Text(
                    'No animes in this collection',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.gradient1,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('Add some from anime details to populate this list.'),
                ],
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.symmetric(vertical:0),
              itemCount: _items.length,
              separatorBuilder: (_, __) => SizedBox(height: 12),
              itemBuilder: (context, index) {
                final anime = _items[index];
                return Card(
                  color: AppTheme.blackGradient.withAlpha(30),
                  margin: EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: anime.image,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        placeholder: (c, u) => Container(
                          color: AppTheme.greyGradient,
                          width: 72,
                          height: 72,
                        ),
                      ),
                    ),
                    title: Text(
                      anime.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Row(
                      children: [
                        if (anime.type != null && anime.type!.isNotEmpty) ...[
                          Text(anime.type!,
                              style: TextStyle(
                                  fontSize: 12, color: AppTheme.gradient1)),
                          SizedBox(width: 10),
                        ],
                        if (anime.dubCount != null) ...[
                          Icon(Icons.mic, size: 12, color: AppTheme.gradient1),
                          SizedBox(width: 6),
                          Text(anime.dubCount!, style: TextStyle(fontSize: 12)),
                          SizedBox(width: 10),
                        ],
                        if (anime.subCount != null) ...[
                          Icon(Icons.closed_caption, size: 12, color: AppTheme.gradient1),
                          SizedBox(width: 6),
                          Text(anime.subCount!, style: TextStyle(fontSize: 12)),
                        ],
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'remove') _removeAnime(anime);
                        if (v == 'open') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AnimeDetailsPage(animeSlug: anime.slug),
                            ),
                          );
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'open', child: Text('Open details')),
                        PopupMenuItem(
                            value: 'remove', child: Text('Remove from collection')),
                      ],
                      icon: Icon(Icons.more_vert, color: AppTheme.gradient1),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => AnimeDetailsPage(animeSlug: anime.slug)),
                      );
                    },
                  ),
                );
              },
            ),
      bottomNavigationBar: null,
    );
  }
}
