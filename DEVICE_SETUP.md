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

## Step 2 — Enable Google Sign-In (REQUIRED to fix the sign-in error)

This step is mandatory — Google Sign-In will fail until it is completed.

1. Go to [Firebase Console → Authentication → Sign-in method](https://console.firebase.google.com/project/studycore-d48d6/authentication/providers)
2. Click **Google** → toggle **Enable** → click **Save**
3. **Re-download `google-services.json`** from Project Settings — it now includes the OAuth client credentials
4. Replace `android/app/google-services.json` with this newly downloaded file
5. **Add SHA-1 fingerprint** (if not done in Step 1):
   - Firebase Console → Project Settings → Your apps → Android app → **Add fingerprint**
   - Paste the SHA-1 from the `keytool` command above

> **Why does Google Sign-In fail without this?**  
> Firebase generates an OAuth web client only when Google Sign-In is enabled. Without it, `google-services.json` has an empty `oauth_client` array, and the Android SDK cannot authenticate users with Google.

---

## Step 3 — Enable Email/Password sign-in

1. Go to [Firebase Console → Authentication → Sign-in method](https://console.firebase.google.com/project/studycore-d48d6/authentication/providers)
2. Click **Email/Password** → toggle **Enable** → click **Save**

---

## Step 4 — Update firebase_options.dart (optional but recommended)

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

## Step 5 — Enable Firestore and Storage

1. Go to [Firestore Database](https://console.firebase.google.com/project/studycore-d48d6/firestore) → **Create database** → choose **Production mode** (rules are already written)
2. Go to [Storage](https://console.firebase.google.com/project/studycore-d48d6/storage) → **Get started** → **Production mode**

---

## Step 6 — Deploy security rules and indexes

```bash
npm install -g firebase-tools
firebase login
firebase use studycore-d48d6
firebase deploy --only firestore,storage
```

---

## Step 7 — Run on Android

```bash
flutter devices          # confirm your device is listed
flutter run              # builds and installs on connected device
flutter run --release    # production build
```

---

## Step 8 (optional) — iOS setup

1. In Firebase Console → **Add app** → **iOS**
   - **Bundle ID:** `com.studycore.workspace`
2. Enable **Google Sign-In** (same as Step 2 above — if already done, skip)
3. Download **GoogleService-Info.plist**
4. Replace `ios/Runner/GoogleService-Info.plist` with the downloaded file
5. Open `ios/Runner.xcworkspace` in Xcode
6. Set **Deployment Target** to 13.0
7. Update `lib/firebase_options.dart` iOS section with the real `GOOGLE_APP_ID` from the plist
8. Run: `flutter run -d <your-ios-device-id>`

---

## Troubleshooting

| Problem | Fix |
|---|---|
| **Google Sign-In fails** | Follow Step 2 exactly — enable Google in Firebase Auth, re-download `google-services.json`, and add your SHA-1 fingerprint |
| `SHA1 mismatch` error | Re-run the keytool command and update the SHA-1 in Firebase Console → Project Settings → Your apps → Android |
| `google-services.json` not found | Make sure the file is at `android/app/google-services.json` (not in the project root) |
| `FirebaseException: permission-denied` | Deploy Firestore rules: `firebase deploy --only firestore` |
| `Missing index` error in logs | Deploy indexes: `firebase deploy --only firestore` |
| iOS build fails on GoogleService-Info.plist | Register the iOS app in Firebase and replace the placeholder plist |
| Gemini AI returns empty results | Check `GEMINI_API_KEY` is set in Replit Secrets and the key has Generative Language API enabled in [Google Cloud Console](https://console.cloud.google.com/apis/library/generativelanguage.googleapis.com) |
| `oauth_client` array is empty in google-services.json | You downloaded the file before enabling Google Sign-In. Enable it in Firebase Auth, then re-download |
