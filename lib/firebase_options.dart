//firebase의 초기화해주는 코드들


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
    apiKey: 'AIzaSyATpbs7JuCku2ZTm9a7Vi5Xu1a92A-yvvY',
    appId: '1:1003576425334:web:3f089775e322541c9fd857',
    messagingSenderId: '1003576425334',
    projectId: 'zero-kcal-life',
    authDomain: 'zero-kcal-life.firebaseapp.com',
    storageBucket: 'zero-kcal-life.firebasestorage.app',
    measurementId: 'G-HB2RRWPEGQ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAa3ATdFHUH3Xbo4CU76t6rhi2Dvan1u6I',
    appId: '1:1003576425334:android:7c8ee750e4b2378f9fd857',
    messagingSenderId: '1003576425334',
    projectId: 'zero-kcal-life',
    storageBucket: 'zero-kcal-life.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC4se-ublK1A6EpStgmFuPUxPqcvKSjrCA',
    appId: '1:1003576425334:ios:c8d2fb6ef00c87ad9fd857',
    messagingSenderId: '1003576425334',
    projectId: 'zero-kcal-life',
    storageBucket: 'zero-kcal-life.firebasestorage.app',
    iosBundleId: 'com.example.zeroKcalLife',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC4se-ublK1A6EpStgmFuPUxPqcvKSjrCA',
    appId: '1:1003576425334:ios:c8d2fb6ef00c87ad9fd857',
    messagingSenderId: '1003576425334',
    projectId: 'zero-kcal-life',
    storageBucket: 'zero-kcal-life.firebasestorage.app',
    iosBundleId: 'com.example.zeroKcalLife',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyATpbs7JuCku2ZTm9a7Vi5Xu1a92A-yvvY',
    appId: '1:1003576425334:web:ad3822aa9429b4869fd857',
    messagingSenderId: '1003576425334',
    projectId: 'zero-kcal-life',
    authDomain: 'zero-kcal-life.firebaseapp.com',
    storageBucket: 'zero-kcal-life.firebasestorage.app',
    measurementId: 'G-Z3LJGL6FNG',
  );
}
