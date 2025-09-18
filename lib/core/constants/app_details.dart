class AppDetails {
  static const String version = "v1.0.0";
  static const String developer = "thetwodigiter";
  static const bool isBeta = false;
  static const String repoURL =
      "https://github.com/iamthetwodigiter/ShinobiHaven";
  static const List<Map<String, dynamic>> changelogs = [
    {
      "v1.0.0": {
        "title": "Initial Release",
        "date": "2025-09-19",
        "notes": [
          "Discovery / browse and detailed anime pages with sorting and filtering.",
          "Subbed and Dubbed Episodes streaming with multiple formats support.",
          "Local library: favorites, collections (custom lists) and watched history (per-episode counts).",
          "Favorites UI with remove/undo and user-friendly layout.",
          "Collection Details page with card-based UI and remove/delete options.",
          "Watch History and \"Top Animes\" view (top 10 most-watched).",
          "Onboarding with user profile, theme choices and explicit consent/disclaimer.",
          "Privacy Policy bundled in-app.",
        ],
      },
      "unreleased": {
        "title": "Planned / TODO",
        "notes": [
          "Manga Support [API done, fixing and integration WIP].",
          "Download support for offline viewing",
          "Release build for the app. Current build is debug version but that doesn't affect the user experience."
          "Optional cloud sync / backup for library and favorites.",
          "Per-anime notes, ratings, and improved sorting/filtering.",
        ],
      },
    },
  ];
}
