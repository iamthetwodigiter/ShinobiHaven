import 'package:flutter/material.dart';
import 'package:shinobihaven/core/constants/app_details.dart';
import 'package:shinobihaven/core/theme/app_theme.dart';
import 'package:shinobihaven/core/utils/user_box_functions.dart';
import 'package:shinobihaven/features/anime/common/view/pages/profile_page.dart';
import 'package:shinobihaven/features/anime/discovery/view/pages/favorites_page.dart';
import 'package:shinobihaven/features/anime/discovery/view/pages/library_page.dart';
import 'package:shinobihaven/features/anime/discovery/view/pages/search_page.dart';
import 'package:shinobihaven/features/anime/home/view/pages/home_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  int _currentIndex = 0;
  final String _installedAppVersion = AppDetails.version;

  final List<Widget> _pages = [
    HomePage(),
    SearchPage(),
    FavoritesPage(),
    LibraryPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storedVersion = UserBoxFunctions.getInstalledVersion();
      if (storedVersion != _installedAppVersion) {
        _showChangelogIfNewVersion(_installedAppVersion);
      }
    });
  }

  void _showChangelogIfNewVersion(String newVersion) async {
    final current = UserBoxFunctions.getInstalledVersion();
    if (current == newVersion) return;

    final raw = AppDetails.changelogs;
    final List<MapEntry<String, dynamic>> entries = [];

    for (final item in raw) {
      for (final e in item.entries) {
        entries.add(MapEntry(e.key.toString(), e.value));
      }
    }

    int rank(String k) {
      if (k.toLowerCase() == 'unreleased') return -1;
      final ver = k.replaceAll(RegExp(r'[^0-9.]'), '');
      final parts = ver.split('.').map((s) => int.tryParse(s) ?? 0).toList();
      while (parts.length < 3) {
        parts.add(0);
      }
      return parts[0] * 10000 + parts[1] * 100 + parts[2];
    }

    entries.sort((a, b) => rank(b.key).compareTo(rank(a.key)));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.blackGradient,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 16),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Changelog",
                  style: TextStyle(
                    color: AppTheme.gradient1,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final data = entries[i].value;
                      final title = (data is Map && data['title'] != null)
                          ? data['title'].toString()
                          : entries[i].key;
                      final version = entries[i].key;
                      final notes = (data is Map && data['notes'] is List)
                          ? List<String>.from(data['notes'])
                          : <String>[];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🟢 $title [$version]',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (notes.isNotEmpty) SizedBox(height: 6),
                          ...notes.map(
                            (n) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text('• $n'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      UserBoxFunctions.setInstalledVersion(AppDetails.version);
                    },
                    child: Text(
                      'Close',
                      style: TextStyle(color: AppTheme.gradient1, fontSize: 18),
                    ),
                  ),
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (itemIndex) {
          setState(() {
            _currentIndex = itemIndex;
          });
        },

        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.view_list),
            label: 'Library',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
