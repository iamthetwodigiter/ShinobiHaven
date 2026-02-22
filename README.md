# ShinobiHaven - Anime Streaming Mobile App

A feature-rich Flutter application for anime discovery and streaming, built with feature-based MVVM pattern and modern development practices for a scalable, maintainable cross-platform solution.

![Flutter](https://img.shields.io/badge/Flutter-3.32.8-blue)
![Dart](https://img.shields.io/badge/Dart-3.8.1-blue)
![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS%20%7C%20Web-orange)
![License](https://img.shields.io/badge/License-MIT-green)
![Version](https://img.shields.io/badge/Version-v1.2.0-brightgreen)
![Downloads](https://img.shields.io/github/downloads/iamthetwodigiter/shinobihaven/total?label=Downloads&logo=GitHub)

## 📱 Overview

ShinobiHaven is a comprehensive anime streaming application that provides users with a seamless experience for discovering, streaming, and managing their anime content. The app follows feature-based MVVM pattern with advanced update management, professional splash screens, and comprehensive data backup capabilities.

### Key Highlights
- **Architecture**: Feature-based MVVM architecture with clear separation of concerns
- **Modern State Management**: Riverpod for efficient state management and dependency injection
- **Local Storage**: Hive database for offline-first approach with backup/restore functionality
- **Cross-Platform**: Flutter for Android, iOS[To-Do], Web[To-Do], Windows[To-Do], Linux[To-Do] platforms
- **Privacy-Focused**: Local data storage with comprehensive backup and restore capabilities
- **Auto-Update System**: In-app update checker with notification support and automatic installation
- **Professional UI**: Native splash screen implementation with proper scaling and theming
- **Bug-Free Streaming**: Enhanced video player with fixed persistence issues and state management

## 🚀 Latest Updates (v1.2.0)

### 🎨 UI Revamp
- **Glassmorphism Design**: Overhauled UI with modern glassmorphism and gradient design language across all major pages
- **Profile Page Redesign**: Completely rebuilt profile page with improved layout and visual hierarchy
- **Anime Details Overhaul**: Streamlined anime details page with a cleaner, more intuitive layout
- **Episode & Stream Pages**: Refreshed episodes and stream pages with consistent new design system
- **Home & Search Pages**: Updated home, search, and library pages for visual consistency
- **Spotlight Cards**: Redesigned spotlight/hero cards with gradient overlay polish
- **Anime Cards**: Updated anime card components with improved styling
- **Theme Consistency**: Fixed theming and UI inconsistencies throughout the app

### 🔔 Native Notification & Playback Controls
- **Native Android Notifications**: Replaced Flutter-based notifications with a fully native Android notification system for better reliability
- **Playback Controls in Notification**: Play/pause, previous, and next episode controls directly from the notification shade
- **Notification onTap Navigation**: Tapping the playback notification navigates directly to the correct episode stream page
- **Global Navigator Key**: Added a global navigator key to enable context-free navigation from native callbacks

### ⬇️ Background Download Service
- **Native Background Downloads**: Implemented a native Android `DownloadService` (Kotlin) for robust background episode downloads
- **Download State Models**: Added `DownloadTask` and `DownloadsState` models for structured download management
- **Downloads Repository Refactor**: Significantly refactored the downloads repository for reliability and performance
- **Progress Notifications**: Real-time download progress updates pushed through native notifications

### 🐛 Bug Fixes & Improvements
- **App Exit/Crash Fix**: Resolved major application exit issue (carried forward from v1.1.2)
- **Player Service**: Extracted player lifecycle logic into a dedicated `PlayerService` for cleaner separation
- **Performance**: General performance improvements and removal of redundant rebuilds
- **Minor Bug Fixes**: Various small fixes improving overall stability

## 🏗️ Architecture

### Enhanced MVVM Architecture Pattern

```
┌─────────────────────────┐
│       View Layer        │  ◄── UI Components, Pages, Widgets
├─────────────────────────┤
│     ViewModel Layer     │  ◄── State Management, Business Logic
├─────────────────────────┤
│       Model Layer       │  ◄── Data Models, Entities
├─────────────────────────┤
│     Repository Layer    │  ◄── Data Sources, API Integration
├─────────────────────────┤
│     Update Management   │  ◄── Version Control, Download Management
├─────────────────────────┤
│      Storage Layer      │  ◄── Local Storage, Backup/Restore
└─────────────────────────┘
```

### Enhanced Project Structure

```
lib/
├── core/
│   ├── constants/           # App constants, privacy policy, changelog
│   ├── pages/              # Core pages (onboarding, splash)
│   ├── theme/              # App theming & styling
│   └── utils/              # Utilities, Hive helpers, update checker, notifications
├── features/               # Feature-based modules
│   └── anime/
│       ├── common/         # Shared anime components
│       │   ├── model/      # Anime data models with Hive adapters
│       │   └── view/       # Shared UI components, enhanced profile page
│       ├── details/        # Anime details with streamlined navigation
│       ├── discovery/      # Enhanced search & browse
│       ├── episodes/       # Improved episode management
│       ├── home/           # Home dashboard with better statistics
│       └── stream/         # Optimized video streaming with fixed persistence
└── main.dart              # Application entry point with splash integration
```

### New Core Components

```
core/utils/
├── update_checker.dart     # GitHub release checking and update management
├── notification_service.dart # Advanced notification system
├── backup_manager.dart     # Data backup and restore functionality
├── file_manager.dart       # File operations and storage management
└── user_box_functions.dart # Enhanced user data management
```

## 🔑 Enhanced Features

### Core Functionality
- **Anime Discovery**: Browse trending, popular, and latest anime with improved filtering
- **Advanced Search**: Enhanced filter options with better performance
- **Anime Details**: Comprehensive information with streamlined episode access
- **Episode Streaming**: Multi-server support with improved video player management (v1.0.1 fixes)
- **Smart Navigation**: Direct episode access with reduced navigation steps
- **Favorites Management**: Enhanced favorite system with better organization
- **Watch History**: Detailed tracking with automatic resume functionality
- **Custom Collections**: Improved collection management with better UI

### Advanced Features (v1.0.0+)
- **Auto-Update System**: Complete update management with GitHub integration
- **Data Backup/Restore**: Comprehensive backup system for all user data
- **Notification Management**: Smart notification system with lifecycle management
- **Professional Splash**: Native splash screen with proper scaling
- **Enhanced Privacy**: Updated privacy policy with detailed data handling information
- **Performance Optimization**: Better resource management and startup performance

### Latest Bug Fixes (v1.0.1)
- **Video Player Stability**: Fixed critical video persistence issues between different anime
- **State Management**: Enhanced provider state management with proper cleanup
- **Memory Management**: Improved widget lifecycle and memory usage
- **Cross-Section Navigation**: Fixed video playback issues when switching between app sections
- **Provider Disposal**: Resolved "Bad state" errors during navigation and provider disposal

### User Experience Improvements
- **Streamlined UI/UX**: Reduced navigation steps for common actions
- **Better Feedback**: Enhanced error messages and user guidance
- **Progress Tracking**: Real-time updates for all background operations
- **Theme Integration**: Consistent dark mode theming throughout the app
- **Accessibility**: Improved accessibility features and navigation

## 🛠️ Technical Implementation

### Enhanced State Management & Dependency Injection

```dart
// Enhanced Repository Provider with caching
final animeDetailsRepositoryProvider = Provider((ref) => AnimeDetailsRepository());

// Section-aware ViewModel Provider
final animeDetailsViewModelProvider = 
    StateNotifierProvider.family<AnimeDetailsViewmodel, AsyncValue<AnimeDetails>, String>((ref, animeSlug) {
  final repository = ref.watch(animeDetailsRepositoryProvider);
  return AnimeDetailsViewmodel(repository, animeSlug);
});

// Fixed Video Streaming Provider (v1.0.1)
final sourcesViewModelProvider = StateNotifierProvider<SourcesViewmodel, AsyncValue<Sources>>((ref) {
  return SourcesViewmodel();
});

// Usage in UI with proper disposal
class AnimeDetailsPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animeDetails = ref.watch(animeDetailsViewModelProvider(widget.animeSlug));
    return animeDetails.when(
      data: (data) => AnimeDetailsView(data),
      loading: () => LoadingWidget(),
      error: (error, stack) => ErrorWidget(error),
    );
  }
}
```

### Advanced Update Management

```dart
class UpdateChecker {
  static Future<GitHubRelease?> checkForUpdates() async {
    final response = await http.get(Uri.parse('$githubApiUrl/releases/latest'));
    if (response.statusCode == 200) {
      final release = GitHubRelease.fromJson(json.decode(response.body));
      return _compareVersions(release.tagName, AppDetails.version) > 0 ? release : null;
    }
    return null;
  }

  static Future<void> downloadAndInstallUpdate(BuildContext context, GitHubRelease release) async {
    // Multi-stage download with progress tracking
    // Notification management
    // Installation with multiple fallback methods
  }
}
```

### Enhanced Video Player Management (v1.0.1 Fix)

```dart
class _SourcesPageState extends ConsumerState<SourcesPage> {
  // Section-aware cache key to prevent cross-contamination
  String get _cacheKey => '${widget.anime.slug}-${_currentPlayingEpisode?.episodeID ?? ''}-${DateTime.now().millisecondsSinceEpoch}';

  void _clearAnimeSpecificProviders() {
    if (_isDisposing || !mounted) return;
    
    try {
      // Force clear all possible cached providers
      ref.invalidate(serversViewModelProvider(widget.anime.slug));
      ref.invalidate(sourcesViewModelProvider);
      ref.invalidate(vidSrcSourcesProvider(_cacheKey));
    } catch (e) {
      print('Provider invalidation error: $e');
    }
  }

  Future<void> _setupBetterPlayer(String videoUrl, List<Captions> captions) async {
    // Always dispose previous player when setting up new one
    _forceDisposePlayer();
    await Future.delayed(Duration(milliseconds: 300));
    
    // Enhanced video player initialization with proper state management
    _betterPlayerController = BetterPlayerController(/* configuration */);
  }
}
```

### Comprehensive Backup System

```dart
class BackupManager {
  static Future<void> exportUserData() async {
    final backupData = {
      'favorites': FavoritesBoxFunctions.listFavorites(),
      'library': LibraryBoxFunctions.getLibraryAnimes(),
      'collections': LibraryBoxFunctions.getCollections(),
      'watchHistory': LibraryBoxFunctions.getWatchedHistory(),
      'userPreferences': UserBoxFunctions.getAllPreferences(),
      'metadata': {
        'exportDate': DateTime.now().toIso8601String(),
        'appVersion': AppDetails.version,
        'dataVersion': '1.0',
      }
    };
    // File creation, validation, and export
  }

  static Future<void> importUserData(String filePath) async {
    // Data validation, backup creation, and import with progress tracking
  }
}
```

### Enhanced Local Storage with Hive

```dart
// Enhanced User Box Functions with backup support
class UserBoxFunctions {
  static Map<String, dynamic> getAllPreferences() {
    final userBox = Hive.box('user');
    return {
      'firstSetup': userBox.get('firstSetup', defaultValue: false),
      'installedVersion': userBox.get('installedVersion', defaultValue: ''),
      'darkMode': userBox.get('darkMode', defaultValue: 1),
      'userName': userBox.get('userName', defaultValue: ''),
      'userProfile': userBox.get('userProfile', defaultValue: ''),
    };
  }

  static Future<void> exportData() async {
    // Enhanced export functionality with progress tracking
  }

  static Future<void> importData(Map<String, dynamic> data) async {
    // Enhanced import with validation and error handling
  }
}
```

### Technical Stack Updates

| Category | Technologies |
|----------|--------------|
| **Framework** | Flutter 3.32.8 |
| **Language** | Dart 3.8.1 |
| **Platforms** | Android, iOS [To-Do], Web[To-Do], Windows[To-Do], Linux[To-Do] |
| **State Management** | Riverpod |
| **Architecture** | Feature based MVVM |
| **Local Storage** | Hive with Backup/Restore |
| **Networking** | HTTP package, Dio for downloads |
| **Media** | Cached Network Image, Custom Video Player (media_kit) |
| **UI Enhancement** | Shimmer, Carousel Slider |
| **Notifications** | Flutter Local Notifications, Toastification |
| **File Management** | Path Provider, File Picker, Open File |
| **Permissions** | Permission Handler |
| **Device Info** | Device Info Plus |
| **App Management** | Restart App, Android Intent Plus |
| **External Links** | URL Launcher |

## 🚀 Getting Started

### Prerequisites

- Flutter 3.32.8 or higher
- Dart 3.8.1 or higher
- Android Studio / VS Code with Flutter extensions
- Git for version control
- Android SDK (for Android development)

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/iamthetwodigiter/ShinobiHaven.git
cd ShinobiHaven
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Generate Hive adapters**
```bash
dart run build_runner build
```

4. **Run the application**
```bash
# For Android
flutter run

# For release build
flutter build apk --release
```

### Development Setup

1. **Initialize Hive boxes** (automatically handled in main.dart)
```dart
await Hive.initFlutter();
Hive.registerAdapter(AnimeAdapter());

// Open required boxes
await Hive.openBox('favorites');
await Hive.openBox('library');
await Hive.openBox('history');
await Hive.openBox('user');
```

2. **Configure update system**
```dart
// Update checker runs automatically on app start
// No additional configuration required
```

3. **Set up notification system**
```dart
// Notifications initialized automatically
// Permissions requested on first use
```

## 📊 Enhanced Project Roadmap

- **Phase 1**: Core functionality and UI implementation ✅
- **Phase 2**: Enhanced episode management and streaming ✅
- **Phase 3**: Advanced search and filtering ✅
- **Phase 4**: User collections and watch history ✅
- **Phase 5**: Web platform support and responsive design ✅
- **Phase 6**: Onboarding experience and user guidance ✅
- **Phase 7**: Privacy policy and data management ✅
- **Phase 8**: Update management and notification system ✅
- **Phase 9**: Data backup and restore functionality ✅
- **Phase 10**: Professional splash screen implementation ✅
- **Phase 11**: Critical bug fixes and video player optimization ✅
- **Phase 12**: Custom video player with seek & skip intro/outro ✅
- **Phase 13**: Native notification system & playback controls ✅
- **Phase 14**: Background download service (native Android) ✅
- **Phase 15**: UI revamp with glassmorphism & gradient design ✅
- **Phase 16**: Performance optimizations and caching 🔄
- **Phase 17**: Social features and sharing 🔄
- **Phase 18**: Cloud synchronization options 🔄
- **Phase 19**: Manga reading support 🔄

## 🔒 Enhanced Privacy & Data Management

### Comprehensive Local Storage
- **Complete Data Control**: All user data remains on device with backup options
- **Export/Import**: Full data backup and restore capabilities
- **Data Validation**: Comprehensive validation during import/export operations
- **Privacy Compliance**: Updated privacy policy with detailed data handling

### Advanced Data Categories
- **User Preferences**: Theme, profile, onboarding status, update preferences
- **Anime Data**: Favorites, collections, watch history with detailed tracking
- **App State**: Last viewed episodes, search history, update history
- **Cache Data**: Images, API responses (temporary, automatically managed)
- **Backup Data**: User-controlled export/import with metadata

### Update Privacy
- **Update Checking**: Anonymous GitHub API calls for version checking
- **Download Management**: Local file handling with secure installation
- **Notification Control**: User-controlled notification preferences
- **Data Security**: No personal data transmitted during updates

## 📱 Enhanced Platform Support

### Android
- **Minimum SDK**: 21 (Android 5.0)
- **Target SDK**: Latest stable (34)
- **Adaptive Icons**: Professional splash screens with proper scaling
- **Material Design 3**: Enhanced components with update management
- **Android 12+ Support**: Modern Splash Screen API integration
- **FileProvider**: Secure APK installation across all Android versions
- **Notification Channels**: Advanced notification management

### iOS [To-Do]
- **Minimum iOS**: 12.0
- **Cupertino Design**: iOS-specific UI patterns
- **App Store Guidelines**: Compliance with Apple's guidelines
- **iOS Notifications**: Native notification integration

### Web [To-Do]
- **Progressive Web App**: Enhanced web capabilities
- **Responsive Design**: Optimized for desktop and mobile browsers
- **Web Notifications**: Browser notification support
- **File System Access**: Web-based backup/restore functionality

## 🔧 Advanced Configuration

### Update Management
```yaml
# No configuration required - automatic GitHub integration
# Customizable in core/constants/app_details.dart
```

### Notification Settings
```dart
// Automatic initialization with user permission handling
// Customizable notification channels and behaviors
```

### Video Player Configuration (v1.0.1)
```dart
// Enhanced video player with proper state management
// Section-aware caching to prevent cross-contamination
// Automatic cleanup and disposal
```

### Backup Configuration
```dart
// Automatic backup structure generation
// User-controlled export/import with validation
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Follow the established architecture patterns
4. Add tests for new functionality
5. Update documentation as needed
6. Commit changes (`git commit -m 'Add amazing feature'`)
7. Push to branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

### Enhanced Development Guidelines

- Follow enhanced MVVM architecture with update management
- Use Riverpod for all state management
- Implement comprehensive error handling with user feedback
- Add detailed documentation for new features
- Follow Dart style guidelines and best practices
- Consider privacy implications for new features
- Test across different Android versions and screen sizes
- Validate video player state management for new streaming features

### Code Quality Standards
- **Architecture Consistency**: Follow established patterns
- **Error Handling**: Comprehensive error management with user feedback
- **Performance**: Optimize for smooth user experience
- **Privacy**: Ensure all data handling follows privacy guidelines
- **Testing**: Adequate test coverage for new features
- **Documentation**: Clear documentation for complex features
- **Memory Management**: Proper disposal and cleanup (critical for video features)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Developer

<img src="https://avatars.githubusercontent.com/u/89354282?s=400&u=b168bc48d28bb7cc08e96730cd00691b4b1182ef&v=4" width="150" style="border-radius: 12%; object-fit: cover;">

**thetwodigiter**

- GitHub: [iamthetwodigiter](https://github.com/iamthetwodigiter)
- Repository: [ShinobiHaven](https://github.com/iamthetwodigiter/ShinobiHaven)

## 📞 Support & Community

For support, feature requests, or bug reports:
- **GitHub Issues**: Open an issue for bugs or feature requests
- **Discussions**: Use GitHub Discussions for general questions
- **Developer Contact**: Contact through GitHub profile
- **Privacy Queries**: Review the comprehensive privacy policy
- **Update Issues**: Check the update management documentation

### Getting Help
- **Documentation**: Comprehensive README and code documentation
- **Issue Templates**: Use provided templates for bug reports and features
- **Community Guidelines**: Follow established community standards
- **Privacy Support**: Dedicated privacy policy for data-related queries

## 🙏 Acknowledgments

- **Flutter Team**: For the amazing cross-platform framework
- **Riverpod**: For excellent state management capabilities
- **Hive**: For efficient local storage solutions
- **Community Packages**: All the amazing open-source packages used
- **Users**: For feedback and bug reports that helped improve the app

### Special Thanks
- **Android Community**: For FileProvider and notification best practices
- **GitHub**: For API access and hosting platform
- **Open Source Community**: For inspiration
- **Beta Testers**: For identifying critical video player issues fixed in v1.0.1

---

**Developed with ❤️ using Flutter | Professional, Privacy-Focused, Feature-Rich**

### Recent Updates Summary
- ✅ **v1.2.0**: Full UI revamp — glassmorphism, gradients, and consistent theming
- ✅ **v1.2.0**: Native Android notifications with playback controls and onTap navigation
- ✅ **v1.2.0**: Native background download service with real-time progress notifications
- ✅ **v1.1.2**: Custom video player with seek, skip intro/outro, and playback resumption
- ✅ **v1.1.1**: Linux platform support and desktop UI adaptations
- ✅ **v1.1.0**: Episode download support with progress tracking
- ✅ **v1.0.2**: Dynamic accent color system and background update checker
- ✅ **v1.0.1**: Critical video player fixes and enhanced state management
- ✅ **v1.0.0**: Complete Update Management, Backup/Restore, and Splash Screen