import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:media_kit/media_kit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shinobihaven/core/constants/app_details.dart';
import 'package:shinobihaven/core/pages/onboarding_page.dart';
import 'package:shinobihaven/core/pages/splash_screen.dart';
import 'package:shinobihaven/core/services/background_update_service.dart';
import 'package:shinobihaven/core/services/download_background_service.dart';
import 'package:shinobihaven/core/theme/accent_color_adapter.dart';
import 'package:shinobihaven/core/theme/app_theme.dart';
import 'package:shinobihaven/core/theme/theme_provider.dart';
import 'package:shinobihaven/core/services/notification_service.dart';
import 'package:shinobihaven/core/utils/user_box_functions.dart';
import 'package:shinobihaven/features/anime/common/model/anime.dart';
import 'package:shinobihaven/features/anime/common/view/pages/landing_page.dart';
import 'package:shinobihaven/features/anime/details/view/pages/anime_details_page.dart';
import 'package:window_size/window_size.dart';
import 'package:shinobihaven/core/navigation/navigator_key.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitDown,
    DeviceOrientation.portraitUp,
  ]);

  if (!(Platform.isAndroid || Platform.isIOS)) {
    try {
      final initialWidth = 1280.0;
      final initialHeight = 720.0;
      setWindowTitle('ShinobiHaven');
      setWindowMinSize(const ui.Size(800, 600));
      setWindowMaxSize(const ui.Size(1920, 1200));
      setWindowFrame(ui.Rect.fromLTWH(60, 60, initialWidth, initialHeight));
    } catch (_) {}
  }

  MediaKit.ensureInitialized();
  await AppDetails.init();
  await Hive.initFlutter(
    (Platform.isAndroid || Platform.isIOS) ? null : AppDetails.basePath,
  );
  Hive.registerAdapter(AnimeAdapter());
  Hive.registerAdapter(AccentColorAdapter());

  if (!Hive.isBoxOpen('favorites')) await Hive.openBox('favorites');
  if (!Hive.isBoxOpen('library')) await Hive.openBox('library');
  if (!Hive.isBoxOpen('history')) await Hive.openBox('history');
  if (!Hive.isBoxOpen('user')) await Hive.openBox('user');

  await NotificationService.initialize();
  await BackgroundUpdateService.initialize();
  if (Platform.isAndroid || Platform.isIOS) {
    await DownloadBackgroundService.initialize();
  }

  runApp(ProviderScope(child: const ShinobiHaven()));
}

class ShinobiHaven extends ConsumerStatefulWidget {
  const ShinobiHaven({super.key});

  @override
  ConsumerState<ShinobiHaven> createState() => _ShinobiHavenState();
}

class _ShinobiHavenState extends ConsumerState<ShinobiHaven> {
  StreamSubscription<Uri>? _appLinksSub;
  final AppLinks _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initBox();
      _setupPermissions();
      _initAppLinks();
    });
  }

  Future<void> _initAppLinks() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleIncomingLink(initialUri);
      }
    } catch (_) {}

    _appLinksSub = _appLinks.uriLinkStream.listen((uri) {
      _handleIncomingLink(uri);
    }, onError: (err) {});
  }

  void _handleIncomingLink(Uri uri) {
    final host = uri.host.toLowerCase();

    if (!(host == 'shinobihaven.com' ||
        host == 'www.shinobihaven.com' ||
        host.contains('shinobihaven'))) {
      return;
    }

    final segments = uri.pathSegments
        .where((s) => s.trim().isNotEmpty)
        .toList();
    if (segments.isEmpty) return;

    final slug = segments.last.trim();
    if (slug.isEmpty) return;

    final nav = navigatorKey.currentState;
    if (nav == null) return;

    nav.pushNamed('/anime', arguments: slug);
  }

  void _setupPermissions() async {
    if (Platform.isAndroid || Platform.isIOS) {
      await [Permission.storage, Permission.manageExternalStorage].request();
      if (!Directory(AppDetails.appBackupDirectory).existsSync()) {
        Directory(AppDetails.appBackupDirectory).createSync(recursive: true);
      }
      if (!Directory(AppDetails.appDownloadsDirectory).existsSync()) {
        Directory(AppDetails.appDownloadsDirectory).createSync(recursive: true);
      }
    }
  }

  void _initBox() async {
    final userBox = Hive.box('user');
    final libraryBox = Hive.box('library');

    if (userBox.isEmpty) {
      userBox.put('firstSetup', false);
      userBox.put('installedVersion', 'v0.0.0');
      userBox.put('accentColor', AppTheme.gradient1.toARGB32());
    }
    if (libraryBox.isEmpty) {
      libraryBox.put('watched', []);
    }
  }

  @override
  void dispose() {
    _appLinksSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    ref.watch(accenetColorProvider);
    return MaterialApp(
      title: 'ShinobiHaven',
      navigatorKey: navigatorKey,
      onGenerateRoute: (settings) {
        final name = settings.name ?? '';
        final uri = Uri.tryParse(name);
        if (uri != null) {
          final segments = uri.pathSegments
              .where((s) => s.trim().isNotEmpty)
              .toList();
          if (segments.isNotEmpty && segments.first.toLowerCase() == 'anime') {
            String? slug;
            if (segments.length > 1) {
              slug = segments.last.trim();
            } else {
              slug = settings.arguments as String?;
            }
            if (slug != null && slug.isNotEmpty) {
              return MaterialPageRoute(
                builder: (_) => AnimeDetailsPage(animeSlug: slug!),
                settings: settings,
              );
            }
          }
        }

        if (name == '/anime') {
          if (settings.arguments is String) {
            return MaterialPageRoute(
              builder: (_) =>
                  AnimeDetailsPage(animeSlug: settings.arguments as String),
            );
          } else {
            return MaterialPageRoute(builder: (_) => const LandingPage());
          }
        }

        return null;
      },
      home: (Platform.isAndroid || Platform.isIOS)
          ? SplashScreen()
          : UserBoxFunctions.isSetupDone()
          ? LandingPage()
          : OnBoardingPage(),
      builder: (context, child) {
        return Container(
          decoration: AppTheme.mainBackground(context),
          child: child,
        );
      },
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
    );
  }
}
