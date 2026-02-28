import 'package:flutter_riverpod/legacy.dart';
import '../../../core/services/wl_api_client.dart';

/// Dane formularza z kroku 2 rejestracji NIP (bez powtarzania danych firmy z WL).
class NipRegistrationFormData {
  const NipRegistrationFormData({
    required this.displayName,
    this.position,
    required this.email,
    required this.phone,
    required this.password,
    required this.stayLoggedIn,
  });

  final String displayName;
  final String? position;
  final String email;
  final String phone;
  final String password;
  final bool stayLoggedIn;
}

/// Zweryfikowany podmiot z rejestru WL (krok 1). Ustawiany po weryfikacji NIP.
final verifiedNipSubjectProvider =
    StateProvider<WlSubject?>((ref) => null);

/// Dane formularza z kroku 2 (imię/nazwisko, stanowisko, email, telefon, hasło). Ustawiane przed krokiem 3.
final nipRegistrationFormProvider =
    StateProvider<NipRegistrationFormData?>((ref) => null);
