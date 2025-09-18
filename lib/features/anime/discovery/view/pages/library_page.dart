import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shinobihaven/core/theme/app_theme.dart';
import 'package:shinobihaven/core/utils/library_box_functions.dart';
import 'package:shinobihaven/features/anime/common/model/anime.dart';
import 'package:shinobihaven/features/anime/common/view/pages/profile_page.dart';
import 'package:shinobihaven/features/anime/common/view/widgets/anime_card.dart';
import 'package:shinobihaven/features/anime/discovery/view/pages/collection_details_page.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  late final TextEditingController _nameController;

  final OutlineInputBorder _border = OutlineInputBorder(
    borderSide: BorderSide(color: AppTheme.whiteGradient),
    borderRadius: BorderRadius.circular(15),
  );
  final OutlineInputBorder _focusedBorder = OutlineInputBorder(
    borderSide: BorderSide(color: AppTheme.gradient1),
    borderRadius: BorderRadius.circular(15),
  );

  final List<Anime> _libraryAnimes = [];
  final Map<String, List<Anime>> _collections = {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLibraryAnimes();
      _loadCollections();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }


  void _loadLibraryAnimes() {
    _libraryAnimes.clear();
    final keys = LibraryBoxFunction.libraryBoxKeys();
    for (String key in keys) {
      final anime = LibraryBoxFunction.getAnimeBySlug(key);
      if (anime != null) {
        _libraryAnimes.add(anime);
      }
    }
  }

  void _loadCollections() {
    _collections.clear();
    final collections = LibraryBoxFunction.getCollections();
    for (var name in collections) {
      final animes = LibraryBoxFunction.getAnimesInCollection(name);
      _collections[name] = animes;
    }
  }

  void _addUserList() {
    showAdaptiveDialog(
      context: context,
      builder: (_) {
        return AlertDialog.adaptive(
          title: Text('Add Your Custom List'),
          titleTextStyle: TextStyle(fontSize: 18, color: AppTheme.gradient1),
          content: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(15),
            child: TextField(
              controller: _nameController,
              cursorColor: AppTheme.gradient1,
              style: TextStyle(fontSize: 16),
              onSubmitted: (name) {
                final trimmed = name.trim();
                if (trimmed.isEmpty) return;
                LibraryBoxFunction.createCustomCollectionInLibrary(trimmed);
                _nameController.clear();
                _loadCollections();
                Navigator.pop(context);
              },
              decoration: InputDecoration(
                hintText: 'Enter List Name',
                hintStyle: TextStyle(fontSize: 16),
                labelStyle: TextStyle(color: AppTheme.blackGradient),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                border: _border,
                enabledBorder: _border,
                focusedBorder: _focusedBorder,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 18,
                ),
              ),
            ),
          ),
          actionsPadding: EdgeInsets.only(right: 20, bottom: 10),
          actions: [
            TextButton(
              onPressed: () {
                _nameController.clear();
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.gradient2,
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
                final name = _nameController.text.trim();
                if (name.isEmpty) return;
                LibraryBoxFunction.createCustomCollectionInLibrary(name);
                _nameController.clear();
                setState(() {
                  _loadCollections();
                });
                Navigator.pop(context);
              },
              child: Text(
                'Create',
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

  void _popUpDeleteConfirmation(String collectionName, {Anime? anime}) {
    showAdaptiveDialog(
      context: context,
      builder: (context) {
        return AlertDialog.adaptive(
          title: Text(
            anime == null
                ? 'Are you sure to delete $collectionName from Collections'
                : 'Are you sure to delete "${anime.title}" from collection "$collectionName"',
            style: TextStyle(fontSize: 18),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.gradient2,
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
                if (anime == null) {
                  LibraryBoxFunction.deleteCollection(collectionName);
                } else {
                  LibraryBoxFunction.removeAnimeFromCollection(
                    collectionName,
                    anime,
                  );
                  Navigator.pop(context);
                }
                setState(() {
                  _loadCollections();
                });
                Navigator.pop(context);
              },
              child: Text(
                'Delete',
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
        title: Text('Library', style: TextStyle(fontWeight: FontWeight.bold)),
        actionsPadding: EdgeInsets.only(right: 10),
        actions: [
          IconButton(
            onPressed: () {
              _addUserList();
            },
            icon: Icon(Icons.add),
          ),
        ],
      ),
      body: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: Hive.box('library').listenable(),
          builder: (context, value, child) {
            _loadCollections();
            _loadLibraryAnimes();
            return SizedBox(
              width: size.width,
              height: size.height,
              child: _libraryAnimes.isEmpty && _collections.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.movie,
                            size: 64,
                            color: AppTheme.gradient1,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Go watch something first',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.gradient1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 18),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Recently Watching',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.gradient1,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) {
                                        return WatchHistory();
                                      },
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                ),
                                child: Text(
                                  'View All',
                                  style: TextStyle(color: AppTheme.gradient1),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 15),
                        SizedBox(
                          height: 235,
                          child: _libraryAnimes.isEmpty
                              ? Center(
                                  child: Text(
                                    'Go watch something first',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.gradient1,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  itemCount: _libraryAnimes.length,
                                  separatorBuilder: (_, __) => SizedBox(),
                                  itemBuilder: (context, index) {
                                    final anime = _libraryAnimes[index];
                                    return SizedBox(
                                      height: 250,
                                      width: 175,
                                      child: AnimeCard(
                                        anime: anime,
                                        showAdditionalInfo: false,
                                      ),
                                    );
                                  },
                                ),
                        ),
                        SizedBox(height: 10),
                        if (_collections.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 18),
                                  child: Text(
                                    'Collections',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.gradient1,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8),
                                if (_collections.isEmpty)
                                  Center(
                                    child: Text(
                                      'Go watch something first',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.gradient1,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ..._collections.entries.map((entry) {
                                  final title = entry.key;
                                  final animes = entry.value;
                                  return Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: ListTile(
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
                                        '${animes.length} item${animes.length == 1 ? '' : 's'}',
                                        style: TextStyle(
                                          color: AppTheme.gradient1.withAlpha(
                                            150,
                                          ),
                                        ),
                                      ),
                                      trailing: IconButton(
                                        onPressed: () {
                                          _popUpDeleteConfirmation(title);
                                        },
                                        icon: Icon(
                                          Icons.delete,
                                          color: AppTheme.gradient2,
                                        ),
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                CollectionDetailsPage(
                                                  title: title,
                                                  animes: animes,
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}
