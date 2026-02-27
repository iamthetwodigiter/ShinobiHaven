import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shinobihaven/core/constants/app_details.dart';
import 'package:shinobihaven/core/theme/app_theme.dart';
import 'package:shinobihaven/core/utils/user_box_functions.dart';
import 'package:shinobihaven/features/anime/common/view/pages/profile_page.dart';
import 'package:shinobihaven/features/anime/discovery/view/pages/favorites_page.dart';
import 'package:shinobihaven/features/anime/discovery/view/pages/library_page.dart';
import 'package:shinobihaven/features/anime/home/view/pages/home_page.dart';
import 'package:shinobihaven/features/download/view/pages/downloads_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinobihaven/features/download/dependency_injection/downloads_provider.dart';

class LandingPage extends ConsumerStatefulWidget {
  const LandingPage({super.key});

  @override
  ConsumerState<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends ConsumerState<LandingPage> {
  int _currentIndex = 0;
  final String _installedAppVersion = AppDetails.version;
  StreamSubscription? _notifSub;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomePage(),
      const FavoritesPage(),
      if (Platform.isAndroid || Platform.isIOS) const DownloadsPage(),
      const LibraryPage(),
      const ProfilePage(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storedVersion = UserBoxFunctions.getInstalledVersion();
      if (storedVersion != _installedAppVersion) {
        _showChangelogIfNewVersion(_installedAppVersion);
      }
    });

    _notifSub = ref
        .read(downloadsViewModelProvider.notifier)
        .onNotificationTap
        .listen((_) {
          if (mounted) {
            setState(() {
              _currentIndex = 2; // Downloads tab index
            });
          }
        });
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
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
      backgroundColor: AppTheme.transparentColor,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: UserBoxFunctions.isDarkMode(context)
                ? AppTheme.blackGradient
                : AppTheme.whiteGradient,
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
                    separatorBuilder: (_, _) => SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final data = entries[i].value;
                      final title = (data is Map && data['title'] != null)
                          ? data['title'].toString()
                          : entries[i].key;
                      final version = entries[i].key;
                      final date = data['date'];
                      final notes = (data is Map && data['notes'] is List)
                          ? List<String>.from(data['notes'])
                          : <String>[];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🟢 $title [$version]',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '🗓️ Released on: ${date ?? 'TO BE RELEASED'}',
                            style: TextStyle(
                              fontSize: 14,
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
    final isDark = UserBoxFunctions.isDarkMode(context);
    final size = MediaQuery.sizeOf(context);
    final isDesktop = size.width > 900;

    return Scaffold(
      extendBody: true,
      body: Row(
        children: [
          if (isDesktop)
            Container(
              width: 280,
              decoration: BoxDecoration(
                color: (isDark ? Colors.black : Colors.white).withAlpha(180),
                border: Border(
                  right: BorderSide(
                    color: AppTheme.gradient1.withAlpha(50),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Logo Area
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.gradient1,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.movie_filter_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'ShinobiHaven',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.gradient1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),
                  // Nav Items
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _desktopNavItem(
                          0,
                          'Home',
                          Icons.home_rounded,
                          Icons.home_outlined,
                        ),
                        _desktopNavItem(
                          1,
                          'Favorites',
                          Icons.favorite_rounded,
                          Icons.favorite_border_rounded,
                        ),
                        if (Platform.isAndroid || Platform.isIOS)
                          _desktopNavItem(
                            2,
                            'Downloads',
                            Icons.download_rounded,
                            Icons.download_outlined,
                          ),
                        _desktopNavItem(
                          (Platform.isAndroid || Platform.isIOS) ? 3 : 2,
                          'Library',
                          Icons.video_library_rounded,
                          Icons.video_library_outlined,
                        ),
                        _desktopNavItem(
                          (Platform.isAndroid || Platform.isIOS) ? 4 : 3,
                          'Profile',
                          Icons.person_rounded,
                          Icons.person_outline,
                        ),
                      ],
                    ),
                  ),
                  // Bottom Info
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Version $_installedAppVersion',
                      style: TextStyle(
                        color: AppTheme.greyGradient,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: IndexedStack(index: _currentIndex, children: _pages),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.black : Colors.white).withAlpha(
                        180,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: AppTheme.gradient1.withAlpha(80),
                        width: 1.5,
                      ),
                      boxShadow: AppTheme.premiumShadow,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _navItem(
                          0,
                          Icons.home_rounded,
                          Icons.home_outlined,
                          'Home',
                        ),
                        _navItem(
                          1,
                          Icons.favorite_rounded,
                          Icons.favorite_outline,
                          'Favorites',
                        ),
                        _navItem(
                          2,
                          Icons.download_rounded,
                          Icons.download_outlined,
                          'Downloads',
                        ),
                        _navItem(
                          3,
                          Icons.video_library_rounded,
                          Icons.video_library_outlined,
                          'Library',
                        ),
                        _navItem(
                          4,
                          Icons.person_rounded,
                          Icons.person_outline,
                          'Profile',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _desktopNavItem(
    int index,
    String label,
    IconData selectedIcon,
    IconData unselectedIcon,
  ) {
    final isSelected = _currentIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.gradient1.withAlpha(40)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: AppTheme.gradient1.withAlpha(80), width: 1)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? selectedIcon : unselectedIcon,
                color: isSelected ? AppTheme.gradient1 : AppTheme.greyGradient,
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? AppTheme.gradient1
                      : AppTheme.greyGradient,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    int index,
    IconData selectedIcon,
    IconData unselectedIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppTheme.gradient1 : AppTheme.greyGradient;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.gradient1.withAlpha(30)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              color: color,
              size: isSelected ? 26 : 24,
            ),
            if (isSelected)
              AnimatedOpacity(
                opacity: isSelected ? 1 : 0,
                duration: const Duration(milliseconds: 300),
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
