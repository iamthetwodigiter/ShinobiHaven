import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AppDetails {
  static const String version = "v1.1.0";
  static const String developer = "thetwodigiter";
  static const bool isBeta = false;
  static const String repoURL =
      "https://github.com/iamthetwodigiter/ShinobiHaven";

  static String _resolvedBasePath = '';

  static Future<void> init() async {
    try {
      if (Platform.isAndroid) {
        try {
          final dir = await getExternalStorageDirectory();
          if (dir != null && dir.path.isNotEmpty) {
            _resolvedBasePath = p.join(dir.path, 'ShinobiHaven');
            await _ensureAppDirsCreated(_resolvedBasePath);
            return;
          }
        } catch (_) {}
        _resolvedBasePath = '/storage/emulated/0/ShinobiHaven';
        await _ensureAppDirsCreated(_resolvedBasePath);
        return;
      }

      if (Platform.isIOS) {
        try {
          final dir = await getApplicationDocumentsDirectory();
          _resolvedBasePath = p.join(dir.path, 'ShinobiHaven');
          await _ensureAppDirsCreated(_resolvedBasePath);
          return;
        } catch (_) {}
        final home = Platform.environment['HOME'] ?? '';
        _resolvedBasePath = home.isNotEmpty
            ? p.join(home, 'Documents', 'ShinobiHaven')
            : 'Documents/ShinobiHaven';
        await _ensureAppDirsCreated(_resolvedBasePath);
        return;
      }

      if (Platform.isMacOS) {
        final home = Platform.environment['HOME'] ?? '';
        _resolvedBasePath = home.isNotEmpty
            ? p.join(home, 'Documents', 'ShinobiHaven')
            : 'Documents/ShinobiHaven';
        await _ensureAppDirsCreated(_resolvedBasePath);
        return;
      }

      if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'] ?? '';
        _resolvedBasePath = userProfile.isNotEmpty
            ? p.join(userProfile, 'Documents', 'ShinobiHaven')
            : p.join(
                Platform.environment['HOME'] ?? '',
                'Documents',
                'ShinobiHaven',
              );
        await _ensureAppDirsCreated(_resolvedBasePath);
        return;
      }

      _resolvedBasePath = _resolveLinuxDocumentsDir();
      await _ensureAppDirsCreated(_resolvedBasePath);
    } catch (_) {
      _resolvedBasePath = Platform.environment['HOME'] != null
          ? p.join(Platform.environment['HOME']!, 'Documents', 'ShinobiHaven')
          : 'ShinobiHaven';
      try {
        await _ensureAppDirsCreated(_resolvedBasePath);
      } catch (_) {}
    }
  }

  static Future<void> _ensureAppDirsCreated(String basePath) async {
    try {
      if (basePath.isEmpty) return;
      final baseDir = Directory(basePath);
      if (!baseDir.existsSync()) {
        await baseDir.create(recursive: true);
      }

      final downloadsDir = Directory(p.join(basePath, 'Downloads'));
      if (!downloadsDir.existsSync()) {
        await downloadsDir.create(recursive: true);
      }

      final backupDir = Directory(p.join(basePath, 'Backup'));
      if (!backupDir.existsSync()) {
        await backupDir.create(recursive: true);
      }
    } catch (_) {}
  }

  static String get basePath {
    if (_resolvedBasePath.isNotEmpty) return _resolvedBasePath;
    if (Platform.isAndroid) return '/storage/emulated/0/ShinobiHaven';
    if (Platform.isIOS) {
      return p.join(
        Platform.environment['HOME'] ?? '',
        'Documents',
        'ShinobiHaven',
      );
    }
    if (Platform.isMacOS) {
      return p.join(
        Platform.environment['HOME'] ?? '',
        'Documents',
        'ShinobiHaven',
      );
    }
    if (Platform.isWindows) {
      return p.join(
        Platform.environment['USERPROFILE'] ??
            Platform.environment['HOME'] ??
            '',
        'Documents',
        'ShinobiHaven',
      );
    }
    return _resolveLinuxDocumentsDir();
  }

  static String get appBackupDirectory =>
      p.join(basePath, 'Backup') + p.separator;
  static String get appDownloadsDirectory =>
      p.join(basePath, 'Downloads') + p.separator;

  static String _resolveLinuxDocumentsDir() {
    final home = Platform.environment['HOME'] ?? '';
    if (home.isEmpty) return 'Documents${p.separator}ShinobiHaven';
    try {
      final cfg = File(p.join(home, '.config', 'user-dirs.dirs'));
      if (cfg.existsSync()) {
        for (final line in cfg.readAsLinesSync()) {
          final m = RegExp(
            r'^\s*XDG_DOCUMENTS_DIR\s*=\s*(?:"(.*)"|(.*))\s*$',
          ).firstMatch(line);
          if (m != null) {
            var val = m.group(1) ?? m.group(2) ?? '';
            val = val.replaceAll(r'$HOME', home).replaceAll('"', '').trim();
            if (val.isEmpty) continue;
            if (val.startsWith('/')) return p.join(val, 'ShinobiHaven');
            return p.join(home, val, 'ShinobiHaven');
          }
        }
      }
    } catch (_) {}
    return p.join(home, 'Documents', 'ShinobiHaven');
  }

  static const List<Map<String, dynamic>> changelogs = [
    {
      "v1.1.0": {
        "title": "Downloads Support Added",
        "date": "2025-10-28",
        "notes": [
          "Added Downloads page to manage offline episodes",
          "Implemented episode download functionality with progress tracking",
          "Track downloads with notification updates",
          "Download queue management and error handling",
          "Improved video player stability and performance",
          "Enhanced user interface for better navigation and usability",
          "Fixed various bugs and improved overall app performance",
        ],
      },
    },
    {
      "v1.0.2-hotfix": {
        "title": "Backup Functionality Fixed",
        "date": "2025-10-08",
        "latest": true,
        "notes": [
          "Fixed the broken backup feature, cause when saving accentColor trying to store data of type MaterialAccentColor",
        ],
      },
    },
    {
      "v1.0.2": {
        "title": "Accent & Theme Improvements",
        "date": "2025-10-06",
        "notes": [
          "Dynamic accent color applied app-wide",
          "AppTheme refactored to use runtime getters so theme sub-objects (AppBar, ProgressIndicator, BottomNavigationBar) pick up the current accent",
          "ThemeProvider enhanced: added accentColor provider and updated ThemeNotifier.setAccentColor to notify app and persist changes",
          "Replaced nested unbounded ListView builders in profile/theme selector with constrained layout (GridView/Wrap) to fix RenderFlex overflow",
          "Progress indicators and bottom navigation selected item color now react to the selected accent",
          "General provider & rebuild fixes so theme changes propagate reliably across the app",
          "Background update checker added with the following capabilities:",
          "  • Periodic background checks: schedules lightweight remote manifest checks (respecting device power/data settings)",
          "  • Manual check UI: 'Check for updates' action in settings that runs the same manifest check on demand",
          "  • Dismissible update notifications: in-app notification and system notification with dismiss / remind-later actions",
          "  • Install flow: hands off to platform installer (APK intent) or prompts user per platform policy; respects install-permission state",
        ],
      },
      "v1.0.1": {
        "title": "Bug Fixes & Performance Improvements",
        "date": "2025-09-21",
        "notes": [
          "Fixed critical video player persistence issue between different anime",
          "Resolved video playback continuing when switching between anime from same section",
          "Enhanced provider state management to prevent cross-contamination of video sources",
          "Improved video player initialization with better state validation",
          "Enhanced video URL validation and cleanup to prevent cached playback issues",
          "Enhanced widget lifecycle management for better memory usage and stability",
        ],
      },
      "v1.0.0": {
        "title": "Official Release",
        "date": "2025-09-20",
        "notes": [
          "Official stable release of ShinobiHaven",
          "Added professional splash screen for enhanced app startup experience",
          "Streamlined navigation flow - Watch episodes directly from anime details without multiple page transitions",
          "Smart Watch Now button - Automatically resume from last watched episode or start from Episode 1",
          "Optimized user experience with reduced navigation steps for faster episode access",
          "Improved video player with proper disposal and single instance management",
          "Enhanced episode tracking and last watched functionality with real-time updates",
          "Better error handling and loading states throughout the app",
          "Performance optimizations for smoother streaming experience",
          "Fixed video playback continuing after navigation back",
          "Improved local storage management with Hive boxes for better data persistence",
          "UI/UX improvements and better user feedback across all screens",
          "Comprehensive bug fixes and stability improvements",
          "Advanced notification system for app updates with progress tracking",
          "In-app update checker with automatic download and installation support",
          "Smart notification management preventing spam and duplicate notifications",
          "Enhanced update installation with multiple fallback methods for better compatibility",
          "FileProvider integration for secure APK installation across Android versions",
          "Improved notification actions with proper sound and vibration control",
          "Real-time download progress updates in both dialogs and notifications",
          "Background download support with notification-based progress tracking",
          "Automatic cleanup of old notifications when new ones are generated",
          "Enhanced permission handling for storage and install packages",
          "Comprehensive app data backup and restore functionality",
          "Export and Import user data including favorites, collections, and watch history",
          "Progress indicators for backup and restore operations",
          "Enhanced privacy policy with detailed data handling information",
          "Improved changelog display with version sorting and copy functionality",
          "Better error messages and user feedback throughout the application",
          "Advanced statistics tracking for most watched anime",
          "Better file management for downloads and temporary files",
          "Enhanced security with proper file provider configuration",
          "Improved app startup performance and resource management",
        ],
      },
      "v1.0.0-pre-release": {
        "title": "Initial Release",
        "date": "2025-09-19",
        "notes": [
          "Discovery and browse anime with detailed pages including sorting and filtering",
          "Subbed and Dubbed episodes streaming with multiple format support",
          "Local library system with favorites, custom collections, and watch history",
          "Episode-level watch tracking with detailed statistics",
          "Favorites management with intuitive add and remove functionality",
          "Custom collections creation and management with card-based UI",
          "Watch history tracking with episode count and progress",
          "Top 10 most-watched anime statistics and rankings",
          "User onboarding with profile setup and theme selection",
          "Comprehensive privacy policy integrated within the app",
          "Dark mode support with consistent theming throughout",
          "Responsive design optimized for various screen sizes",
          "Local data persistence using Hive for offline functionality",
          "Search functionality with advanced filtering options",
          "Video player integration with multiple streaming sources",
          "User profile customization with avatar selection",
          "Theme preferences with light and dark mode options",
          "Data consent and disclaimer system for user transparency",
        ],
      },
      "unreleased": {
        "title": "Planned Features",
        "notes": [
          "Manga reading support with integrated viewer",
          "Cloud synchronization for cross-device data sharing",
          "User ratings and reviews system for anime",
          "Personal notes and comments for anime entries",
          "Enhanced recommendation system based on watch history",
          "Social features for sharing favorites and collections",
          "Episode download queue management",
          "Automatic quality selection based on network conditions",
          "Integration with external anime databases",
        ],
      },
    },
  ];
}
