# StudyCore — Flutter Mobile App

## Project Overview
A production-ready Flutter (Dart) mobile application for university students featuring:
- **Flashcard decks** with SM-2 spaced repetition algorithm
- **AI card generation** via Google Gemini API
- **Quiz mode** with timed multiple-choice questions
- **Progress tracking** with fl_chart charts
- **Group collaboration** with real-time Firestore chat
- **Firebase backend** (Auth, Firestore, Storage, Messaging)

Target platforms: **Android** (minSdk 21) and **iOS** (deployment target 13.0)

---

## Architecture

### Tech Stack
- **Framework**: Flutter 3.32 / Dart 3.8
- **State Management**: Provider (`ChangeNotifier`)
- **Navigation**: go_router 13
- **Backend**: Firebase (Auth, Firestore, Storage, Messaging)
- **AI**: google_generative_ai (Gemini)
- **Charts**: fl_chart
- **Fonts**: Google Fonts (DM Sans)

### Directory Structure
```
lib/
├── main.dart                  # Entry point — Firebase init, MultiProvider
├── app.dart                   # StudyCoreApp widget, GoRouter initialization
├── config/
│   ├── app_theme.dart         # ThemeData (light + dark)
│   ├── app_colors.dart        # AppColors constants
│   ├── constants.dart         # AppConstants (subjects, etc.)
│   └── router.dart            # appRoutes (List<RouteBase>), appNavigatorKey
├── models/
│   ├── user_model.dart
│   ├── deck_model.dart
│   ├── card_model.dart
│   ├── session_model.dart
│   ├── group_model.dart
│   └── message_model.dart
├── services/
│   ├── auth_service.dart
│   ├── deck_service.dart
│   ├── card_service.dart
│   ├── session_service.dart
│   ├── group_service.dart
│   ├── ai_service.dart
│   ├── storage_service.dart
│   ├── notification_service.dart
│   └── spaced_repetition_service.dart
├── providers/
│   ├── auth_provider.dart
│   ├── deck_provider.dart
│   ├── card_provider.dart
│   ├── session_provider.dart
│   ├── group_provider.dart
│   └── theme_notifier.dart
├── screens/
│   ├── auth/         splash, login, signup
│   ├── home/         home_screen
│   ├── deck/         detail, create/edit, add/edit card, ai_generate
│   ├── study/        flashcard_study, quiz, session_results
│   ├── progress/     progress_screen
│   ├── groups/       list, create, detail, chat
│   └── profile/      profile, settings
└── widgets/
    ├── common/       app_button, app_input, app_chip, empty_state, loading_overlay
    ├── deck/         deck_card
    ├── study/        flashcard_widget, rating_buttons, quiz_option_tile
    └── groups/       message_bubble
```

---

## Key Configuration

### Firebase
- `lib/firebase_options.dart` is a **stub** — user must run `flutterfire configure` to populate real keys.
- Firestore offline persistence is enabled at startup.

### Environment Variables
- `.env` file at project root: `GEMINI_API_KEY=your_key_here`
- Loaded via `flutter_dotenv` in `main.dart`

### Router Pattern
- `appRoutes` (`List<RouteBase>`) and `appNavigatorKey` exported from `lib/config/router.dart`
- GoRouter created in `_StudyCoreAppState.didChangeDependencies` (initialized once with `_routerInitialized` flag)
- Auth redirect logic lives in `app.dart`

### AuthProvider Public API
- `sendPasswordResetEmail(String email)`
- `deleteAccount()`
- `changePassword(String newPassword)`
- `signInWithGoogle()`
- `signOut()`

---

## Dependencies (key packages)
| Package | Version | Purpose |
|---|---|---|
| firebase_core | ^2.32.0 | Firebase init |
| firebase_auth | ^4.16.0 | Authentication |
| cloud_firestore | ^4.17.5 | Database |
| firebase_storage | ^11.6.5 | File uploads |
| firebase_messaging | ^14.7.10 | Push notifications |
| google_generative_ai | ^0.4.7 | Gemini AI |
| go_router | ^13.2.5 | Navigation |
| provider | ^6.1.5 | State management |
| fl_chart | ^0.67.0 | Charts |
| google_fonts | ^6.3.2 | Typography |
| google_sign_in | ^6.2.0 | Google OAuth |
| flutter_dotenv | ^5.2.1 | Env vars |
| flutter_local_notifications | ^16.3.3 | Local notifications |
| image_picker | ^1.2.1 | Photo upload |
| cached_network_image | ^3.4.1 | Image caching |
| shared_preferences | ^2.5.3 | Local prefs |

---

## Setup Instructions (for production)

1. **Firebase**: Run `flutterfire configure` and replace `lib/firebase_options.dart`
2. **Gemini API**: Set `GEMINI_API_KEY` in `.env`
3. **Android minSdk**: Already set to 21 in `android/app/build.gradle.kts`
4. **iOS**: Set deployment target to 13.0 in Xcode
5. **Run**: `flutter pub get && flutter run`

## Analyze Status
- Zero errors, zero warnings
- ~39 `info`-level hints (deprecated `withOpacity`, `prefer_const_constructors`, `use_build_context_synchronously`)
