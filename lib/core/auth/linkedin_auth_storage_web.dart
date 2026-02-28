// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

const _key = 'linkedin_oauth_state';

void setLinkedInState(String value) {
  html.window.sessionStorage[_key] = value;
}

String? getLinkedInState() {
  return html.window.sessionStorage[_key];
}

void clearLinkedInState() {
  html.window.sessionStorage.remove(_key);
}

/// Przekierowanie w oknie najwyższego poziomu (top), żeby LinkedIn nie ładował się
/// w iframe (content blocker / CSP wtedy blokują). replace() zamiast href by nie iść w history.
void redirectToUrl(String url) {
  try {
    final top = html.window.top;
    if (top != null && top != html.window) {
      (top.location as html.Location).replace(url);
      return;
    }
  } catch (_) {
    // cross-origin iframe – nie można zmienić top
  }
  html.window.location.replace(url);
}

/// Pełne przeładowanie strony pod [path] (np. /dashboard) – cały widok odświeżony po OAuth.
void replaceToPath(String path) {
  final url = '${Uri.base.origin}${path.startsWith('/') ? path : '/$path'}';
  html.window.location.replace(url);
}
