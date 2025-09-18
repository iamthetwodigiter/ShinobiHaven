import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinobihaven/core/theme/app_theme.dart';
import 'package:shinobihaven/core/utils/search_history_box_function.dart';
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
      setState(() {
        _searchHistory = SearchHistoryBoxFunction.loadHistory();
      });
    });
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
    _searchHistory = SearchHistoryBoxFunction.loadHistory();
    return Scaffold(
      appBar: AppBar(
        title: Text('Search', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
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
                      _searchHistory = SearchHistoryBoxFunction.loadHistory();
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
                          spacing: 10,
                          runSpacing: 12,
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
                                      return SearchResultPage(query: history);
                                    },
                                  ),
                                );
                              },
                              child: Chip(
                                // backgroundColor: AppTheme.blackGradient,
                                labelPadding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                avatar: Icon(
                                  Icons.history,
                                  color: AppTheme.gradient1,
                                  size: 16,
                                ),
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
                                  SearchHistoryBoxFunction.deleteHistory(history);
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
            ],
          ),
        ),
      ),
    );
  }
}
