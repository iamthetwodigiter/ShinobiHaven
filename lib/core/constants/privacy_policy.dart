class PrivacyPolicy {
  static const String privacyPolicy = """
# **Privacy Policy — ShinobiHaven**

Last updated: _September 19, 2025_

## **1. Overview**  
ShinobiHaven is a client app that helps you discover and stream anime episodes. This policy explains what data the app collects, where it is stored, how it is used, and how you can control or delete it.
## ```THE APP ITSELF DOES NOT HOST MEDIA FILES — IT LINKS TO THIRS-PARTY STREAMING HOSTS.```

## **2. What we do NOT store on our servers**
- ShinobiHaven does not upload or store media files. As stated in the onboarding/about screens, “ShinobiHaven does not store any files on our server, we only linked to the media which is hosted on 3rd party services.” For reference the onboarding / about text in onboarding_page.dart.

## **3. Local data stored on device (Hive boxes)**
The app stores user data locally using Hive. Data is stored only on the user’s device:

- Account & preferences:
  - Username, chosen profile image, and theme choice are stored via `UserBoxFunctions` — see user_box_functions.dart and methods such as `UserBoxFunctions.setUserName`.
- Library, favorites, history:
  - Library, favorites, watched history and collections are stored in the `library` Hive box and related helpers in library_box_functions.dart.
- Playback metadata:
  - The app reads sources and uses `better_player_plus` for playback in sources_page.dart and anime_details_page.dart. The app may cache images using `cached_network_image` (image cache is local to the device).

## **4. Why we store this data**
- Provide a personalized experience: username/profile, watch progress, favorites, and custom collections.
- Improve UX locally: caching images and keeping recently watched lists for quick access.

## **5. What we share with third parties**
- We do not share user data with third parties by default.
- When you stream a video the app connects to third‑party hosts (the app only links to external hosts). We are not responsible for the privacy practices of those hosts. Links to and playback from these hosts happen at the user’s end via network requests initiated by the player (`better_player_plus`) and cached image loader (`cached_network_image`).

## **6. Analytics and tracking**
- The current codebase contains no analytics or telemetry libraries. No automated analytics data is sent to third parties by default.

## **7. Cookies and local storage**
- The app uses device local storage (Hive). There are no web cookies involved in the native app.

## **8. Deleting / clearing data**
- Local data stays on device until the user deletes it or uninstalls the app.
- Clear data options:
  - “Clear Data" or “Clear Library”, use the helper methods in library_box_functions.dart to remove user data like library entries and watch history.
  - Uninstalling the app removes the local data.

## **9. Security**
- Data is stored locally in Hive. By default Hive data is not encrypted. But that doesn't compromise with the user data since the entire data is and will be stored locally.
- No data related to the user device or accounts is stored or accessed. The app only accesses the data folder in the root for storing the Hive data[by default accessed by Hive], which the user does not have access to without rooting device so storing user private data and leaking it to the app is out of question.

## **10. Children**
- The contents accessible from the app may not be suitable for children. Users discrepancy advised.

## **11. Changes to this policy**
- This policy may be updated. When the app updates, update the “Last updated” date and communicate material changes in‑app or in release notes.

## **13. Contact & requests**
- For questions, feature requests, or security concerns, contact me on itsmeprabhatjana@gmail.com.

## **14. Legal disclaimer**
- ShinobiHaven links to content hosted by third parties. We do not verify or control the legality or availability of that content. Users access third‑party content at their own risk. See the About/Onboarding text at onboarding_page.dart.

---

**USING THE APP IS COMPLETELY SAFE. IF AT ANY POINT YOU HAVE CONCERNS REGARDING YOUR DATA SECURITY OR ABSTRACTION, FEEL FREE TO CHECK OUT THE CODE ON MY GITHUB.**

### With Love,
### From ShinobiHaven Dev,
### thetwodigiter
### GitHub: https://github.com/iamthetwodigiter
---
""";
}