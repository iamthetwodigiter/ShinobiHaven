import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shinobihaven/core/theme/app_theme.dart';
import 'package:shinobihaven/core/utils/search_history_box_function.dart';
import 'package:shinobihaven/features/anime/common/view/widgets/anime_card.dart';
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

  final OutlineInputBorder _border = OutlineInputBorder(
    borderSide: BorderSide(color: AppTheme.whiteGradient),
    borderRadius: BorderRadius.circular(15),
  );
  final OutlineInputBorder _focusedBorder = OutlineInputBorder(
    borderSide: BorderSide(color: AppTheme.gradient1),
    borderRadius: BorderRadius.circular(15),
  );

  List _searchHistory = [];

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

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final searchSuggestions = ref.watch(searchSuggestionsViewModelProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Search', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box('history').listenable(),
        builder: (context, value, child) {
          SearchHistoryBoxFunction.loadHistory();
          return SafeArea(
            child: Container(
              height: size.height,
              width: size.width,
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                children: [
                  SizedBox(height: 20),
                  Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(15),
                    // color: AppTheme.primaryBlack,
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      cursorColor: AppTheme.gradient1,
                      style: TextStyle(fontSize: 16),
                      onSubmitted: (query) {
                        setState(() {
                          SearchHistoryBoxFunction.saveHistory(query);
                          _searchHistory =
                              SearchHistoryBoxFunction.loadHistory();
                        });
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return SearchResultPage(
                                query: _searchController.text,
                              );
                            },
                          ),
                        );
                      },
                      decoration: InputDecoration(
                        hintText: 'What Would You Like to Watch?',
                        hintStyle: TextStyle(
                          // color: AppTheme.whiteGradient.withValues(alpha: 0.65),
                          fontSize: 16,
                        ),
                        border: _border,
                        enabledBorder: _border,
                        focusedBorder: _focusedBorder,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 18,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _focusNode.unfocus();
                          },
                          icon: Icon(
                            Icons.backspace,
                            size: 20,
                            color: AppTheme.gradient1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Search History',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.gradient1,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  Expanded(
                    child: _searchHistory.isNotEmpty
                        ? SingleChildScrollView(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 5,
                              children: List.generate(_searchHistory.length, (
                                index,
                              ) {
                                final history = _searchHistory.elementAt(index);
                                return InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) {
                                          return SearchResultPage(
                                            query: history,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                  child: Chip(
                                    // backgroundColor: AppTheme.blackGradient,
                                    labelPadding: EdgeInsets.symmetric(
                                      horizontal: 2,
                                      vertical: 2,
                                    ),
                                    // avatar: Icon(
                                    //   Icons.history,
                                    //   color: AppTheme.gradient1,
                                    //   size: 16,
                                    // ),
                                    label: Text(
                                      history,
                                      style: TextStyle(
                                        // color: AppTheme.whiteGradient,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    deleteIcon: Icon(
                                      Icons.close,
                                      size: 18,
                                      color: AppTheme.gradient1,
                                    ),
                                    onDeleted: () {
                                      SearchHistoryBoxFunction.deleteHistory(
                                        history,
                                      );
                                      setState(() {
                                        _searchHistory =
                                            SearchHistoryBoxFunction.loadHistory();
                                      });
                                    },
                                  ),
                                );
                              }),
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  color: AppTheme.gradient1,
                                  size: 48,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'No History. Try searching something!',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.gradient1,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                  ),
                  SizedBox(
                    child: searchSuggestions.when(
                      data: (suggestions) {
                        return Column(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Not sure what to watch?\nCheck out some of the trending animes',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.gradient1,
                                ),
                              ),
                            ),
                            SizedBox(height: 12),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: List.generate(suggestions.length, (
                                  index,
                                ) {
                                  final anime = suggestions.elementAt(index);
                                  return AnimeCard(
                                    anime: anime,
                                    size: Size(100, 150),
                                    twoLineTitle: true,
                                    textStyle: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  );
                                }),
                              ),
                            ),
                            SizedBox(height: 10),
                          ],
                        );
                      },
                      error: (err, stack) => Container(
                        alignment: Alignment.center,
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: AppTheme.gradient1,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.error,
                                color: AppTheme.gradient1,
                                size: 48,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Failed to load suggestions\nTap the button to retry.',
                              style: TextStyle(
                                color: AppTheme.gradient1,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.gradient1,
                                foregroundColor: AppTheme.whiteGradient,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                ref
                                    .read(
                                      searchSuggestionsViewModelProvider
                                          .notifier,
                                    )
                                    .getSearchSuggestions();
                              },
                              icon: Icon(Icons.refresh),
                              label: Text(
                                'Retry',
                                style: TextStyle(color: AppTheme.whiteGradient),
                              ),
                            ),
                          ],
                        ),
                      ),
                      loading: () => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Shimmer.fromColors(
                              baseColor: AppTheme.blackGradient,
                              highlightColor: AppTheme.gradient1.withAlpha(77),
                              child: Icon(
                                Icons.search,
                                size: 72,
                                color: AppTheme.whiteGradient,
                              ),
                            ),
                            SizedBox(height: 18),
                            Shimmer.fromColors(
                              baseColor: AppTheme.blackGradient,
                              highlightColor: AppTheme.gradient1.withAlpha(77),
                              child: Text(
                                'Loading...',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.whiteGradient,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
