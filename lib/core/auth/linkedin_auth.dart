import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;

import '../config/app_config.dart';

import 'linkedin_auth_storage_stub.dart'
    if (dart.library.html) 'linkedin_auth_storage_web.dart' as storage;

/// Stałe OAuth LinkedIn (OpenID Connect).
/// https://learn.microsoft.com/en-us/linkedin/consumer/integrations/self-serve/sign-in-with-linkedin-v2
const String _linkedInAuthBase = 'https://www.linkedin.com/oauth/v2/authorization';
const String _linkedInScopes = 'openid profile email';

/// Generuje losowy state do ochrony przed CSRF (zapisywany w sessionStorage na web).
String _generateState() {
  final values = List<int>.generate(24, (i) => (DateTime.now().microsecondsSinceEpoch + i) % 256);
  return base64UrlEncode(values).replaceAll('=', '');
}

/// Buduje URL do przekierowania użytkownika na logowanie LinkedIn.
/// [returnTo] – ścieżka do przekierowania po zalogowaniu (np. /dashboard).
/// Zwraca null jeśli brak clientId lub nie web.
String? buildLinkedInAuthUrl([String? returnTo]) {
  if (!kIsWeb || AppConfig.linkedInClientId.isEmpty || AppConfig.linkedInClientId == 'YOUR_LINKEDIN_CLIENT_ID') {
    return null;
  }
  final random = _generateState();
  final stateValue = returnTo != null && returnTo.isNotEmpty ? '$random|$returnTo' : random;
  storage.setLinkedInState(stateValue);
  final redirectUri = Uri.base.origin + AppConfig.linkedInRedirectPath;
  final params = <String, String>{
    'response_type': 'code',
    'client_id': AppConfig.linkedInClientId,
    'redirect_uri': redirectUri,
    'scope': _linkedInScopes,
    'state': stateValue,
  };
  final uri = Uri.parse(_linkedInAuthBase).replace(queryParameters: params);
  return uri.toString();
}

/// Pobiera zapisany state (do weryfikacji w callbacku).
String? getLinkedInSavedState() {
  return storage.getLinkedInState();
}

/// Czyści zapisany state po użyciu.
void clearLinkedInSavedState() {
  storage.clearLinkedInState();
}

/// Parsuje state: "randomId" lub "randomId|/returnPath".
void parseLinkedInState(String state, void Function(String csrf, String? returnTo) fn) {
  final pipe = state.indexOf('|');
  if (pipe >= 0) {
    fn(state.substring(0, pipe), state.substring(pipe + 1));
  } else {
    fn(state, null);
  }
}

/// Przekierowuje przeglądarkę na [url] (tylko web).
void redirectToLinkedIn(String url) {
  storage.redirectToUrl(url);
}

/// Na web: pełne przeładowanie strony pod [path] (np. /dashboard) – odświeża cały widok po OAuth.
void replaceToPath(String path) {
  storage.replaceToPath(path);
}
