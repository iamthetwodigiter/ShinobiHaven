import 'package:flutter/material.dart';
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

  final List<Widget> _pages = [
    HomePage(),
    SearchPage(),
    FavoritesPage(),
    LibraryPage(),
    ProfilePage(),
  ];

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
