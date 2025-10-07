import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shinobihaven/core/theme/app_theme.dart';
import 'package:shinobihaven/features/anime/common/view/widgets/anime_card.dart';
import 'package:shinobihaven/features/anime/discovery/dependency_injection/search_provider.dart';

class SearchResultPage extends ConsumerStatefulWidget {
  final String query;
  const SearchResultPage({super.key, required this.query});

  @override
  ConsumerState<SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends ConsumerState<SearchResultPage> {
  bool _isFilterOn = false;

  final OutlineInputBorder _border = OutlineInputBorder(
    borderSide: BorderSide(color: AppTheme.whiteGradient),
    borderRadius: BorderRadius.circular(15),
  );

  final OutlineInputBorder _focusedBorder = OutlineInputBorder(
    borderSide: BorderSide(color: AppTheme.gradient1),
    borderRadius: BorderRadius.circular(15),
  );

  final Map<String, Map<String, String>> filterOptions = {
    "type": {
      "All": "all",
      "Movie": "movie",
      "TV": "tv",
      "OVA": "ova",
      "ONA": "ona",
      "Special": "special",
      "Music": "music",
    },
    "status": {
      "All": "all",
      "Finished Airing": "finished_airing",
      "Currently Airing": "currently_airing",
      "Not yet aired": "not_yet_aired",
    },
    "rated": {
      "All": "all",
      "G": "g",
      "PG": "pg",
      "PG-13": "pg-13",
      "R": "r",
      "R+": "r+",
      "Rx": "rx",
    },
    "score": {
      "All": "all",
      "(1) Appalling": "1",
      "(2) Horrible": "2",
      "(3) Very Bad": "3",
      "(4) Bad": "4",
      "(5) Average": "5",
      "(6) Fine": "6",
      "(7) Good": "7",
      "(8) Very Good": "8",
      "(9) Great": "9",
      "(10) Masterpiece": "10",
    },
    "season": {
      "All": "all",
      "Spring": "spring",
      "Summer": "summer",
      "Fall": "fall",
      "Winter": "winter",
    },
    "language": {
      "All": "all",
      "SUB": "sub",
      "DUB": "dub",
      "SUB & DUB": "sub & dub",
    },
    "sort": {
      "Default": "default",
      "Recently Added": "recently_added",
      "Recently Updated": "recently_updated",
      "Score": "score",
      "Name A-Z": "name_az",
      "Released Date": "released_date",
      "Most Watched": "most_watched",
    },
    "genres": {
      "Action": "action",
      "Adventure": "adventure",
      "Cars": "cars",
      "Comedy": "comedy",
      "Dementia": "dementia",
      "Demons": "demons",
      "Drama": "drama",
      "Ecchi": "ecchi",
      "Fantasy": "fantasy",
      "Game": "game",
      "Harem": "harem",
      "Historical": "historical",
      "Horror": "horror",
      "Isekai": "isekai",
      "Josei": "josei",
      "Kids": "kids",
      "Magic": "magic",
      "Martial Arts": "martial arts",
      "Mecha": "mecha",
      "Military": "military",
      "Music": "music",
      "Mystery": "mystery",
      "Parody": "parody",
      "Police": "police",
      "Psychological": "psychological",
      "Romance": "romance",
      "Samurai": "samurai",
      "School": "school",
      "Sci-Fi": "sci-fi",
      "Seinen": "seinen",
      "Shoujo": "shoujo",
      "Shoujo Ai": "shoujo ai",
      "Shounen": "shounen",
      "Shounen Ai": "shounen ai",
      "Slice of Life": "slice of life",
      "Space": "space",
      "Sports": "sports",
      "Super Power": "super power",
      "Supernatural": "supernatural",
      "Thriller": "thriller",
      "Vampire": "vampire",
    },
  };

  final Map<String, String> selectedFilters = {
    "type": "",
    "status": "",
    "rated": "",
    "score": "",
    "season": "",
    "language": "",
    "sort": "default",
    "genres": "",
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSearchResults();
    });
  }

  void _loadSearchResults() {
    ref.read(searchViewModelProvider.notifier).searchAnime(widget.query);
  }

  void _applyFilters() {
    ref
        .read(searchViewModelProvider.notifier)
        .searchAnime(
          widget.query,
          type: selectedFilters['type'],
          status: selectedFilters['status'],
          rating: selectedFilters['rating'],
          score: selectedFilters['score'],
          season: selectedFilters['season'],
          language: selectedFilters['language'],
          sort: selectedFilters['sort'],
          genres: selectedFilters['genres'],
        );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final searchData = ref.watch(searchViewModelProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios),
        ),
        title: Text(
          'Search Results for ${widget.query}',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: searchData.when(
        data: (searchResults) {
          return SafeArea(
            child: Container(
              width: size.width,
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Returned ${searchResults.animes.length} Animes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _isFilterOn = !_isFilterOn;
                            });
                          },
                          icon: Icon(
                            Icons.filter_alt_rounded,
                            color: AppTheme.gradient1,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            searchResults.animes.isEmpty
                                ? Column(
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        color: AppTheme.gradient1,
                                        size: 48,
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        'No Animes Found\nTry Refining Your Search',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.whiteGradient,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  )
                                : SizedBox(
                                    width: size.width,
                                    child: Wrap(
                                      alignment: WrapAlignment.center,
                                      runSpacing: 12,
                                      spacing: 12,
                                      children: List.generate(
                                        searchResults.animes.length,
                                        (index) {
                                          final result = searchResults.animes
                                              .elementAt(index);
                                          return SizedBox(
                                            width: size.width / 2.25,
                                            child: AnimeCard(
                                              anime: result,
                                              showAdditionalInfo: false,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                        if (_isFilterOn)
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.all(12).copyWith(bottom: 25),
                              decoration: BoxDecoration(
                                color: AppTheme.blackGradient,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: AppTheme.gradient1.withValues(
                                    alpha: 0.25,
                                  ),
                                ),
                              ),
                              child: Column(
                                children: [
                                  SingleChildScrollView(
                                    child: Wrap(
                                      runSpacing: 15,
                                      spacing: 8,
                                      children: filterOptions.entries.map((
                                        entry,
                                      ) {
                                        final key = entry.key;
                                        final options = entry.value;
                                        final selectedValue =
                                            options.values.contains(
                                              selectedFilters[key],
                                            )
                                            ? selectedFilters[key]
                                            : options.values.first;
                                        return AnimatedContainer(
                                          duration: Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                          width: size.width / 2.25 - 8,
                                          child:
                                              DropdownButtonFormField<String>(
                                                isExpanded: true,
                                                decoration: InputDecoration(
                                                  labelText:
                                                      key[0].toUpperCase() +
                                                      key.substring(1),
                                                  labelStyle: TextStyle(
                                                    color:
                                                        AppTheme.whiteGradient,
                                                    fontSize: 15,
                                                  ),
                                                  filled: true,
                                                  fillColor:
                                                      AppTheme.primaryBlack,
                                                  border: _border,
                                                  enabledBorder: _border,
                                                  focusedBorder: _focusedBorder,
                                                ),
                                                iconSize: 18,
                                                padding: EdgeInsets.zero,
                                                value: selectedValue,
                                                items: options.entries.map((
                                                  opt,
                                                ) {
                                                  return DropdownMenuItem<
                                                    String
                                                  >(
                                                    value: opt.value,
                                                    child: Text(
                                                      opt.key,
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                                onChanged: (val) {
                                                  setState(() {
                                                    selectedFilters[key] =
                                                        val ?? "";
                                                  });
                                                },
                                              ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  SizedBox(height: 15),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      backgroundColor: AppTheme.gradient1,
                                      minimumSize: Size(size.width, 50),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isFilterOn = false;
                                      });
                                      _applyFilters();
                                    },
                                    child: Text(
                                      'Filter',
                                      style: TextStyle(
                                        color: AppTheme.whiteGradient,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          );
        },
        error: (err, stack) => Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.error, color: AppTheme.gradient1, size: 48),
              SizedBox(height: 16),
              Text(
                'Error occured while fetching the data.\nPlease check your internet connection or try again later.',
                style: TextStyle(
                  color: AppTheme.gradient1,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gradient1,
                ),
                onPressed: () {
                  ref
                      .read(searchViewModelProvider.notifier)
                      .searchAnime(widget.query);
                },
                child: Text(
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
                  Icons.movie,
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
    );
  }
}
