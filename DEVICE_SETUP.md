# StudyCore — Run on a Real Device

Complete these steps once and the app will build and run on Android and iOS.

---

## Step 1 — Register your Android app in Firebase

1. Open [Firebase Console → studycore-d48d6 → Project Settings](https://console.firebase.google.com/project/studycore-d48d6/settings/general)
2. Scroll to **"Your apps"** and click **"Add app"** → choose the **Android** icon
3. Fill in the form:
   - **Android package name:** `com.studycore.workspace`
   - **App nickname:** StudyCore Android *(optional)*
   - **Debug signing certificate SHA-1:** run the command below and paste the result

```bash
# macOS / Linux
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey \
  -storepass android -keypass android 2>/dev/null | grep SHA1

# Windows
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" ^
  -alias androiddebugkey -storepass android -keypass android | findstr SHA1
```

4. Click **"Register app"**
5. Click **"Download google-services.json"**
6. **Replace** the placeholder file at `android/app/google-services.json` with the one you just downloaded

---

## Step 2 — Update firebase_options.dart with your real Android App ID

After downloading `google-services.json`, open it and copy the value of `"mobilesdk_app_id"`.
It looks like: `1:336263165579:android:xxxxxxxxxxxxxxxx`

Open `lib/firebase_options.dart` and replace:
```dart
appId: '1:336263165579:android:9fd38c58da014b8407468e',
```
with:
```dart
appId: '1:336263165579:android:YOUR_REAL_ANDROID_APP_ID',
```

---

## Step 3 — Enable Firebase Auth sign-in methods

1. Go to [Firebase Console → Authentication → Sign-in method](https://console.firebase.google.com/project/studycore-d48d6/authentication/providers)
2. Enable **Email/Password**
3. Enable **Google** (required for Google Sign-In button)
   - When enabling Google, copy the **Web client ID** — you'll need it for the Google Sign-In config

---

## Step 4 — Enable Firestore and Storage

1. Go to [Firestore Database](https://console.firebase.google.com/project/studycore-d48d6/firestore) → **Create database** → choose **Production mode** (rules are already written)
2. Go to [Storage](https://console.firebase.google.com/project/studycore-d48d6/storage) → **Get started** → **Production mode**

---

## Step 5 — Deploy security rules and indexes

```bash
npm install -g firebase-tools
firebase login
firebase use studycore-d48d6
firebase deploy --only firestore,storage
```

---

## Step 6 — Run on Android

```bash
flutter devices          # confirm your device is listed
flutter run              # builds and installs on connected device
flutter run --release    # production build
```

---

## Step 7 (optional) — iOS setup

1. In Firebase Console → **Add app** → **iOS**
   - **Bundle ID:** `com.studycore.workspace`
2. Download **GoogleService-Info.plist**
3. Replace `ios/Runner/GoogleService-Info.plist` with the downloaded file
4. Open `ios/Runner.xcworkspace` in Xcode
5. Set **Deployment Target** to 13.0
6. Update `lib/firebase_options.dart` iOS section with the real `GOOGLE_APP_ID` from the plist
7. Run: `flutter run -d <your-ios-device-id>`

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `SHA1 mismatch` / Google Sign-In fails | Re-run the keytool command and add the SHA-1 in Firebase Console → Project Settings → Your apps → Android |
| `google-services.json` not found | Make sure the file is at `android/app/google-services.json` (not in the project root) |
| `FirebaseException: permission-denied` | Deploy Firestore rules: `firebase deploy --only firestore` |
| `Missing index` error in logs | Deploy indexes: `firebase deploy --only firestore` |
| iOS build fails on GoogleService-Info.plist | Register the iOS app in Firebase and replace the placeholder plist |
| Gemini AI returns empty results | Check `GEMINI_API_KEY` is set in Replit Secrets and the key has Generative Language API enabled in [Google Cloud Console](https://console.cloud.google.com/apis/library/generativelanguage.googleapis.com) |
