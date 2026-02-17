import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';

/// Wynik wysyłki kalkulacji ROI na e-mail.
enum RoiEmailSendResult {
  success,
  notConfigured,
  invalidEmail,
  networkError,
}

/// Serwis wywołujący Cloud Function wysyłającą e-mail z kalkulacją ROI.
class RoiCalculationEmailService {
  RoiCalculationEmailService._();

  static const _timeout = Duration(seconds: 15);

  /// Wysyła kalkulację na podany adres e-mail przez Firebase Cloud Function.
  /// Zwraca [RoiEmailSendResult.success] przy 200, [RoiEmailSendResult.notConfigured] przy 503,
  /// [RoiEmailSendResult.invalidEmail] przy 400, [RoiEmailSendResult.networkError] przy błędzie sieci.
  static Future<RoiEmailSendResult> send({
    required String email,
    required String subject,
    required String body,
  }) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty || !isValidEmail(trimmed)) {
      return RoiEmailSendResult.invalidEmail;
    }

    try {
      final response = await http
          .post(
            Uri.parse(AppConfig.sendRoiCalculationEmailUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': trimmed,
              'subject': subject,
              'body': body,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) return RoiEmailSendResult.success;
      if (response.statusCode == 503) return RoiEmailSendResult.notConfigured;
      if (response.statusCode == 400) return RoiEmailSendResult.invalidEmail;
      return RoiEmailSendResult.networkError;
    } catch (_) {
      return RoiEmailSendResult.networkError;
    }
  }

  /// Walidacja formatu adresu e-mail (do użycia w UI).
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w\-+.]+@[\w\-]+(\.[\w\-]+)+$').hasMatch(email);
  }
}
