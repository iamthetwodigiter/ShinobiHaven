import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:restart_app/restart_app.dart';
import 'package:shinobihaven/core/constants/accent_colors.dart';
import 'package:shinobihaven/core/constants/app_details.dart';
import 'package:shinobihaven/core/constants/privacy_policy.dart';
import 'package:shinobihaven/core/providers/update_provider.dart';
import 'package:shinobihaven/core/theme/app_theme.dart';
import 'package:shinobihaven/core/theme/theme_provider.dart';
import 'package:shinobihaven/core/utils/favorites_box_functions.dart';
import 'package:shinobihaven/core/utils/library_box_functions.dart';
import 'package:shinobihaven/core/utils/search_history_box_function.dart';
import 'package:shinobihaven/core/utils/toast.dart';
import 'package:shinobihaven/core/utils/update_checker.dart';
import 'package:shinobihaven/core/utils/user_box_functions.dart';
import 'package:shinobihaven/core/widgets/theme_choice.dart';
import 'package:shinobihaven/core/widgets/update_settings_sheet.dart';
import 'package:shinobihaven/features/anime/common/model/anime.dart';
import 'package:shinobihaven/features/anime/details/view/pages/anime_details_page.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late String _userProfile = UserBoxFunctions.getUserProfile();
  late String _userName = UserBoxFunctions.getUserName();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  void _loadProfile() {
    setState(() {
      _userProfile = UserBoxFunctions.getUserProfile();
      _userName = UserBoxFunctions.getUserName();
    });
  }

  void _launchGitHub() async {
    try {
      await launchUrl(
        Uri.parse(AppDetails.repoURL),
        mode: LaunchMode.platformDefault,
      );
    } catch (_) {
      if (mounted) {
        Toast(
          context: context,
          title: 'Loading Error',
          description: 'Failed to load project repo. Try again later',
        );
      }
    }
  }

  Future<void> _showUpdateSettings() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.blackGradient,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => UpdateSettingsSheet(),
    );
  }

  void _checkForUpdates() async {
    final isChecking = ref.read(updateCheckStatusProvider.notifier);
    isChecking.state = true;

    try {
      await UpdateChecker.checkForUpdates(context);
    } finally {
      isChecking.state = false;
    }
  }

  Widget _listTile(
    String title,
    IconData icon, {
    VoidCallback? onPressed,
    String? subtitle,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppTheme.gradient1),
      title: Text(title),
      trailing: subtitle != null
          ? Text(subtitle)
          : Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 15,
              ),
              title: const Text(
                'PROFILE',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.sizeOf(context).width > 900 ? MediaQuery.sizeOf(context).width * 0.2 : 24, 
              vertical: 24,
            ),
            sliver: SliverList.list(
              children: [
                Center(
                  child: Column(
                    children: [
                      Container(
                        height: 100,
                        width: 100,
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: Image.asset(
                            _userProfile,
                            height: 95,
                            width: 95,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _userName,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.gradient1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text('Welcome to ShinobiHaven!'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _listTile(
                  'Edit Profile',
                  Icons.edit,
                  onPressed: () async {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfile(),
                      ),
                    );
                    if (updated == true) {
                      _loadProfile();
                    }
                  },
                ),
                _listTile(
                  'Set App Theme',
                  Icons.color_lens_rounded,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SetDarkMode(),
                      ),
                    );
                  },
                ),
                _listTile(
                  'Watch History',
                  Icons.history,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return const WatchHistory();
                        },
                      ),
                    );
                  },
                ),
                _listTile(
                  "$_userName's Top Animes",
                  Icons.favorite,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            UserTopAnimes(userName: _userName),
                      ),
                    );
                  },
                ),
                _listTile(
                  "Manage App Data",
                  Icons.storage,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManageAppData(),
                      ),
                    );
                  },
                ),
                _listTile(
                  'Privacy Policy',
                  Icons.privacy_tip_rounded,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return const PrivacyPolicyPage();
                        },
                      ),
                    );
                  },
                ),
                _listTile(
                  'Changelog',
                  Icons.change_circle_outlined,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return const ChangelogPage();
                        },
                      ),
                    );
                  },
                ),
                _listTile(
                  'Update Settings',
                  Icons.settings_system_daydream,
                  onPressed: _showUpdateSettings,
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final isChecking = ref.watch(updateCheckStatusProvider);
                    return _listTile(
                      'Check for updates',
                      Icons.system_update_sharp,
                      onPressed: isChecking ? null : _checkForUpdates,
                      subtitle: isChecking ? 'Checking...' : null,
                    );
                  },
                ),
                _listTile(
                  'Want to contribute to the project?',
                  Icons.emoji_emotions_rounded,
                  onPressed: () {
                    _launchGitHub();
                  },
                ),
                _listTile(
                  'App Version',
                  Icons.android,
                  subtitle:
                      '${AppDetails.version} ${AppDetails.isBeta ? 'Beta' : ''}',
                ),
                _listTile(
                  'Developed with ❤️ by ${AppDetails.developer}',
                  Icons.code_rounded,
                  subtitle: '',
                ),
                const SizedBox(height: 75),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EditProfile extends ConsumerStatefulWidget {
  const EditProfile({super.key});

  @override
  ConsumerState<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends ConsumerState<EditProfile> {
  static late String _userProfile;
  static late String _userName;
  late int _currentProfileChoice = 0;

  late final TextEditingController _nameController;
  late final FocusNode _focusNode;

  final OutlineInputBorder _border = OutlineInputBorder(
    borderSide: BorderSide(color: AppTheme.whiteGradient),
    borderRadius: BorderRadius.circular(15),
  );
  final OutlineInputBorder _focusedBorder = OutlineInputBorder(
    borderSide: BorderSide(color: AppTheme.gradient1),
    borderRadius: BorderRadius.circular(15),
  );

  static final List<String> _assetsPath = [
    'assets/images/hashirama.jpg',
    'assets/images/jiraiya.jpg',
    'assets/images/kakashi.jpg',
    'assets/images/obito.jpg',
    'assets/images/naruto.jpg',
    'assets/images/sasuke.jpg',
    'assets/images/sakura.jpg',
    'assets/images/tenten.jpg',
    'assets/images/rocklee.jpg',
    'assets/images/neji.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _nameController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _loadProfile() {
    setState(() {
      _userProfile = UserBoxFunctions.getUserProfile();
      _userName = UserBoxFunctions.getUserName();
      _currentProfileChoice = _assetsPath.indexOf(_userProfile);
    });
  }

  void _changeUserProfile(int choice) {
    setState(() {
      _currentProfileChoice = choice;
      UserBoxFunctions.setUserProfile(_assetsPath.elementAt(choice));
    });
  }

  void _changeUserName(String name) {
    setState(() {
      UserBoxFunctions.setUserName(name);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    _loadProfile();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            'SETTINGS',
                            style: TextStyle(
                              letterSpacing: 2,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppTheme.gradient1,
                            ),
                          ),
                          const Text(
                            'Edit Profile',
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
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _changeUserName(
                          _nameController.text.trim().isEmpty
                              ? _userName
                              : _nameController.text.trim(),
                        );
                      });
                      Toast(
                        context: context,
                        title: 'Profile Updated',
                        description:
                            'All right we will call you ${_nameController.text.trim()} from now on',
                        type: ToastificationType.success,
                      );
                      Navigator.pop(context, true);
                    },
                    child: Text(
                      'Done',
                      style: TextStyle(
                        color: AppTheme.gradient1,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(shape: BoxShape.circle),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: Image.asset(
                            _userProfile,
                            height: 95,
                            width: 95,
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        _userName,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.gradient1,
                        ),
                      ),
                      SizedBox(height: 4),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          _focusNode.unfocus();
                        },
                        child: SingleChildScrollView(
                          child: Container(
                            width: size.width,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 800),
                              child: Column(
                                spacing: 16,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Material(
                                    elevation: 4,
                                    borderRadius: BorderRadius.circular(15),
                                    child: TextField(
                                      controller: _nameController,
                                      focusNode: _focusNode,
                                      cursorColor: AppTheme.gradient1,
                                      style: const TextStyle(fontSize: 16),
                                      onSubmitted: (name) {},
                                      decoration: InputDecoration(
                                        hintText: _userName,
                                        hintStyle: const TextStyle(fontSize: 16),
                                        labelText: 'Enter a Username',
                                        labelStyle: TextStyle(color: AppTheme.gradient1),
                                        floatingLabelBehavior:
                                            FloatingLabelBehavior.always,
                                        border: _border,
                                        enabledBorder: _border,
                                        focusedBorder: _focusedBorder,
                                        contentPadding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                          horizontal: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    'Choose a profile',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  Wrap(
                                    alignment: WrapAlignment.start,
                                    spacing: 20,
                                    runSpacing: 20,
                                    children: List.generate(
                                      _assetsPath.length,
                                      (index) {
                                        final asset = _assetsPath.elementAt(index);
                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _focusNode.unfocus();
                                              _changeUserProfile(index);
                                            });
                                          },
                                          child: Container(
                                            height: size.width > 900 ? 100 : 80,
                                            width: size.width > 900 ? 100 : 80,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: _currentProfileChoice == index
                                                  ? Border.all(
                                                      color: AppTheme.gradient1,
                                                      width: 4,
                                                    )
                                                  : null,
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(100),
                                              child: Image.asset(
                                                asset,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
  }
}

class SetDarkMode extends ConsumerStatefulWidget {
  const SetDarkMode({super.key});

  @override
  ConsumerState<SetDarkMode> createState() => _SetDarkModeState();
}

class _SetDarkModeState extends ConsumerState<SetDarkMode> {
  void _setThemeMode(int mode) {
    ref.read(themeModeProvider.notifier).setTheme(mode);
    Toast(
      context: context,
      title: 'Theme Applied',
      description: 'Dark Mode theme updated',
      type: ToastificationType.success,
    );
  }

  void _setAccentColor(Color accentColor) {
    ref.read(themeModeProvider.notifier).setAccentColor(accentColor);
  }

  @override
  Widget build(BuildContext context) {
    final int selectedMode = UserBoxFunctions.darkModeState();
    final accentColor = ref.watch(themeModeProvider.notifier).getAccentColor();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
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
                        'SETTINGS',
                        style: TextStyle(
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppTheme.gradient1,
                        ),
                      ),
                      const Text(
                        'Set App Theme',
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
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Choose your app theme:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ThemeChoice(
                              currentThemeChoice: selectedMode,
                              title: 'Light Mode',
                              titleTextColor: AppTheme.blackGradient,
                              themeColor: AppTheme.whiteGradient,
                              themeMode: 0,
                              onTap: () {
                                _setThemeMode(0);
                              },
                            ),
                            ThemeChoice(
                              currentThemeChoice: selectedMode,
                              title: 'Dark Mode',
                              titleTextColor: AppTheme.whiteGradient,
                              themeColor: AppTheme.blackGradient,
                              themeMode: 1,
                              onTap: () {
                                _setThemeMode(1);
                              },
                            ),
                            ThemeChoice(
                              currentThemeChoice: selectedMode,
                              title: 'System Choice',
                              themeColor:
                                  Theme.brightnessOf(context) == Brightness.light
                                  ? AppTheme.whiteGradient
                                  : AppTheme.blackGradient,
                              titleTextColor:
                                  Theme.brightnessOf(context) == Brightness.dark
                                  ? AppTheme.whiteGradient
                                  : AppTheme.blackGradient,
                              themeMode: 2,
                              onTap: () {
                                _setThemeMode(2);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'Choose an accent color:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: GridView.builder(
                            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 80,
                              mainAxisSpacing: 15,
                              crossAxisSpacing: 15,
                            ),
                            itemCount: AccentColors.accentColors.length,
                            itemBuilder: (context, index) {
                              final color = AccentColors.accentColors[index];
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _setAccentColor(color);
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      height: 60,
                                      width: 60,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: color,
                                        border: Border.all(
                                          color: color.toARGB32() == accentColor.toARGB32() 
                                            ? Colors.white 
                                            : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (color.toARGB32() == accentColor.toARGB32())
                                    const Icon(Icons.done, size: 30, color: Colors.white),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WatchHistory extends StatefulWidget {
  const WatchHistory({super.key});

  @override
  State<WatchHistory> createState() => _WatchHistoryState();
}

class _HistoryItem {
  final String slug;
  final Anime? anime;
  final Map<String, int> episodes;
  final int totalCount;
  final String? topEpisodeId;
  final int topEpisodeCount;
  final int distinctEpisodes;

  _HistoryItem({
    required this.slug,
    required this.anime,
    required this.episodes,
    required this.totalCount,
    required this.topEpisodeId,
    required this.topEpisodeCount,
    required this.distinctEpisodes,
  });
}

class _WatchHistoryState extends State<WatchHistory> {
  void _popUpDeleteConfirmation() {
    showAdaptiveDialog(
      context: context,
      builder: (context) {
        return AlertDialog.adaptive(
          title: Text(
            'Are you sure you want to clear Watch History?',
            style: TextStyle(fontSize: 18),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
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
                LibraryBoxFunction.clearLibrary();
                Toast(
                  context: context,
                  title: 'Well...',
                  description:
                      'Your watch history has been set to null\n[Like her feelings for you]',
                  type: ToastificationType.success,
                );
                Navigator.pop(context);
              },
              child: Text(
                'Yes',
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

  List<_HistoryItem> _buildHistoryItems() {
    final raw = LibraryBoxFunction.getWatchedMap();
    final List<_HistoryItem> items = [];

    raw.forEach((slug, entry) {
      try {
        final Anime? anime = entry['anime'] is Anime
            ? entry['anime'] as Anime
            : LibraryBoxFunction.getAnimeBySlug(slug);
        final Map<String, int> episodes = <String, int>{};
        final dynamic epRaw = entry['episodes'] ?? <String, int>{};

        if (epRaw is Map) {
          epRaw.forEach((k, v) {
            episodes[k.toString()] = (v is int)
                ? v
                : int.tryParse(v.toString()) ?? 0;
          });
        } else if (epRaw is List) {
          for (final e in epRaw) {
            final id = e.toString();
            episodes[id] = (episodes[id] ?? 0) + 1;
          }
        }

        final int total = episodes.values.fold(0, (p, n) => p + n);
        if (total > 0) {
          String? topEp;
          int topCount = 0;
          episodes.forEach((eid, c) {
            if (c > topCount) {
              topCount = c;
              topEp = eid;
            }
          });

          items.add(
            _HistoryItem(
              slug: slug,
              anime: anime,
              episodes: episodes,
              totalCount: total,
              topEpisodeId: topEp,
              topEpisodeCount: topCount,
              distinctEpisodes: episodes.length,
            ),
          );
        }
      } catch (_) {}
    });

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            'SETTINGS',
                            style: TextStyle(
                              letterSpacing: 2,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppTheme.gradient1,
                            ),
                          ),
                          const Text(
                            'Watch History',
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
                  TextButton(
                    onPressed: _popUpDeleteConfirmation,
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        color: AppTheme.gradient1,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: Hive.box('library').listenable(),
                builder: (context, _, _) {
                  final items = _buildHistoryItems();
                  if (items.isEmpty) {
                    return Center(
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
                            'No watch history yet',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.gradient1,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Watch episodes to build your history and stats.',
                          ),
                        ],
                      ),
                    );
                  }

                  final int maxCount = items.first.totalCount;

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    itemCount: items.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.sizeOf(context).width > 900 ? 3 : 1,
                      childAspectRatio: MediaQuery.sizeOf(context).width > 900 ? 2.5 : 3.5,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemBuilder: (context, index) {
                      final it = items[index];
                      final progress = maxCount > 0 ? (it.totalCount / maxCount) : 0.0;

                      return GestureDetector(
                        onTap: () {
                          if (it.anime != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AnimeDetailsPage(animeSlug: it.slug),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: AppTheme.cardColor(context).withAlpha(150),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: it.anime != null
                                    ? CachedNetworkImage(
                                        imageUrl: it.anime!.image,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: 80,
                                        height: 80,
                                        color: AppTheme.greyGradient,
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      it.anime?.title ?? it.slug,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.visibility,
                                          size: 14,
                                          color: AppTheme.gradient1,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${it.totalCount} views',
                                          style: TextStyle(
                                            color: AppTheme.gradient1,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: progress.clamp(0.0, 1.0),
                                        minHeight: 4,
                                        backgroundColor: AppTheme.whiteGradient.withAlpha(50),
                                        valueColor: AlwaysStoppedAnimation(AppTheme.gradient1),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserTopAnimes extends StatefulWidget {
  final String userName;
  const UserTopAnimes({super.key, required this.userName});

  @override
  State<UserTopAnimes> createState() => _UserTopAnimesState();
}

class _TopAnimeItem {
  final String slug;
  final Anime anime;
  final int totalCount;
  final String? topEpisodeId;
  final int topEpisodeCount;
  final int episodeCount;

  _TopAnimeItem({
    required this.slug,
    required this.anime,
    required this.totalCount,
    required this.topEpisodeId,
    required this.topEpisodeCount,
    required this.episodeCount,
  });
}

class _UserTopAnimesState extends State<UserTopAnimes> {
  List<_TopAnimeItem> _buildTopList() {
    final Map<String, dynamic> raw = LibraryBoxFunction.getWatchedMap();
    final List<_TopAnimeItem> items = [];

    raw.forEach((slug, value) {
      try {
        final Map<String, dynamic> entry = value as Map<String, dynamic>;
        Anime? animeData = (entry['anime'] is Anime)
            ? entry['anime'] as Anime
            : LibraryBoxFunction.getAnimeBySlug(slug);
        final Map<String, int> episodes = <String, int>{};
        final dynamic epRaw = entry['episodes'] ?? entry;
        if (epRaw is Map) {
          epRaw.forEach((k, v) {
            episodes[k.toString()] = (v is int)
                ? v
                : int.tryParse(v.toString()) ?? 0;
          });
        } else if (epRaw is List) {
          for (final e in epRaw) {
            final id = e.toString();
            episodes[id] = (episodes[id] ?? 0) + 1;
          }
        }
        final int total = episodes.values.fold(0, (p, n) => p + n);
        if (animeData != null && total > 0) {
          String? topEpisode;
          int topCount = 0;
          episodes.forEach((eid, c) {
            if (c > topCount) {
              topCount = c;
              topEpisode = eid;
            }
          });

          items.add(
            _TopAnimeItem(
              slug: slug,
              anime: animeData,
              totalCount: total,
              topEpisodeId: topEpisode,
              topEpisodeCount: topCount,
              episodeCount: episodes.length,
            ),
          );
        }
      } catch (_) {}
    });

    items.sort((a, b) => b.totalCount.compareTo(a.totalCount));
    return items.take(10).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
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
                        'SETTINGS',
                        style: TextStyle(
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppTheme.gradient1,
                        ),
                      ),
                      Text(
                        "${widget.userName}'s Top Animes",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: Hive.box('library').listenable(),
                builder: (context, box, _) {
                  final items = _buildTopList();
                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite_border,
                            size: 72,
                            color: AppTheme.gradient1,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No viewing history yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.gradient1,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text('Watch some episodes to see your top animes.'),
                        ],
                      ),
                    );
                  }

                  final int maxCount = items.first.totalCount;

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    itemCount: items.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.sizeOf(context).width > 900 ? 3 : 1,
                      childAspectRatio: MediaQuery.sizeOf(context).width > 900 ? 2.5 : 3.5,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemBuilder: (context, index) {
                      final it = items[index];
                      final progress = maxCount > 0 ? (it.totalCount / maxCount) : 0.0;
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AnimeDetailsPage(animeSlug: it.slug),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: AppTheme.cardColor(context).withAlpha(150),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: CachedNetworkImage(
                                  imageUrl: it.anime.image,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      it.anime.title,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.visibility,
                                          size: 14,
                                          color: AppTheme.gradient1,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${it.totalCount} views',
                                          style: TextStyle(
                                            color: AppTheme.gradient1,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: progress.clamp(0.0, 1.0),
                                        minHeight: 4,
                                        backgroundColor: AppTheme.whiteGradient.withAlpha(50),
                                        valueColor: AlwaysStoppedAnimation(AppTheme.gradient1),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '#${index + 1}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.gradient1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
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
                        'SETTINGS',
                        style: TextStyle(
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppTheme.gradient1,
                        ),
                      ),
                      const Text(
                        'Privacy Policy',
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
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Markdown(
                    data: PrivacyPolicy.privacyPolicy,
                    styleSheet: MarkdownStyleSheet(h2: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChangelogPage extends StatelessWidget {
  const ChangelogPage({super.key});

  List<MapEntry<String, dynamic>> _sortedEntries(dynamic raw) {
    final List<MapEntry<String, dynamic>> entries = [];

    for (final item in raw) {
      if (item is Map) {
        for (final e in item.entries) {
          entries.add(MapEntry(e.key.toString(), e.value));
        }
      }
    }

    int rank(String k) {
      if (k.toLowerCase() == 'unreleased') return 999999;
      final ver = k.replaceAll(RegExp(r'[^0-9.]'), '');
      final parts = ver.split('.').map((s) => int.tryParse(s) ?? 0).toList();
      while (parts.length < 3) {
        parts.add(0);
      }
      return parts[0] * 10000 + parts[1] * 100 + parts[2];
    }

    entries.sort((a, b) {
      final ra = rank(a.key);
      final rb = rank(b.key);
      return rb.compareTo(ra);
    });

    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final raw = AppDetails.changelogs;
    final entries = _sortedEntries(raw);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
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
                        'ABOUT',
                        style: TextStyle(
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppTheme.gradient1,
                        ),
                      ),
                      const Text(
                        'Changelog',
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
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                    child: ListView.separated(
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final key = entries[index].key;
                        final data = entries[index].value;
                    final title = (data is Map && data['title'] != null)
                        ? data['title'].toString()
                        : key;
                    final date = (data is Map && data['date'] != null)
                        ? data['date'].toString()
                        : null;
                    final notes = (data is Map && data['notes'] is List)
                        ? List<String>.from(data['notes'])
                        : <String>[];
                    final isLatest = (data is Map && data['latest'] != null);

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        collapsedIconColor: AppTheme.gradient1,
                        iconColor: AppTheme.gradient1,
                        title: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (date != null) ...[
                                    SizedBox(height: 4),
                                    Row(
                                      spacing: 8,
                                      children: [
                                        Text(
                                          date,
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        if (isLatest)
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryGreen
                                                  .withValues(alpha: 0.25),
                                              border: Border.all(
                                                color: AppTheme.primaryGreen,
                                                width: 0.5,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                            child: Text(
                                              'Latest',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.gradient1.withAlpha(30),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                key,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        childrenPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        children: [
                          if (notes.isNotEmpty) ...[
                            SizedBox(height: 8),
                            ...notes.map(
                              (n) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '• ',
                                      style: TextStyle(
                                        fontSize: 18,
                                        height: 1.3,
                                      ),
                                    ),
                                    Expanded(child: Text(n)),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 6),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  final buffer = StringBuffer();
                                  buffer.writeln(title);
                                  if (date != null) buffer.writeln(date);
                                  if (notes.isNotEmpty) {
                                    buffer.writeln("\nWhat's new:");
                                    for (final n in notes) {
                                      buffer.writeln('- $n');
                                    }
                                  }
                                  Clipboard.setData(
                                    ClipboardData(text: buffer.toString()),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Copied changelog to clipboard',
                                      ),
                                    ),
                                  );
                                },
                                icon: Icon(
                                  Icons.copy,
                                  color: AppTheme.gradient1,
                                ),
                                label: Text(
                                  'Copy',
                                  style: TextStyle(color: AppTheme.gradient1),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ManageAppData extends StatefulWidget {
  const ManageAppData({super.key});

  @override
  State<ManageAppData> createState() => _ManageAppDataState();
}

class _ManageAppDataState extends State<ManageAppData> {
  bool _isBackingUp = false;
  bool _isRestoring = false;

  void _clearData() {
    showAdaptiveDialog(
      context: context,
      builder: (context) {
        return AlertDialog.adaptive(
          title: Text(
            'Are you sure to delete app data?',
            style: TextStyle(fontSize: 18),
          ),
          content: Text(
            'This will delete animes added in the library collections, favorites, your watch history and search history.',
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
                LibraryBoxFunction.clearLibrary();
                FavoritesBoxFunctions.clearFavorites();
                SearchHistoryBoxFunction.clearHistory();
                Toast(
                  context: context,
                  title: 'Data Cleared',
                  description: 'All app data has been cleared successfully',
                  type: ToastificationType.success,
                );
                Navigator.pop(context);
              },
              child: Text(
                'Clear',
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

  void _backupData() async {
    setState(() {
      _isBackingUp = true;
    });

    try {
      final backupPath = await UserBoxFunctions.backupAllData();

      if (backupPath != null) {
        if (mounted) {
          final fileName = backupPath.split('/').last;
          Toast(
            context: context,
            title: 'Backup Successful',
            description: 'Data backed up successfully',
            type: ToastificationType.success,
          );

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Backup Created'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your data has been successfully backed up!'),
                  SizedBox(height: 12),
                  Text(
                    'File: $fileName',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Location: ${Platform.isAndroid ? 'ShinobiHaven folder' : 'Documents folder'}',
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Keep this file safe to restore your data later.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'OK',
                    style: TextStyle(color: AppTheme.gradient1),
                  ),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          Toast(
            context: context,
            title: 'Backup Failed',
            description: 'Failed to create backup. Please check permissions.',
            type: ToastificationType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Toast(
          context: context,
          title: 'Backup Error',
          description: 'An error occurred while creating backup',
          type: ToastificationType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBackingUp = false;
        });
      }
    }
  }

  void _restoreData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Restore from Backup'),
        content: Text(
          'This will replace ALL current data with data from the backup file. This action cannot be undone.\n\nMake sure you have selected the correct backup file.\n\nAre you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: AppTheme.gradient1)),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: AppTheme.gradient1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Restore',
              style: TextStyle(color: AppTheme.whiteGradient),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isRestoring = true;
    });

    try {
      final success = await UserBoxFunctions.restoreFromBackup();

      if (success) {
        if (mounted) {
          Toast(
            context: context,
            title: 'Restore Successful',
            description: 'Data has been restored from backup successfully',
            type: ToastificationType.success,
          );
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Text('Restore Complete'),
              content: Text(
                'Your data has been successfully restored from the backup file!\n\nRestarting the app for all changes to take effect properly.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Restart.restartApp();
                  },
                  child: Text(
                    'OK',
                    style: TextStyle(color: AppTheme.gradient1),
                  ),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          Toast(
            context: context,
            title: 'Restore Failed',
            description:
                'Failed to restore from backup. Please check the file format.',
            type: ToastificationType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Toast(
          context: context,
          title: 'Restore Error',
          description: 'An error occurred while restoring data',
          type: ToastificationType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRestoring = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
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
                        'SETTINGS',
                        style: TextStyle(
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppTheme.gradient1,
                        ),
                      ),
                      const Text(
                        'Manage Data',
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
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Column(
                      spacing: 8,
                      children: [
                        const SizedBox(height: 10),
                        ListTile(
                          tileColor: AppTheme.cardColor(context).withAlpha(100),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          leading: _isBackingUp
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.gradient1,
                                  ),
                                )
                              : Icon(
                                  Icons.backup,
                                  size: 18,
                                  color: AppTheme.gradient1,
                                ),
                          title: const Text('Backup App Data'),
                          subtitle: const Text('Save all your data to a file'),
                          trailing: _isBackingUp
                              ? null
                              : const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: _isBackingUp ? null : _backupData,
                        ),
                        ListTile(
                          tileColor: AppTheme.cardColor(context).withAlpha(100),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          leading: _isRestoring
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.gradient1,
                                  ),
                                )
                              : Icon(
                                  Icons.restore,
                                  size: 18,
                                  color: AppTheme.gradient1,
                                ),
                          title: const Text('Restore from Backup'),
                          subtitle: const Text('Load data from a backup file'),
                          trailing: _isRestoring
                              ? null
                              : const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: _isRestoring ? null : _restoreData,
                        ),
                        ListTile(
                          tileColor: AppTheme.cardColor(context).withAlpha(100),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          leading: Icon(
                            Icons.delete,
                            size: 18,
                            color: AppTheme.gradient1,
                          ),
                          title: const Text('Clear App Data'),
                          subtitle: const Text('Delete all local data'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: _clearData,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
