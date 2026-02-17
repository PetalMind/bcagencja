import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'vdr_download_helper_stub.dart'
    if (dart.library.html) 'vdr_download_helper_web.dart' as download_helper;

/// Wynik pobrania dokumentu VDR z watermarkiem.
sealed class VdrDownloadResult {}

class VdrDownloadSuccess extends VdrDownloadResult {
  VdrDownloadSuccess({this.filename});
  final String? filename;
}

class VdrDownloadFailure extends VdrDownloadResult {
  VdrDownloadFailure(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
}

/// Serwis pobierania dokumentów VDR przez Cloud Function z dynamicznym znakiem wodnym.
/// PDF jest nakładany w locie danymi: "Dla: {imię}, {data}, IP: {ip}" i logowany w document_downloads.
class VdrDocumentService {
  VdrDocumentService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Pobiera PDF z VDR z nałożonym w locie znakiem wodnym (kto, data, IP).
  /// [listingId] – id oferty, [documentPath] – pełna ścieżka w Storage (np. listings/xyz/vdr/umowa.pdf).
  /// [filename] – opcjonalna nazwa pliku przy zapisie (domyślnie z documentPath).
  Future<VdrDownloadResult> downloadWithWatermark({
    required String listingId,
    required String documentPath,
    String? filename,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return VdrDownloadFailure('Zaloguj się, aby pobrać dokument.');
    }

    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      return VdrDownloadFailure('Nie udało się uzyskać tokenu. Spróbuj wylogować i zalogować ponownie.');
    }

    final uri = Uri.parse(AppConfig.getDocumentWithWatermarkUrl).replace(
      queryParameters: {
        'listingId': listingId,
        'documentPath': documentPath,
      },
    );

    try {
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        String message = 'Błąd pobierania (${response.statusCode})';
        if (response.headers['content-type']?.contains('json') == true) {
          try {
            final body = response.body;
            final err = body.contains('error') ? body : null;
            if (err != null) {
              final start = body.indexOf('"error"');
              if (start >= 0) {
                final valueStart = body.indexOf(':', start) + 1;
                final valueEnd = body.indexOf('"', valueStart + 1) + 1;
                message = body.substring(valueStart + 1, valueEnd - 1).replaceAll(r'\"', '"');
              }
            }
          } catch (_) {}
        }
        return VdrDownloadFailure(message, statusCode: response.statusCode);
      }

      final bytes = response.bodyBytes;
      final name = filename ?? documentPath.split('/').last;
      final saveName = name.endsWith('.pdf') ? name : '$name.pdf';

      try {
        download_helper.triggerPdfDownload(bytes, saveName);
        return VdrDownloadSuccess(filename: saveName);
      } on UnsupportedError {
        return VdrDownloadFailure(
          'Pobieranie z watermarkiem jest dostępne w przeglądarce. Otwórz aplikację w przeglądarce.',
        );
      }
    } catch (e) {
      return VdrDownloadFailure('Błąd sieci: $e');
    }
  }
}
