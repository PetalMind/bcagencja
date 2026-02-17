import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// Wynik wyszukiwania podmiotu po NIP w Rejestrze WL (Ministerstwo Finansów).
/// API: https://wl-api.mf.gov.pl
class WlSubject {
  const WlSubject({
    required this.name,
    required this.nip,
    this.regon,
    this.statusVat,
    this.residenceAddress,
    this.workingAddress,
  });

  final String name;
  final String nip;
  final String? regon;
  final String? statusVat;
  final String? residenceAddress;
  final String? workingAddress;

  factory WlSubject.fromJson(Map<String, dynamic> json) {
    return WlSubject(
      name: json['name'] as String? ?? '',
      nip: json['nip'] as String? ?? '',
      regon: json['regon'] as String?,
      statusVat: json['statusVat'] as String?,
      residenceAddress: json['residenceAddress'] as String?,
      workingAddress: json['workingAddress'] as String?,
    );
  }
}

/// Klient API Rejestru Podatników VAT (WL), https://wl-api.mf.gov.pl
/// Endpoint: GET /api/search/nip/{nip}?date=YYYY-MM-DD
///
/// Na web używa Cloud Function proxy (AppConfig.wlApiProxyUrl), bo API WL
/// nie zwraca CORS – request z przeglądarki byłby zablokowany.
class WlApiClient {
  WlApiClient({http.Client? client})
      : _client = client ?? http.Client();

  static const String _directBaseUrl = 'https://wl-api.mf.gov.pl';

  final http.Client _client;

  /// Wyszukuje pojedynczy podmiot po NIP.
  /// [date] – data w formacie YYYY-MM-DD (wymagana przez API).
  /// Na web używa Cloud Function proxy (unika CORS).
  Future<WlSubject?> searchByNip(String nip, {required String date}) async {
    final normalizedNip = nip.replaceAll(RegExp(r'[^0-9]'), '');
    if (normalizedNip.length != 10) return null;

    final Uri uri = kIsWeb
        ? Uri.parse(AppConfig.wlApiProxyUrl).replace(queryParameters: {'nip': normalizedNip, 'date': date})
        : Uri.parse('$_directBaseUrl/api/search/nip/$normalizedNip').replace(queryParameters: {'date': date});

    final response = await _client.get(uri);

    if (response.statusCode != 200) return null;

    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>?;
      final result = data?['result'] as Map<String, dynamic>?;
      final subject = result?['subject'] as Map<String, dynamic>?;
      if (subject == null) return null;
      return WlSubject.fromJson(subject);
    } catch (_) {
      return null;
    }
  }
}
