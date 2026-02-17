// Plik konfiguracyjny Firebase.
// Aby wygenerować prawdziwe wartości, uruchom w katalogu projektu:
//   dart run flutterfire configure
// (wymaga zalogowania do Firebase CLI: firebase login)

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
  apiKey: "AIzaSyA4aawTo6rQSW5PbwaJPpmQ2w8qCE0izeo",
  authDomain: "bc-agencja.firebaseapp.com",
  projectId: "bc-agencja",
  storageBucket: "bc-agencja.firebasestorage.app",
  messagingSenderId: "1091574464476",
  appId: "1:1091574464476:web:10fb555fc6333294215919"
  );
}
