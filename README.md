# ShinobiHaven - Anime Streaming Mobile App

A feature-rich Flutter application for anime discovery and streaming, built with feature based MVVM pattern, and modern development practices for a scalable, maintainable cross-platform solution.

![Flutter](https://img.shields.io/badge/Flutter-3.32.8-blue)
![Dart](https://img.shields.io/badge/Dart-3.8.1-blue)
![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS%20%7C%20Web-orange)
![License](https://img.shields.io/badge/License-MIT-green)
![Version](https://img.shields.io/badge/Version-v1.0.0-brightgreen)
![Downloads](https://img.shields.io/github/downloads/iamthetwodigiter/shinobihaven/total?label=Downloads&logo=GitHub)

## 📱 Overview

ShinobiHaven is a comprehensive anime streaming application that provides users with a seamless experience for discovering, streaming, and managing their anime content. The app follows feature based MVVM pattern, ensuring maintainable and scalable code.

### Key Highlights
- **Clean Architecture**: Feature-based MVVM architecture with clear separation of concerns
- **Modern State Management**: Riverpod for efficient state management and dependency injection
- **Local Storage**: Hive database for offline-first approach
- **Cross-Platform**: Flutter for Android, iOS[To-Do], Web[To-Do], Windows[To-Do], Linux[To-Do] platforms
- **Privacy-Focused**: Local data storage with no server-side user data collection

## 🏗️ Architecture

### MVVM Architecture Pattern

```
┌─────────────────────────┐
│      View Layer         │  ◄── UI Components, Pages, Widgets
├─────────────────────────┤
│    ViewModel Layer      │  ◄── State Management, Business Logic
├─────────────────────────┤
│      Model Layer        │  ◄── Data Models, Entities
├─────────────────────────┤
│   Repository Layer      │  ◄── Data Sources, API Integration
└─────────────────────────┘
```

### Project Structure

```
lib/
├── core/
│   ├── constants/           # App constants, privacy policy
│   ├── pages/              # Core pages (onboarding, splash)
│   ├── theme/              # App theming & styling
│   └── utils/              # Utility functions, Hive helpers
├── features/               # Feature-based modules
│   └── anime/
│       ├── common/         # Shared anime components
│       │   ├── model/      # Anime data models
│       │   └── view/       # Shared UI components, profile page
│       ├── details/        # Anime details feature
│       │   ├── dependency_injection/
│       │   ├── model/
│       │   ├── repository/
│       │   ├── view/
│       │   └── viewmodel/
│       ├── discovery/      # Search & browse feature
│       ├── episodes/       # Episode management
│       ├── home/           # Home dashboard
│       └── stream/         # Video streaming
└── main.dart              # Application entry point
```

Each feature follows the MVVM pattern:

```
feature/
├── dependency_injection/   # Riverpod providers
├── model/                  # Data models
├── repository/             # Data access layer
├── view/                   # UI components & pages
│   ├── pages/              # Feature screens
│   └── widgets/            # Feature-specific widgets
└── viewmodel/              # Business logic & state management
```

## 🔑 Key Features

### Core Functionality
- **Anime Discovery**: Browse trending, popular, and latest anime
- **Advanced Search**: Filter by genre, status, year, and more
- **Anime Details**: Comprehensive information with synopsis, characters, and ratings
- **Episode Streaming**: Multi-server support with quality options
- **Favorites Management**: Personal favorite anime collection
- **Watch History**: Track viewing progress and resume watching
- **Custom Collections**: Create and manage custom anime lists

### User Experience
- **Onboarding Flow**: Guided setup with user preferences
- **Profile Management**: Customizable user profiles with avatar selection
- **Theme Support**: Dark/Light mode with system preference detection
- **Responsive Design**: Optimized for mobile and web platforms
- **Offline Support**: Local data storage for offline access

### Privacy & Security
- **Local Storage**: All user data stored locally using Hive
- **No Server Storage**: No personal data uploaded to servers
- **Privacy Policy**: Comprehensive privacy policy with user consent
- **Transparent Disclaimer**: Clear information about third-party content sources

## 🛠️ Technical Implementation

### State Management & Dependency Injection

The application leverages **Riverpod** for efficient state management and dependency injection:

```dart
// Repository Provider
final animeDetailsRepositoryProvider = Provider((ref) => AnimeDetailsRepository());

// ViewModel Provider with Dependencies
final animeDetailsViewModelProvider = 
    StateNotifierProvider<AnimeDetailsViewmodel, AsyncValue<AnimeDetails>>((ref) {
  final repository = ref.watch(animeDetailsRepositoryProvider);
  return AnimeDetailsViewmodel(repository);
});

// Usage in UI
class AnimeDetailsPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animeDetails = ref.watch(animeDetailsViewModelProvider);
    return animeDetails.when(
      data: (data) => AnimeDetailsView(data),
      loading: () => LoadingWidget(),
      error: (error, stack) => ErrorWidget(error),
    );
  }
}
```

### Local Storage with Hive

Hive is used for efficient local data storage across multiple boxes:

#### Storage Structure
```dart
// User Preferences
'user' Box:
├── firstSetup: bool          # Onboarding completion status
├── installedVersion: String  # App version tracking
├── darkMode: int             # Theme preference (0: Light, 1: Dark, 2: System)
├── userName: String          # User display name
└── userProfile: String       # Selected avatar/profile

// Favorites Management
'favorites' Box:
├── anime_slug_1: Anime      # Favorite anime objects
├── anime_slug_2: Anime      # Keyed by anime slug for quick access
└── ...

// Library & Collections
'library' Box:
├── library_list: List<Anime>                                   # Main library anime list
├── collections: Map                                            # Custom collections
│   ├── collection_name_1: List<Anime>                          # Anime slugs in collection
│   └── collection_name_2: List<Anime>
├── watched: List                                               # Watch history
    └── anime_slug_episodes: Map<Anime,Map<String, int>>        # Per-anime episode watch status

// Watch History
'history' Box:
└── watch_history: List      # Chronological search history
```

#### Hive Helper Functions

```dart
// User Box Functions
class UserBoxFunctions {
  static bool isSetupDone() {
    return Hive.box('user').get('firstSetup', defaultValue: false);
  }
  
  static void markFirstSetup() {
    Hive.box('user').put('firstSetup', true);
  }
  
  static bool isDarkMode(BuildContext context) {
    final darkModeStatus = Hive.box('user').get('darkMode', defaultValue: 1);
    return darkModeStatus == 1 || 
           (darkModeStatus == 2 && Theme.brightnessOf(context) == Brightness.dark);
  }
}

// Library Box Functions
class LibraryBoxFunctions {
  static List<Anime> getLibraryAnimes() {
    return Hive.box('library').get('library_list', defaultValue: <Anime>[]);
  }
  
  static void addToLibrary(Anime anime) {
    final library = getLibraryAnimes();
    library.add(anime);
    Hive.box('library').put('library_list', library);
  }
}

// Favorites Box Functions
class FavoritesBoxFunctions {
  static List<Anime> listFavorites() {
    final favBox = Hive.box('favorites');
    return favBox.values.cast<Anime>().toList();
  }
  
  static void addToFavorites(Anime anime) {
    Hive.box('favorites').put(anime.slug, anime);
  }
  
  static bool isFavorite(String animeSlug) {
    return Hive.box('favorites').containsKey(animeSlug);
  }
}
```

### Data Flow Architecture

```
UI Layer (Pages/Widgets)
    ↓ (User Interaction)
ViewModel (StateNotifier)
    ↓ (Business Logic)
Repository (Data Access)
    ↓ (API Calls / Local Storage)
Data Sources (HTTP / Hive)
```

### Model Architecture

```dart
// Base Anime Model
@HiveType(typeId: 0)
class Anime extends HiveObject {
  @HiveField(0)
  final String slug;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final String image;
  
  @HiveField(3)
  final String? synopsis;
  
  // Constructor and methods...
}

// Feature-specific Models
class AnimeDetails extends Anime {
  final List<String> genres;
  final String status;
  final int? episodeCount;
  final double? rating;
  // Additional detail fields...
}
```

### Technical Stack

| Category | Technologies |
|----------|--------------|
| **Framework** | Flutter 3.32.8 |
| **Language** | Dart 3.8.1 |
| **Platforms** | Android, iOS [To-Do], Web[To-Do], Windows[To-Do], Linux[To-Do] |
| **State Management** | Riverpod |
| **Architecture** | Model-View-ViewModel [MVVM] |
| **Local Storage** | Hive |
| **Networking** | HTTP package |
| **Media** | Cached Network Image, Better Player Plus |
| **UI Enhancement** | Shimmer, Carousel Slider |
| **Onboarding** | Flutter Onboarding Slider |
| **Markdown** | Flutter Markdown Plus |
| **Notifications** | Toastification |
| **External Links** | URL Launcher |

## 🚀 Getting Started

### Prerequisites

- Flutter
- Dart
- Android Studio / VS Code with Flutter extensions
- Git for version control

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/iamthetwodigiter/ShinobiHaven.git
cd ShinobiHaven
```

2. **Install dependencies**
```bash
flutter pub get --no-example
```

3. **Generate Hive adapters**
```bash
dart run build_runner build
```

4. **Run the application**
```bash
# For Android/iOS
flutter run

# For Web
flutter run -d chrome
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

2. **Environment Configuration**
- No external API keys required for basic functionality
- Local storage handles all user data

## 📊 Project Roadmap

- **Phase 1**: Core functionality and UI implementation ✅
- **Phase 2**: Enhanced episode management and streaming ✅
- **Phase 3**: Advanced search and filtering ✅
- **Phase 4**: User collections and watch history ✅
- **Phase 5**: Web platform support and responsive design ✅
- **Phase 6**: Onboarding experience and user guidance ✅
- **Phase 7**: Privacy policy and data management ✅
- **Phase 8**: Performance optimizations and caching 🔄
- **Phase 9**: Social features and sharing 🔄
- **Phase 10**: Analytics and user insights 🔄

## 🔒 Privacy & Data Management

### Local Storage Only
- **No Server Storage**: All user data remains on device
- **Data Control**: Users have full control over their data
- **Easy Cleanup**: Uninstalling app removes all data

### Privacy Policy Compliance
- Comprehensive privacy policy included
- User consent for third-party content disclaimer
- Transparent data usage explanation

### Data Categories
- **User Preferences**: Theme, profile, onboarding status
- **Anime Data**: Favorites, collections, watch history
- **App State**: Last viewed episodes, search history
- **Cache Data**: Images, API responses (temporary)

## 📱 Platform Support

### Android
- Minimum SDK: 21 (Android 5.0)
- Target SDK: Latest stable
- Adaptive icons and splash screens
- Material Design 3 components

### iOS
- Minimum iOS: 12.0
- Cupertino design patterns
- iOS-specific navigation patterns
- Human Interface Guidelines compliance

### Web
- Progressive Web App features
- Responsive breakpoints
- Browser compatibility (Chrome, Firefox, Safari, Edge)
- Web-specific optimizations

### Windows
- Windows 10 version 1903 or higher (build 18362)
- UWP and Win32 deployment support
- Windows-specific UI patterns and navigation
- System integration (taskbar, notifications)
- File association and protocol handling

### Linux
- Ubuntu 18.04 LTS or higher
- Debian-based distributions support
- GTK-based native rendering
- Desktop integration (app launcher, file manager)
- Wayland and X11 display server compatibility

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Follow the established architecture patterns
4. Add tests for new functionality
5. Commit changes (`git commit -m 'Add amazing feature'`)
6. Push to branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Development Guidelines

- Follow MVVM architecture pattern
- Use Riverpod for state management
- Implement proper error handling
- Add comprehensive documentation
- Write unit and widget tests
- Follow Dart style guidelines

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Developer

**thetwodigiter**

- GitHub: [@iamthetwodigiter](https://github.com/iamthetwodigiter)
- Repository: [ShinobiHaven](https://github.com/iamthetwodigiter/ShinobiHaven)

## 📞 Support

For support, feature requests, or bug reports:
- Open an issue on GitHub
- Contact the developer through GitHub
- Review the privacy policy for data-related queries

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Riverpod for excellent state management
- Hive for efficient local storage
- Open source community for various packages used

---

**Developed with ❤️ using Flutter**