// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Na web: zapisuje bajty jako plik i uruchamia pobieranie w przeglądarce.
void triggerPdfDownload(List<int> bytes, String filename) {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement()
    ..href = url
    ..download = filename
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
