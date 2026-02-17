import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Native (iOS/Android) Google Sign-In. Not used on web (redirect flow).
Future<UserCredential?> signInWithGoogleNative(FirebaseAuth auth) async {
  final googleUser = await GoogleSignIn().signIn();
  if (googleUser == null) {
    throw FirebaseAuthException(
      code: 'sign_in_canceled',
      message: 'Logowanie przez Google zostało anulowane',
    );
  }
  final googleAuth = await googleUser.authentication;
  final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );
  return auth.signInWithCredential(credential);
}
