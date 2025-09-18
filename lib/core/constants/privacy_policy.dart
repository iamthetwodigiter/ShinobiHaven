class PrivacyPolicy {
  static const String privacyPolicy = """
# **Privacy Policy — ShinobiHaven**

Last updated: _September 19, 2025_

## **1. Overview**  
ShinobiHaven is a client app that helps you discover and stream anime episodes. This policy explains what data the app collects, where it is stored, how it is used, and how you can control or delete it. The app itself does not host media files — it links to third‑party streaming hosts.

## **2. What we do NOT store on our servers**
- ShinobiHaven does not upload or store media files. As stated in the onboarding/about screens, “ShinobiHaven does not store any files on our server, we only linked to the media which is hosted on 3rd party services.” See the onboarding / about text in onboarding_page.dart and the About dialog invoked in profile_page.dart.

## **3. Local data stored on device (Hive boxes)**
The app stores user data locally using Hive. Data is stored only on the user’s device unless you implement remote sync:

- Account & preferences:
  - Username, chosen profile image, and theme choice are stored via `UserBoxFunctions` — see user_box_functions.dart and methods such as `UserBoxFunctions.setUserName`.
- Library, favorites, history:
  - Library, favorites, watched history and collections are stored in the `library` Hive box and related helpers in library_box_functions.dart. Collections are stored as a map of collectionName → list of anime slugs; the helper returns full Anime objects for UI via `getAnimesInCollectionAsObjects`.
- Playback metadata:
  - The app reads sources and uses `better_player_plus` for playback in sources_page.dart and anime_details_page.dart. The app may cache images using `cached_network_image` (image cache is local to the device).

## **4. Why we store this data**
- Provide a personalized experience: username/profile, watch progress, favorites, and custom collections.
- Improve UX locally: caching images and keeping recently watched lists for quick access.

## **5. What we share with third parties**
- We do not share user data with third parties by default.
- When you stream a video the app connects to third‑party hosts (the app only links to external hosts). We are not responsible for the privacy practices of those hosts. Links to and playback from these hosts happen at the user’s end via network requests initiated by the player (`better_player_plus`) and cached image loader (`cached_network_image`).

## **6. Analytics and tracking**
- The current codebase contains no analytics or telemetry libraries. No automated analytics data is sent to third parties by default. (If you later add analytics — e.g., Firebase, Sentry — disclose it here and provide opt‑out.)

## **7. Cookies and local storage**
- The app uses device local storage (Hive). There are no web cookies involved in the native app.

## **8. Deleting / clearing data**
- Local data stays on device until the user deletes it or uninstalls the app.
- Clear data options:
  - If you provide a UI action such as “Clear Cache” or “Clear Library”, use the helper methods in library_box_functions.dart to remove keys like `library_list`, `collections`, or per‑slug entries.
  - Uninstalling the app removes the local data.
  - You can implement an explicit “Delete my data” feature that deletes the Hive boxes (delete keys / clear boxes).

## **9. Security**
- Data is stored locally in Hive. By default Hive data is not encrypted. If you require encryption at rest, integrate Hive’s encryption feature or platform encryption and document it here.
- Network requests go over standard HTTP(S) depending on third‑party host URLs. We recommend HTTPS endpoints; ShinobiHaven does not control third‑party host TLS settings.

## **10. Children**
- The app is not specifically targeted at children. If you plan to support minors you should implement parental controls and include COPPA/GDPR‑K compliance as applicable.

## **11. Third‑party libraries and licenses**
- The app uses third‑party packages such as:
  - better_player_plus for playback (sources_page.dart)
  - cached_network_image for image caching (anime_card.dart, details pages)
  - Hive for local storage (main.dart initializes boxes)
  - flutter_riverpod for state management (various files)
  - shimmer, carousel_slider, etc.  
  These packages may have their own privacy or telemetry behaviors — review their docs before adding analytics or remote features.

## **12. Changes to this policy**
- This policy may be updated. When the app updates, update the “Last updated” date and communicate material changes in‑app or in release notes.

## **13. Contact & requests**
- For questions, feature requests, data deletion requests, or security concerns, provide an email/URL in your release. (Add contact details here.)

## **14. Legal disclaimer**
- ShinobiHaven links to content hosted by third parties. We do not verify or control the legality or availability of that content. Users access third‑party content at their own risk. See the About/Onboarding text at onboarding_page.dart and the About dialog in profile_page.dart.

## **15. Developer notes for implementation (for your team)**
- Make sure any UI that modifies Hive boxes uses the helpers in:
  - library_box_functions.dart (collections, library, watched)
  - user_box_functions.dart (username/profile, theme)
- Keep the UI reactive: use `Hive.box('library').listenable()` where appropriate (e.g., `lib/features/anime/discovery/view/pages/library_page.dart`) or propagate active tab state from the parent to force reloads.
- If you add remote sync, analytics, or server components, update the policy to list what is sent, where it is stored, and how long it is retained.
""";
}