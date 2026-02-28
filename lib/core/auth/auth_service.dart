import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'sign_in_google_native.dart'
    if (dart.library.html) 'sign_in_google_stub.dart' as sign_in_google;

import 'app_user.dart';
import 'linkedin_auth.dart';

void _authLog(String message, [Object? detail]) {
  // Logi wyłączone – odkomentuj poniżej, aby włączyć w debug:
  // if (kDebugMode) {
  //   // ignore: avoid_print
  //   print('[Auth] $message${detail != null ? ' $detail' : ''}');
  // }
}

/// Serwis autentykacji: Firebase Auth + profil użytkownika z Firestore.
class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? get currentFirebaseUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Odczyt profilu użytkownika z Firestore (role, accessLevel, VDR, NDA).
  /// Jeśli [user] podany i email zweryfikowany, a profil ma NDA i teaser – ustawia identityVerified.
  Future<AppUser?> getAppUser(String uid, [User? user]) async {
    _authLog('getAppUser start', 'uid=$uid');
    final ref = _firestore.collection('users').doc(uid);
    final doc = await ref.get();
    if (!doc.exists) {
      _authLog('getAppUser: doc nie istnieje', uid);
      return null;
    }
    final data = doc.data()!;
    final accessStr = data['accessLevel'] as String? ?? 'teaser';
    final ndaAcceptedAt = data['ndaAcceptedAt'];
    if (user != null &&
        user.emailVerified &&
        accessStr == 'teaser' &&
        ndaAcceptedAt != null) {
      await ref.update({
        'accessLevel': 'identityVerified',
        'emailVerified': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _authLog('getAppUser: zaktualizowano identityVerified', uid);
      return _appUserFromDoc(uid, {...data, 'accessLevel': 'identityVerified', 'emailVerified': true});
    }
    _authLog('getAppUser ok', 'uid=$uid accessLevel=${data['accessLevel']}');
    return _appUserFromDoc(uid, data);
  }

  AppUser _appUserFromDoc(String uid, Map<String, dynamic> data) {
    final roleStr = data['role'] as String? ?? 'lead';
    final accessStr = data['accessLevel'] as String? ?? 'teaser';
    final vdrList = data['vdrAccessForListingIds'];
    final accountTypeStr = data['accountType'] as String?;
    final preferredList = data['preferredInvestmentTypes'];
    return AppUser(
      id: uid,
      email: data['email'] as String?,
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      role: _roleFromString(roleStr),
      accessLevel: _accessLevelFromString(accessStr),
      ndaAcceptedAt: (data['ndaAcceptedAt'] as Timestamp?)?.toDate(),
      vdrAccessForListingIds: vdrList is List
          ? List<String>.from(vdrList.map((e) => e.toString()))
          : const [],
      regionVoivodeship: data['regionVoivodeship'] as String?,
      directorId: data['directorId'] as String?,
      accountType: accountTypeStr == 'company' ? AccountType.company : (accountTypeStr == 'person' ? AccountType.person : null),
      nip: data['nip'] as String?,
      companyName: data['companyName'] as String?,
      companyAddress: data['companyAddress'] as String?,
      phone: data['phone'] as String?,
      preferredInvestmentTypes: preferredList is List
          ? List<String>.from(preferredList.map((e) => e.toString()))
          : const [],
      budgetMin: data['budgetMin'] as int?,
      budgetMax: data['budgetMax'] as int?,
      emailVerified: data['emailVerified'] as bool? ?? false,
      linkedInProfileUrl: data['linkedInProfileUrl'] as String?,
      isBlocked: data['blocked'] as bool? ?? false,
    );
  }

  UserRole _roleFromString(String s) {
    switch (s) {
      case 'admin':
        return UserRole.admin;
      case 'director':
        return UserRole.director;
      case 'agent':
        return UserRole.agent;
      case 'lead':
        return UserRole.lead;
      default:
        return UserRole.lead;
    }
  }

  AccessLevel _accessLevelFromString(String s) {
    switch (s) {
      case 'vdr':
        return AccessLevel.vdr;
      case 'identityVerified':
        return AccessLevel.identityVerified;
      default:
        return AccessLevel.teaser;
    }
  }

  Future<void> signOut() => _auth.signOut();

  /// Ustawia persystencję sesji (tylko web).
  Future<void> setPersistence(Persistence persistence) async {
    await _auth.setPersistence(persistence);
  }

  /// Obsługa wyniku signInWithRedirect po powrocie na stronę (tylko web).
  /// Wywołać przy starcie aplikacji (main) – np. AuthService().handleWebRedirectResult().
  Future<UserCredential?> handleWebRedirectResult() async {
    if (!kIsWeb) return null;
    final userCred = await _auth.getRedirectResult();
    if (userCred.user != null) {
      await _ensureUserProfile(userCred.user!);
    }
    return userCred;
  }

  /// Logowanie przez Google.
  /// Na web: najpierw signInWithPopup (wynik od razu w tej samej stronie, pewne przekierowanie po logowaniu).
  /// Gdy popup jest zablokowany – fallback na signInWithRedirect (wynik w getRedirectResult przy powrocie).
  Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {
      final googleProvider = GoogleAuthProvider();
      try {
        final userCred = await _auth.signInWithPopup(googleProvider);
        if (userCred.user != null) {
          await _ensureUserProfile(userCred.user!);
        }
        return userCred;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'auth/popup-blocked' || e.code == 'auth/cancelled-popup-request') {
          await _auth.signInWithRedirect(googleProvider);
          return null; // redirect – wynik w getRedirectResult przy powrocie
        }
        rethrow;
      }
    }
    final userCred = await sign_in_google.signInWithGoogleNative(_auth);
    if (userCred != null) {
      await _ensureUserProfile(userCred.user!);
    }
    return userCred;
  }

  /// Logowanie przez LinkedIn (OpenID Connect).
  /// Działa tylko na web. Zwraca URL do przekierowania (caller powinien użyć url_launcher),
  /// żeby uniknąć blokady przeglądarki przy programowym location.href.
  /// [returnTo] – ścieżka do przekierowania po zalogowaniu (np. /dashboard).
  Future<String?> signInWithLinkedIn([String? returnTo]) async {
    if (!kIsWeb) return null;
    return buildLinkedInAuthUrl(returnTo);
  }

  /// Zalogowanie custom tokenem zwróconym przez Cloud Function po wymianie kodu LinkedIn.
  Future<UserCredential?> signInWithLinkedInCustomToken(String customToken) async {
    final userCred = await _auth.signInWithCustomToken(customToken);
    if (userCred.user != null) {
      await _ensureUserProfile(userCred.user!);
    }
    return userCred;
  }

  /// Logowanie przez Apple.
  /// Na web: najpierw signInWithPopup; przy zablokowanym popupie – signInWithRedirect.
  Future<UserCredential?> signInWithApple() async {
    if (kIsWeb) {
      final appleProvider = AppleAuthProvider();
      try {
        final userCred = await _auth.signInWithPopup(appleProvider);
        if (userCred.user != null) {
          await _ensureUserProfile(userCred.user!);
        }
        return userCred;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'auth/popup-blocked' || e.code == 'auth/cancelled-popup-request') {
          await _auth.signInWithRedirect(appleProvider);
          return null;
        }
        rethrow;
      }
    }
    final rawNonce = _generateNonce();
    final hashedNonce = _sha256(rawNonce);
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );
    final oAuthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );
    final userCred = await _auth.signInWithCredential(oAuthCredential);
    if (userCred.user != null) {
      await _ensureUserProfile(
        userCred.user!,
        displayName: appleCredential.givenName != null ||
                appleCredential.familyName != null
            ? '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim()
            : null,
      );
    }
    return userCred;
  }

  /// Logowanie e-mailem i hasłem.
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _authLog('signInWithEmailAndPassword start', 'email=$email');
    final userCred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    _authLog('signInWithEmailAndPassword OK', 'uid=${userCred.user?.uid}');
    if (userCred.user != null) {
      await _ensureUserProfile(userCred.user!);
    }
    return userCred;
  }

  /// Rejestracja e-mailem i hasłem.
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final userCred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (userCred.user != null) {
      await _ensureUserProfile(userCred.user!, displayName: displayName);
    }
    return userCred;
  }

  /// Reset hasła (wysłanie linku na email).
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Wysłanie linku weryfikacyjnego na email (rejestracja krok 1).
  /// [continueUrl] – pełny URL, na który użytkownik wróci po kliknięciu linku (np. origin + /rejestracja/email-link?email=...).
  Future<void> sendSignInLinkToEmail({
    required String email,
    required String continueUrl,
  }) async {
    final actionCodeSettings = ActionCodeSettings(
      url: continueUrl,
      handleCodeInApp: true,
    );
    await _auth.sendSignInLinkToEmail(
      email: email.trim(),
      actionCodeSettings: actionCodeSettings,
    );
  }

  /// Zalogowanie przez link z emaila (po kliknięciu linku weryfikacyjnego).
  Future<UserCredential> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async {
    final userCred = await _auth.signInWithEmailLink(
      email: email.trim(),
      emailLink: emailLink,
    );
    if (userCred.user != null) {
      await _ensureUserProfile(userCred.user!);
    }
    return userCred;
  }

  /// Ustawienie hasła i profilu dla użytkownika z rejestracji przez link (krok 2).
  Future<void> setPasswordAndProfile({
    required String displayName,
    required String password,
    String? postalCode,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Brak zalogowanego użytkownika');

    await user.updatePassword(password);

    final ref = _firestore.collection('users').doc(user.uid);
    final data = <String, dynamic>{
      'displayName': displayName.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (postalCode != null && postalCode.trim().isNotEmpty) {
      data['postalCode'] = postalCode.trim().replaceAll(RegExp(r'[^0-9\-]'), '');
    }
    await ref.set(data, SetOptions(merge: true));
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  /// Tworzy lub aktualizuje profil użytkownika w Firestore.
  Future<void> _ensureUserProfile(User user, {String? displayName}) async {
    final ref = _firestore.collection('users').doc(user.uid);
    final doc = await ref.get();
    final data = <String, dynamic>{
      'email': user.email ?? doc.data()?['email'],
      'displayName': displayName ?? user.displayName ?? doc.data()?['displayName'],
      'photoUrl': user.photoURL ?? doc.data()?['photoUrl'],
      'emailVerified': user.emailVerified,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (!doc.exists) {
      data['role'] = 'lead';
      data['accessLevel'] = 'teaser';
      data['createdAt'] = FieldValue.serverTimestamp();
    }
    await ref.set(data, SetOptions(merge: true));
  }

  /// Grant Level 2 (Identity Verified): zapis NDA + ustawienie accessLevel na identityVerified.
  /// Opcjonalnie zapis NIP, nazwy firmy, typu konta (po weryfikacji przez WL API lub OAuth).
  Future<void> acceptNdaAndGrantLevel2({
    String? nip,
    String? companyName,
    String? companyAddress,
    AccountType? accountType,
    String? phone,
    List<String>? preferredInvestmentTypes,
    int? budgetMin,
    int? budgetMax,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Brak zalogowanego użytkownika');

    final ref = _firestore.collection('users').doc(user.uid);
    final data = <String, dynamic>{
      'ndaAcceptedAt': FieldValue.serverTimestamp(),
      'accessLevel': 'identityVerified',
      'role': 'lead',
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (nip != null && nip.isNotEmpty) data['nip'] = nip.replaceAll(RegExp(r'[^0-9]'), '');
    if (companyName != null && companyName.isNotEmpty) data['companyName'] = companyName;
    if (companyAddress != null && companyAddress.isNotEmpty) data['companyAddress'] = companyAddress;
    if (accountType != null) data['accountType'] = accountType == AccountType.company ? 'company' : 'person';
    if (phone != null && phone.isNotEmpty) data['phone'] = phone;
    if (preferredInvestmentTypes != null && preferredInvestmentTypes.isNotEmpty) {
      data['preferredInvestmentTypes'] = preferredInvestmentTypes;
    }
    if (budgetMin != null) data['budgetMin'] = budgetMin;
    if (budgetMax != null) data['budgetMax'] = budgetMax;
    await ref.set(data, SetOptions(merge: true));
  }

  /// Dokończenie rejestracji po OAuth (osoba fizyczna vs firma, NDA, opcjonalne pola).
  Future<void> completeOAuthRegistration({
    required AccountType accountType,
    String? companyName,
    String? nip,
    required bool ndaAccepted,
    required bool ndaScrolledToEnd,
    String? phone,
    List<String>? preferredInvestmentTypes,
    int? budgetMin,
    int? budgetMax,
  }) async {
    _authLog('completeOAuthRegistration start', 'accountType=$accountType');
    final user = _auth.currentUser;
    if (user == null) {
      _authLog('completeOAuthRegistration: brak currentUser');
      throw StateError('Brak zalogowanego użytkownika');
    }
    if (!ndaAccepted) throw StateError('Wymagana akceptacja NDA');

    _authLog('completeOAuthRegistration: log NDA (w tle)');
    unawaited(
      logNdaAcceptance(
        userId: user.uid,
        ndaVersion: 'v1.0',
        scrolledToEnd: ndaScrolledToEnd,
      ).catchError((Object e) {
        _authLog('logNdaAcceptance błąd (nie blokuje)', e);
      }),
    );

    _authLog('completeOAuthRegistration: acceptNdaAndGrantLevel2');
    await acceptNdaAndGrantLevel2(
      accountType: accountType,
      companyName: accountType == AccountType.company ? companyName : null,
      nip: accountType == AccountType.company && nip != null && nip.isNotEmpty
          ? nip.replaceAll(RegExp(r'[^0-9]'), '')
          : null,
      phone: phone,
      preferredInvestmentTypes: preferredInvestmentTypes,
      budgetMin: budgetMin,
      budgetMax: budgetMax,
    );
    _authLog('completeOAuthRegistration zakończone OK', 'uid=${user.uid}');
  }

  /// Rejestracja firmowa przez NIP: tworzy konto email+hasło, zapisuje pełne dane firmy z rejestru WL, wysyła weryfikację email.
  /// Konto można założyć tylko po zweryfikowanym NIP i zaakceptowanym NDA.
  /// accessLevel pozostaje teaser do weryfikacji email.
  /// Kolejność: Auth → token → Firestore → email – tak żeby przy błędzie zapisu do Firestore nie wysyłać e-maila.
  Future<UserCredential> registerWithNip({
    required String email,
    required String password,
    required String displayName,
    String? position,
    required String phone,
    required String nip,
    required String companyName,
    required String companyAddress,
    required bool ndaAccepted,
    required bool ndaScrolledToEnd,
    String? companyRegon,
    String? companyStatusVat,
    String? companyResidenceAddress,
    String? companyWorkingAddress,
  }) async {
    _authLog('registerWithNip start', 'email=$email');
    if (!ndaAccepted) throw StateError('Wymagana akceptacja regulaminu i NDA');

    _authLog('registerWithNip: createUserWithEmailAndPassword');
    final userCred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = userCred.user!;
    _authLog('registerWithNip: konto utworzone', 'uid=${user.uid}');

    // Najpierw token, potem Firestore – dopiero na końcu e-mail. Dzięki temu przy błędzie zapisu użytkownik nie dostaje e-maila przy nieudanym „załóż konto”.
    await user.getIdToken(true);

    _authLog('registerWithNip: zapis profilu do Firestore');
    final ref = _firestore.collection('users').doc(user.uid);
    final nipClean = nip.replaceAll(RegExp(r'[^0-9]'), '');
    final profileData = {
      'email': user.email,
      'displayName': displayName.trim(),
      'phone': phone.trim(),
      'position': position?.trim(),
      'accountType': 'company',
      'nip': nipClean,
      'companyName': companyName,
      'companyAddress': companyAddress,
      'companyRegon': companyRegon,
      'companyStatusVat': companyStatusVat,
      'companyResidenceAddress': companyResidenceAddress,
      'companyWorkingAddress': companyWorkingAddress,
      'ndaAcceptedAt': FieldValue.serverTimestamp(),
      'accessLevel': 'teaser',
      'emailVerified': false,
      'role': 'lead',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await ref.set(profileData, SetOptions(merge: true));
    } catch (e) {
      // Na webie token może być jeszcze niepropagowany – jedna próba po krótkim opóźnieniu.
      final isPermissionDenied = e.toString().toLowerCase().contains('permission-denied') ||
          e.toString().toLowerCase().contains('insufficient permissions');
      if (kIsWeb && isPermissionDenied) {
        _authLog('registerWithNip: retry Firestore po permission-denied');
        await Future<void>.delayed(const Duration(milliseconds: 1500));
        await ref.set(profileData, SetOptions(merge: true));
      } else {
        rethrow;
      }
    }

    _authLog('registerWithNip: sendEmailVerification');
    await user.sendEmailVerification();

    _authLog('registerWithNip: log NDA (w tle)');
    unawaited(
      logNdaAcceptance(
        userId: user.uid,
        ndaVersion: 'v1.0',
        scrolledToEnd: ndaScrolledToEnd,
      ).catchError((Object e) {
        _authLog('logNdaAcceptance błąd (nie blokuje rejestracji)', e);
      }),
    );

    _authLog('registerWithNip zakończone OK', 'uid=${user.uid}');
    return userCred;
  }

  /// Pobiera dane zaproszenia po tokenie (kolekcja inviteTokens, dokument o id = token).
  Future<InviteData?> getInviteByToken(String token) async {
    if (token.isEmpty) return null;
    final doc = await _firestore.collection('inviteTokens').doc(token).get();
    if (!doc.exists) return null;
    final d = doc.data()!;
    final expiresAt = d['expiresAt'] as Timestamp?;
    if (expiresAt != null && DateTime.now().isAfter(expiresAt.toDate())) return null;
    if (d['used'] == true) return null;
    return InviteData(
      email: d['email'] as String? ?? '',
      role: d['role'] as String? ?? 'agent',
      regionVoivodeship: d['regionVoivodeship'] as String?,
    );
  }

  /// Dokończenie rejestracji z linku zaproszeniowego (Agent/Dyrektor).
  Future<UserCredential> completeInviteRegistration({
    required String token,
    required String displayName,
    required String phone,
    required String password,
    required bool regulaminAccepted,
  }) async {
    if (!regulaminAccepted) throw StateError('Wymagana akceptacja regulaminu');

    final invite = await getInviteByToken(token);
    if (invite == null) throw StateError('Nieprawidłowy lub wygasły link zaproszeniowy');

    final userCred = await _auth.createUserWithEmailAndPassword(
      email: invite.email.trim(),
      password: password,
    );
    final user = userCred.user!;

    final ref = _firestore.collection('users').doc(user.uid);
    await ref.set({
      'email': user.email,
      'displayName': displayName.trim(),
      'phone': phone.trim(),
      'role': invite.role,
      'regionVoivodeship': invite.regionVoivodeship,
      'accessLevel': 'identityVerified',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _firestore.collection('inviteTokens').doc(token).update({
      'used': true,
      'usedAt': FieldValue.serverTimestamp(),
    });

    return userCred;
  }

  /// Aktualizuje zdjęcie profilowe: upload do Storage (avatars/{uid}.jpg), Auth i Firestore.
  Future<void> updateUserPhoto(Uint8List imageBytes) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Brak zalogowanego użytkownika');

    final storage = FirebaseStorage.instance;
    final ref = storage.ref().child('avatars').child('${user.uid}.jpg');
    await ref.putData(
      imageBytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final url = await ref.getDownloadURL();

    await user.updateProfile(photoURL: url);
    await _firestore.collection('users').doc(user.uid).update({
      'photoUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Loguje akceptację NDA (kolekcja ndaAcceptanceLogs).
  Future<void> logNdaAcceptance({
    required String userId,
    required String ndaVersion,
    String? ipAddress,
    String? userAgent,
    required bool scrolledToEnd,
  }) async {
    await _firestore.collection('ndaAcceptanceLogs').add({
      'userId': userId,
      'ndaVersion': ndaVersion,
      'acceptedAt': FieldValue.serverTimestamp(),
      if (ipAddress != null) 'ipAddress': ipAddress,
      if (userAgent != null) 'userAgent': userAgent,
      'scrolledToEnd': scrolledToEnd,
    });
  }
}

/// Dane zaproszenia (Agent/Dyrektor) z Firestore.
class InviteData {
  const InviteData({
    required this.email,
    required this.role,
    this.regionVoivodeship,
  });
  final String email;
  final String role;
  final String? regionVoivodeship;
}
