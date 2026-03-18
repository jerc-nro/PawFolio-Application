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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCEa4mO_llyz9p1ZHPLF4MX6eUe9qjWJvA',
    appId: '1:222104651750:web:d916e5729ccaf0ed1b3827',
    messagingSenderId: '222104651750',
    projectId: 'pawfolio-firebase',
    authDomain: 'pawfolio-firebase.firebaseapp.com',
    storageBucket: 'pawfolio-firebase.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCvd4PlIcYpz4Y4NH5QYkpDCHY0_nlyFqQ',
    appId: '1:222104651750:android:4352a8ae3b466d7c1b3827',
    messagingSenderId: '222104651750',
    projectId: 'pawfolio-firebase',
    storageBucket: 'pawfolio-firebase.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCoxhpi-I2VF-GhgWw0Ws5YduOMQx0LtpI',
    appId: '1:222104651750:ios:b3ee5383810b08ee1b3827',
    messagingSenderId: '222104651750',
    projectId: 'pawfolio-firebase',
    storageBucket: 'pawfolio-firebase.firebasestorage.app',
    iosBundleId: 'com.example.pawfolio',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCoxhpi-I2VF-GhgWw0Ws5YduOMQx0LtpI',
    appId: '1:222104651750:ios:b3ee5383810b08ee1b3827',
    messagingSenderId: '222104651750',
    projectId: 'pawfolio-firebase',
    storageBucket: 'pawfolio-firebase.firebasestorage.app',
    iosBundleId: 'com.example.pawfolio',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCEa4mO_llyz9p1ZHPLF4MX6eUe9qjWJvA',
    appId: '1:222104651750:web:6b852405f8e8b15f1b3827',
    messagingSenderId: '222104651750',
    projectId: 'pawfolio-firebase',
    authDomain: 'pawfolio-firebase.firebaseapp.com',
    storageBucket: 'pawfolio-firebase.firebasestorage.app',
  );
}
