import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shinobihaven/core/theme/app_theme.dart';
import 'package:shinobihaven/core/utils/library_box_functions.dart';
import 'package:shinobihaven/core/utils/toast.dart';
import 'package:shinobihaven/features/anime/common/model/anime.dart';
import 'package:shinobihaven/features/anime/common/view/pages/profile_page.dart';
import 'package:shinobihaven/features/anime/common/view/widgets/anime_card.dart';
import 'package:shinobihaven/features/anime/discovery/view/pages/collection_details_page.dart';
import 'package:toastification/toastification.dart';

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
                Toast(
                  context: context,
                  title: 'Removed',
                  description:
                      '${anime?.title} has been removed from collection',
                  type: ToastificationType.success,
                );
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
    return Scaffold(
      body: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: Hive.box('library').listenable(),
          builder: (context, value, child) {
            _loadCollections();
            _loadLibraryAnimes();
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          'Recently Watching',
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => WatchHistory()),
                          ),
                        ),
                        const SizedBox(height: 15),
                        _buildRecentList(),
                        const SizedBox(height: 10),
                        _buildSectionHeader('My Collections', _addUserList),
                        const SizedBox(height: 15),
                        _buildCollectionsGrid(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        title: const Text(
          'LIBRARY',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontSize: 24,
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _addUserList,
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.gradient1.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add_rounded, color: AppTheme.gradient1),
          ),
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(
            'View All',
            style: TextStyle(
              color: AppTheme.gradient1,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentList() {
    if (_libraryAnimes.isEmpty) {
      return _buildEmptyPlaceholder('No recent history.');
    }
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _libraryAnimes.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 15),
          child: AnimeCard(
            anime: _libraryAnimes[index],
            size: const Size(120, 200),
          ),
        ),
      ),
    );
  }

  Widget _buildCollectionsGrid() {
    if (_collections.isEmpty) {
      return _buildEmptyPlaceholder('Create your first collection!');
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemCount: _collections.length,
      itemBuilder: (context, index) {
        final entry = _collections.entries.elementAt(index);
        return _buildCollectionCard(entry.key, entry.value);
      },
    );
  }

  Widget _buildCollectionCard(String title, List<Anime> animes) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CollectionDetailsPage(title: title, animes: animes),
        ),
      ),
      onLongPress: () => _popUpDeleteConfirmation(title),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.gradient1.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.gradient1.withAlpha(40)),
          image: animes.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(animes.first.image),
                  fit: BoxFit.cover,
                  opacity: 0.2,
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${animes.length} Items',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPlaceholder(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: AppTheme.gradient1.withAlpha(10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.gradient1.withAlpha(20),
          style: BorderStyle.none,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.movie_filter_rounded,
            color: AppTheme.gradient1.withAlpha(100),
            size: 48,
          ),
          const SizedBox(height: 15),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[500],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
