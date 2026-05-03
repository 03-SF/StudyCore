import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCswko5VW5nT9U6Vhq_5BsMfQ-e4iqRZZA',
    appId: '1:336263165579:web:9fd38c58da014b8407468e',
    messagingSenderId: '336263165579',
    projectId: 'studycore-d48d6',
    authDomain: 'studycore-d48d6.firebaseapp.com',
    storageBucket: 'studycore-d48d6.firebasestorage.app',
    measurementId: 'G-8DBGDF2G5E',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCswko5VW5nT9U6Vhq_5BsMfQ-e4iqRZZA',
    appId: '1:336263165579:android:9fd38c58da014b8407468e',
    messagingSenderId: '336263165579',
    projectId: 'studycore-d48d6',
    storageBucket: 'studycore-d48d6.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCswko5VW5nT9U6Vhq_5BsMfQ-e4iqRZZA',
    appId: '1:336263165579:ios:9fd38c58da014b8407468e',
    messagingSenderId: '336263165579',
    projectId: 'studycore-d48d6',
    storageBucket: 'studycore-d48d6.firebasestorage.app',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    iosBundleId: 'com.studycore.workspace',
  );
}
