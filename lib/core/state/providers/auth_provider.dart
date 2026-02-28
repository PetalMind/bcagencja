import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../auth/app_user.dart';
import '../../auth/auth_service.dart';
import '../../services/submission_document_service.dart';
import '../../services/vdr_document_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final vdrDocumentServiceProvider = Provider<VdrDocumentService>((ref) => VdrDocumentService());

final submissionDocumentServiceProvider =
    Provider<SubmissionDocumentService>((ref) => SubmissionDocumentService());

/// Komunikat wyświetlany po wylogowaniu z powodu zablokowania konta.
final blockedMessageProvider = StateProvider<String?>((ref) => null);

/// Aktualny użytkownik aplikacji (null = niezalogowany).
/// Łączy Firebase Auth z profilem z Firestore (rola, Level 2/3).
/// Gdy dokument użytkownika nie istnieje (konto usunięte), wylogowuje i zwraca null.
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final auth = ref.watch(authServiceProvider);
  return auth.authStateChanges.asyncExpand((User? fbUser) async* {
    if (fbUser == null) {
      yield null;
      return;
    }
    final appUser = await auth.getAppUser(fbUser.uid, fbUser);
    if (appUser != null) {
      yield appUser.copyWith(
        email: appUser.email ?? fbUser.email,
        displayName: appUser.displayName ?? fbUser.displayName,
        photoUrl: appUser.photoUrl ?? fbUser.photoURL,
      );
    } else {
      await auth.signOut();
      yield null;
      return;
    }
  });
});

/// Skrót: czy użytkownik jest zalogowany.
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider).asData?.value != null;
});

/// Skrót: czy użytkownik ma dostęp do panelu agenta/dyrektora.
final hasPartnerDashboardProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider).asData?.value;
  return user?.hasPartnerDashboard ?? false;
});
