import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shinobihaven/core/theme/app_theme.dart';
import 'package:shinobihaven/core/utils/search_history_box_function.dart';
import 'package:shinobihaven/features/anime/common/view/widgets/anime_card.dart';
import 'package:shinobihaven/features/anime/details/view/pages/anime_details_page.dart';
import 'package:shinobihaven/features/anime/discovery/dependency_injection/search_provider.dart';
import 'package:shinobihaven/features/anime/discovery/view/pages/search_result_page.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late final TextEditingController _searchController;
  late final FocusNode _focusNode;

  List _searchHistory = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSuggestions();
      setState(() {
        _searchHistory = SearchHistoryBoxFunction.loadHistory();
      });
    });
  }

  void _loadSuggestions() {
    ref
        .read(searchSuggestionsViewModelProvider.notifier)
        .getSearchSuggestions();
  }

  void _searchAnime(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    ref.read(searchViewModelProvider.notifier).searchAnime(query);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchSuggestions = ref.watch(searchSuggestionsViewModelProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: Stack(
                children: [
                  _buildContent(searchSuggestions),
                  if (_isSearching) _buildSearchResultsOverlay(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            spacing: 10,
            children: [
              IconButton(
                style: IconButton.styleFrom(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                icon: Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DISCOVER',
                    style: TextStyle(
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppTheme.gradient1,
                    ),
                  ),
                  const Text(
                    'Find Anime',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),
          Container(
            decoration: AppTheme.premiumCard(context, radius: 20),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: (v) => v.length > 2
                  ? _searchAnime(v)
                  : setState(() => _isSearching = false),
              onSubmitted: (query) {
                if (query.isNotEmpty) {
                  SearchHistoryBoxFunction.saveHistory(query);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SearchResultPage(query: query),
                    ),
                  );
                }
              },
              cursorColor: AppTheme.gradient1,
              decoration: InputDecoration(
                hintText: 'Search for series, movies...',
                border: InputBorder.none,
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppTheme.gradient1,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppTheme.gradient1,
                        ),
                        onPressed: () => setState(() {
                          _searchController.clear();
                          _isSearching = false;
                        }),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AsyncValue searchSuggestions) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        if (_searchHistory.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Searches',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => setState(() {
                  Hive.box('history').clear();
                  _searchHistory = [];
                }),
                child: Text(
                  'Clear All',
                  style: TextStyle(color: AppTheme.gradient1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _searchHistory.map((h) => _buildHistoryChip(h)).toList(),
          ),
          const SizedBox(height: 30),
        ],
        const Text(
          'Trending Now',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 20),
        searchSuggestions.when(
          data: (suggestions) {
            final isDesktop = MediaQuery.sizeOf(context).width > 900;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: suggestions.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isDesktop ? 6 : 3,
                childAspectRatio: 0.65,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
              ),
              itemBuilder: (context, index) =>
                  AnimeCard(anime: suggestions[index]),
            );
          },
          loading: () => _buildShimmerGrid(),
          error: (err, stack) =>
              const Center(child: Text('Failed to load suggestions')),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildHistoryChip(String label) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SearchResultPage(query: label)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.gradient1.withAlpha(20),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppTheme.gradient1.withAlpha(40)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 16, color: AppTheme.gradient1),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultsOverlay() {
    final searchResults = ref.watch(searchViewModelProvider);
    return searchResults.when(
      data: (data) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: AppTheme.blackGradient, blurRadius: 30, spreadRadius: 10),
          ],
        ),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: data.animes.take(6).length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final anime = data.animes[index];
            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: anime.image,
                  width: 45,
                  height: 65,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(
                anime.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                anime.type ?? 'TV',
                style: const TextStyle(fontSize: 12),
              ),
              onTap: () {
                if (anime.slug.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AnimeDetailsPage(animeSlug: anime.slug),
                    ),
                  );
                }
              },
            );
          },
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => const SizedBox.shrink(),
    );
  }

  Widget _buildShimmerGrid() {
    final isDesktop = MediaQuery.sizeOf(context).width > 900;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: isDesktop ? 12 : 6,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 6 : 3,
        childAspectRatio: 0.65,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
      ),
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: AppTheme.gradient1.withAlpha(20),
        highlightColor: AppTheme.gradient1.withAlpha(40),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }
}
