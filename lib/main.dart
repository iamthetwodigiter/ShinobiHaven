import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shinobihaven/core/constants/app_details.dart';
import 'package:shinobihaven/core/pages/splash_screen.dart';
import 'package:shinobihaven/core/services/background_update_service.dart';
import 'package:shinobihaven/core/theme/accent_color_adapter.dart';
import 'package:shinobihaven/core/theme/app_theme.dart';
import 'package:shinobihaven/core/theme/theme_provider.dart';
import 'package:shinobihaven/core/utils/notification_service.dart';
import 'package:shinobihaven/features/anime/common/model/anime.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitDown,
    DeviceOrientation.portraitUp,
  ]);

  await Hive.initFlutter();
  Hive.registerAdapter(AnimeAdapter());
  Hive.registerAdapter(AccentColorAdapter());

  if (!Hive.isBoxOpen('favorites')) await Hive.openBox('favorites');
  if (!Hive.isBoxOpen('library')) await Hive.openBox('library');
  if (!Hive.isBoxOpen('history')) await Hive.openBox('history');
  if (!Hive.isBoxOpen('user')) await Hive.openBox('user');

  await NotificationService.initialize();
  await BackgroundUpdateService.initialize();

  runApp(ProviderScope(child: const ShinobiHaven()));
}

class ShinobiHaven extends ConsumerStatefulWidget {
  const ShinobiHaven({super.key});

  @override
  ConsumerState<ShinobiHaven> createState() => _ShinobiHavenState();
}

class _ShinobiHavenState extends ConsumerState<ShinobiHaven> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initBox();
      _setupPermissions();
    });
  }

  void _setupPermissions() async {
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();
    if(!Directory(AppDetails.appDirectory).existsSync()) {
      Directory(AppDetails.appDirectory).createSync(recursive: true);
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
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    ref.watch(accenetColorProvider);
    return MaterialApp(
      home: SplashScreen(),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
    );
  }
}
