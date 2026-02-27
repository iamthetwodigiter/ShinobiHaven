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
            style: TextButton.styleFrom(backgroundColor: AppTheme.gradient1),
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
            icon: Icon(Icons.delete, color: AppTheme.gradient1),
          ),
        ],
      ),
      body: _items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 72, color: AppTheme.gradient1),
                  const SizedBox(height: 12),
                  Text(
                    'No animes in this collection',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.gradient1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Add some from anime details to populate this list.'),
                ],
              ),
            )
          : Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
                itemCount: _items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.sizeOf(context).width > 900 ? 3 : 1,
                  childAspectRatio: MediaQuery.sizeOf(context).width > 900 ? 2.5 : 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final anime = _items[index];
                  return Card(
                    color: AppTheme.blackGradient.withAlpha(30),
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: Center(
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: anime.image,
                            width: 50,
                            height: 70,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(
                          anime.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          anime.type ?? 'TV',
                          style: TextStyle(color: AppTheme.gradient1, fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline, color: AppTheme.gradient1),
                          onPressed: () => _removeAnime(anime),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => AnimeDetailsPage(animeSlug: anime.slug)),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
          ),
      bottomNavigationBar: null,
    );
  }
}
