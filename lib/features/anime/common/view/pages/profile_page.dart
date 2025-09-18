import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shinobihaven/core/constants/app_details.dart';
import 'package:shinobihaven/core/constants/privacy_policy.dart';
import 'package:shinobihaven/core/theme/app_theme.dart';
import 'package:shinobihaven/core/theme/theme_provider.dart';
import 'package:shinobihaven/core/utils/library_box_functions.dart';
import 'package:shinobihaven/core/utils/toast.dart';
import 'package:shinobihaven/core/utils/user_box_functions.dart';
import 'package:shinobihaven/core/widgets/theme_choice.dart';
import 'package:shinobihaven/features/anime/common/model/anime.dart';
import 'package:shinobihaven/features/anime/details/view/pages/anime_details_page.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
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
      Toast(
        // ignore: use_build_context_synchronously
        context: context,
        title: 'Loading Error',
        description: 'Failed to load project repo. Try again later',
      );
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
      appBar: AppBar(
        elevation: 0,
        title: Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(shape: BoxShape.circle),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Image.asset(_userProfile, height: 95, width: 95),
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
                  Text('Welcome to ShinobiHaven!'),
                ],
              ),
            ),
            SizedBox(height: 24),
            _listTile(
              'Edit Profile',
              Icons.edit,
              onPressed: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditProfile()),
                );
                if (updated) {
                  _loadProfile();
                }
              },
            ),
            _listTile(
              'Set Dark Mode',
              Icons.brightness_6_rounded,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SetDarkMode()),
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
                      return WatchHistory();
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
                    builder: (context) => UserTopAnimes(userName: _userName),
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
                      return PrivacyPolicyPage();
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
                      return ChangelogPage();
                    },
                  ),
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
          ],
        ),
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
      appBar: AppBar(
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: Icon(Icons.arrow_back_ios, color: AppTheme.gradient1),
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actionsPadding: EdgeInsets.only(right: 10),
        actions: [
          IconButton(
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
                    'All right we will call you $_userName from now on',
                type: ToastificationType.success,
              );
              Navigator.pop(context, true);
            },
            icon: Text(
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
      body: SafeArea(
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
                    child: Image.asset(_userProfile, height: 95, width: 95),
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
                      padding: EdgeInsets.symmetric(horizontal: 30),
                      child: Column(
                        spacing: 8,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(15),
                            child: TextField(
                              controller: _nameController,
                              focusNode: _focusNode,
                              cursorColor: AppTheme.gradient1,
                              style: TextStyle(fontSize: 16),
                              onSubmitted: (name) {},
                              decoration: InputDecoration(
                                hintText: _userName,
                                hintStyle: TextStyle(fontSize: 16),
                                labelText: 'Enter a Username',
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
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
                          Text(
                            'Choose a profile',
                            style: TextStyle(fontSize: 18),
                          ),
                          SizedBox(
                            // height: size.height * 0.5,
                            // width: size.width,
                            child: SingleChildScrollView(
                              child: Wrap(
                                alignment: WrapAlignment.spaceEvenly,
                                spacing: 15,
                                runSpacing: 15,
                                children: List.generate(_assetsPath.length, (
                                  index,
                                ) {
                                  final asset = _assetsPath.elementAt(index);
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _focusNode.unfocus();
                                        _changeUserProfile(index);
                                      });
                                    },
                                    child: Container(
                                      height: size.width / 4,
                                      width: size.width / 4,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: _currentProfileChoice == index
                                            ? Border.all(
                                                color: AppTheme.gradient1,
                                                width: 5,
                                              )
                                            : null,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                        child: Image.asset(
                                          asset,
                                          height: 95,
                                          width: 95,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                          SizedBox(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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

  @override
  Widget build(BuildContext context) {
    final int selectedMode = UserBoxFunctions.darkModeState();
    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: Icon(Icons.arrow_back_ios, color: AppTheme.gradient1),
        ),
        title: Text(
          'Set Dark Mode',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose your theme:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 24),
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
                    themeColor: Theme.brightnessOf(context) == Brightness.light
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
            ],
          ),
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
      appBar: AppBar(
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back_ios, color: AppTheme.gradient1),
        ),
        title: Text(
          'Watch History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actionsPadding: EdgeInsets.only(right: 10),
        actions: [
          IconButton(
            onPressed: _popUpDeleteConfirmation,
            icon: Text(
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
      body: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: Hive.box('library').listenable(),
          builder: (context, _, __) {
            final items = _buildHistoryItems();
            if (items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.movie, size: 64, color: AppTheme.gradient1),
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
                    Text('Watch episodes to build your history and stats.'),
                  ],
                ),
              );
            }

            final int maxCount = items.first.totalCount;

            return ListView.separated(
              padding: EdgeInsets.symmetric(vertical: 12),
              itemCount: items.length,
              separatorBuilder: (_, __) => SizedBox(height: 8),
              itemBuilder: (context, index) {
                final it = items[index];
                final progress = maxCount > 0
                    ? (it.totalCount / maxCount)
                    : 0.0;

                return GestureDetector(
                  onTap: () {
                    if (it.anime != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) {
                            return AnimeDetailsPage(animeSlug: it.slug);
                          },
                        ),
                      );
                    }
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 12),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppTheme.blackGradient.withAlpha(30),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: it.anime != null
                              ? CachedNetworkImage(
                                  imageUrl: it.anime!.image,
                                  width: 96,
                                  height: 96,
                                  fit: BoxFit.cover,
                                  placeholder: (c, u) => Container(
                                    color: AppTheme.greyGradient,
                                    width: 96,
                                    height: 96,
                                  ),
                                )
                              : Container(
                                  width: 96,
                                  height: 96,
                                  color: AppTheme.greyGradient,
                                ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                it.anime?.title ?? it.slug,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.visibility,
                                    size: 14,
                                    color: AppTheme.gradient1,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    '${it.totalCount} view${it.totalCount == 1 ? '' : 's'}',
                                    style: TextStyle(color: AppTheme.gradient1),
                                  ),
                                  SizedBox(width: 12),
                                ],
                              ),
                              SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: progress.clamp(0.0, 1.0),
                                  minHeight: 6,
                                  backgroundColor: AppTheme.whiteGradient
                                      .withAlpha(100),
                                  valueColor: AlwaysStoppedAnimation(
                                    AppTheme.gradient1,
                                  ),
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                '${it.distinctEpisodes} episode${it.distinctEpisodes == 1 ? '' : 's'} watched',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.whiteGradient.withAlpha(150),
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
      appBar: AppBar(
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back_ios, color: AppTheme.gradient1),
        ),
        title: Text(
          "${widget.userName}'s Top Animes",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actionsPadding: EdgeInsets.only(right: 10),
      ),
      body: SafeArea(
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

            return ListView.separated(
              padding: EdgeInsets.symmetric(vertical: 12),
              itemCount: items.length,
              separatorBuilder: (_, __) => SizedBox(height: 8),
              itemBuilder: (context, index) {
                final it = items[index];
                final progress = maxCount > 0
                    ? (it.totalCount / maxCount)
                    : 0.0;
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) {
                          return AnimeDetailsPage(animeSlug: it.slug);
                        },
                      ),
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 12),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppTheme.blackGradient.withAlpha(30),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: it.anime.image,
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                            placeholder: (c, u) => Container(
                              color: AppTheme.greyGradient,
                              width: 96,
                              height: 96,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                it.anime.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.visibility,
                                    size: 14,
                                    color: AppTheme.gradient1,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    '${it.totalCount} view${it.totalCount == 1 ? '' : 's'}',
                                    style: TextStyle(color: AppTheme.gradient1),
                                  ),
                                  SizedBox(width: 12),
                                  if (it.topEpisodeId != null) ...[
                                    Icon(
                                      Icons.play_arrow,
                                      size: 14,
                                      color: AppTheme.gradient2,
                                    ),
                                    SizedBox(width: 6),
                                  ],
                                ],
                              ),
                              SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: progress.clamp(0.0, 1.0),
                                  minHeight: 6,
                                  backgroundColor: AppTheme.whiteGradient
                                      .withAlpha(100),
                                  valueColor: AlwaysStoppedAnimation(
                                    AppTheme.gradient1,
                                  ),
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                '${it.episodeCount} distinct episode${it.episodeCount == 1 ? '' : 's'} watched',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.whiteGradient.withAlpha(150),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '#${index + 1}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.gradient2,
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
      appBar: AppBar(
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: Icon(Icons.arrow_back_ios, color: AppTheme.gradient1),
        ),
        title: Text(
          'Privacy Policy',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actionsPadding: EdgeInsets.only(right: 10),
      ),
      body: SafeArea(
        child: Markdown(
          data: PrivacyPolicy.privacyPolicy,
          styleSheet: MarkdownStyleSheet(h2: TextStyle(fontSize: 16)),
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
      return rb.compareTo(ra); // descending
    });

    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final raw = AppDetails.changelogs;
    final entries = _sortedEntries(raw);

    return Scaffold(
      appBar: AppBar(
        title: Text('Changelog', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: ListView.separated(
            itemCount: entries.length,
            separatorBuilder: (_, __) => SizedBox(height: 10),
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

              return Card(
                color: AppTheme.blackGradient.withAlpha(28),
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
                              Text(date, style: TextStyle(fontSize: 12)),
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
                                style: TextStyle(fontSize: 18, height: 1.3),
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
                                content: Text('Copied changelog to clipboard'),
                              ),
                            );
                          },
                          icon: Icon(Icons.copy, color: AppTheme.gradient1),
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
    );
  }
}
