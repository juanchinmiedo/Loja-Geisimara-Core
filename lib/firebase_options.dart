// File modified for secure multi-client usage
// ignore_for_file: type=lint

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

import 'firebase_options_local.dart'; // 🔒 ignorado por git

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Usage:
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'FirebaseOptions have not been configured for Linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  /// WEB
  static FirebaseOptions get web => FirebaseOptions(
        apiKey: FirebaseLocal.webApiKey,
        appId: FirebaseLocal.webAppId,
        messagingSenderId: FirebaseLocal.messagingSenderId,
        projectId: FirebaseLocal.projectId,
        authDomain: FirebaseLocal.authDomain,
        storageBucket: FirebaseLocal.storageBucket,
        measurementId: FirebaseLocal.measurementId,
      );

  /// ANDROID
  static FirebaseOptions get android => FirebaseOptions(
        apiKey: FirebaseLocal.androidApiKey,
        appId: FirebaseLocal.androidAppId,
        messagingSenderId: FirebaseLocal.messagingSenderId,
        projectId: FirebaseLocal.projectId,
        storageBucket: FirebaseLocal.storageBucket,
      );

  /// iOS
  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: FirebaseLocal.iosApiKey,
        appId: FirebaseLocal.iosAppId,
        messagingSenderId: FirebaseLocal.messagingSenderId,
        projectId: FirebaseLocal.projectId,
        storageBucket: FirebaseLocal.storageBucket,
        iosBundleId: FirebaseLocal.iosBundleId,
      );

  /// macOS
  static FirebaseOptions get macos => FirebaseOptions(
        apiKey: FirebaseLocal.macosApiKey,
        appId: FirebaseLocal.macosAppId,
        messagingSenderId: FirebaseLocal.messagingSenderId,
        projectId: FirebaseLocal.projectId,
        storageBucket: FirebaseLocal.storageBucket,
        iosBundleId: FirebaseLocal.macosBundleId,
      );

  /// WINDOWS
  static FirebaseOptions get windows => FirebaseOptions(
        apiKey: FirebaseLocal.windowsApiKey,
        appId: FirebaseLocal.windowsAppId,
        messagingSenderId: FirebaseLocal.messagingSenderId,
        projectId: FirebaseLocal.projectId,
        authDomain: FirebaseLocal.windowsAuthDomain,
        storageBucket: FirebaseLocal.storageBucket,
        measurementId: FirebaseLocal.windowsMeasurementId,
      );
}
