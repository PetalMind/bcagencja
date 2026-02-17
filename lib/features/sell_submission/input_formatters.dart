import 'package:flutter/services.dart';

/// Wspólne formattery i limity dla formularza "Chcę sprzedać".
/// Zgodne ze standardami: tylko dozwolone znaki, ograniczenie długości.

/// Maksymalna długość pola ceny (PLN – np. 999 999 999 999 = 12 cyfr + separator).
const int kMaxPriceLength = 14;

/// Maksymalna długość pola powierzchni (m²) – np. 999999.
const int kMaxAreaLength = 10;

/// Maksymalna długość pola czynszu miesięcznego (PLN).
const int kMaxRentLength = 14;

/// Maksymalna długość adresu.
const int kMaxAddressLength = 200;

/// Maksymalna długość ulicy (typ + nazwa).
const int kMaxStreetLength = 80;

/// Maksymalna długość numeru domu.
const int kMaxBuildingNumberLength = 20;

/// Maksymalna długość numeru lokalu.
const int kMaxApartmentNumberLength = 20;

/// Długość kodu pocztowego XX-XXX (5 cyfr + myślnik).
const int kPostalCodeLength = 6;

/// Maksymalna długość miejscowości.
const int kMaxLocalityLength = 80;

/// Maksymalna długość nazwy (np. najemca, imię).
const int kMaxNameLength = 100;

/// Maksymalna długość email.
const int kMaxEmailLength = 254;

/// Maksymalna długość telefonu (cyfry + spacje/myślniki).
const int kMaxPhoneLength = 20;

/// Maksymalna długość opisu / preferowany czas kontaktu.
const int kMaxShortTextLength = 150;

/// Maksymalna długość nazwy pliku (załącznik).
const int kMaxFileNameLength = 80;

/// Formatter: tylko cyfry i co najwyżej jeden separator dziesiętny (kropka lub przecinek).
/// Blokuje litery i wiele separatorów.
class DecimalTextInputFormatter extends TextInputFormatter {
  DecimalTextInputFormatter({this.maxLength = 14});

  final int maxLength;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final normalized = newValue.text.replaceAll(',', '.');
    final parts = normalized.split('.');
    if (parts.length > 2) return oldValue;
    final buffer = StringBuffer();
    for (final c in newValue.text.split('')) {
      if (RegExp(r'\d').hasMatch(c)) {
        buffer.write(c);
      } else if ((c == '.' || c == ',') && !buffer.toString().contains('.') && !buffer.toString().contains(',')) {
        buffer.write(c);
      }
    }
    final result = buffer.toString();
    if (result.length > maxLength) return oldValue;
    if (result == newValue.text) return newValue;
    final newSelection = TextSelection.collapsed(offset: result.length);
    return TextEditingValue(text: result, selection: newSelection);
  }
}

/// Formatter: tylko cyfry (np. powierzchnia bez ułamków, NIP).
final digitsOnlyFormatter = FilteringTextInputFormatter.digitsOnly;

/// Formatter: telefon – cyfry, spacje, myślniki, plus.
final phoneInputFormatter = FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\-()]'));

/// Formatter: kod pocztowy XX-XXX. Wstawia myślnik po 2 cyfrach, tylko 5 cyfr.
class PostalCodeTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 5) return oldValue;
    final formatted = digits.length <= 2
        ? digits
        : '${digits.substring(0, 2)}-${digits.substring(2)}';
    if (formatted == newValue.text) return newValue;
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

final postalCodeInputFormatter = PostalCodeTextInputFormatter();
