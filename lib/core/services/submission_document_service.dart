import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Rozszerzenia plików uznawane za zdjęcia (do galerii oferty).
const List<String> kPhotoExtensions = ['jpg', 'jpeg', 'png'];

/// Referencja do załącznika zgłoszenia (ścieżka w Storage + nazwa do wyświetlenia).
/// [downloadUrl] – opcjonalny URL do wyświetlania/pobierania; ustawiany po uploadzie dla zdjęć.
class SubmissionAttachment {
  const SubmissionAttachment({
    required this.displayName,
    required this.storagePath,
    this.downloadUrl,
  });

  final String displayName;
  final String storagePath;
  final String? downloadUrl;

  bool get isPhoto {
    final ext = (displayName.split('.').last).toLowerCase();
    return kPhotoExtensions.contains(ext);
  }

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'storagePath': storagePath,
        if (downloadUrl != null) 'downloadUrl': downloadUrl,
      };

  static SubmissionAttachment fromJson(Map<String, dynamic> json) =>
      SubmissionAttachment(
        displayName: json['displayName'] as String? ?? '',
        storagePath: json['storagePath'] as String? ?? '',
        downloadUrl: json['downloadUrl'] as String?,
      );
}

/// Serwis uploadu dokumentów do Firebase Storage w formularzu "Chcę sprzedać".
/// Wymaga zalogowania (anonimowego lub zwykłego) – przy pierwszym uploade wywołuje signInAnonymously jeśli użytkownik jest niezalogowany.
class SubmissionDocumentService {
  SubmissionDocumentService({
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB
  static const List<String> allowedExtensions = [
    'pdf',
    'jpg',
    'jpeg',
    'png',
    'doc',
    'docx',
  ];

  /// Zapewnia zalogowanie (anonimowe jeśli brak użytkownika).
  Future<String> _ensureAuth() async {
    var user = _auth.currentUser;
    if (user == null) {
      final cred = await _auth.signInAnonymously();
      user = cred.user;
    }
    if (user == null) throw Exception('Nie udało się utworzyć sesji');
    return user.uid;
  }

  /// Sanityzuje nazwę pliku (usuwa ścieżki, niebezpieczne znaki).
  String _sanitizeFilename(String name) {
    final base = name.split(RegExp(r'[/\\]')).last;
    return base.replaceAll(RegExp(r'[^\w\-\.]'), '_');
  }

  bool _isAllowedExtension(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    return allowedExtensions.contains(ext);
  }

  /// Uploaduje plik do Storage.
  /// Zwraca [SubmissionAttachment] z displayName i storagePath.
  /// Rzuca wyjątek przy przekroczeniu rozmiaru lub niedozwolonym rozszerzeniu.
  Future<SubmissionAttachment> upload({
    required Uint8List bytes,
    required String filename,
  }) async {
    if (bytes.length > maxFileSizeBytes) {
      throw Exception('Plik przekracza limit 10 MB');
    }
    final sanitized = _sanitizeFilename(filename);
    if (!_isAllowedExtension(sanitized)) {
      throw Exception(
        'Dozwolone formaty: ${allowedExtensions.join(', ')}',
      );
    }

    final uid = await _ensureAuth();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath =
        'listing_submissions/$uid/${timestamp}_$sanitized';

    final ref = _storage.ref().child(storagePath);
    await ref.putData(
      bytes,
      SettableMetadata(contentType: _mimeFromExtension(sanitized)),
    );

    String? downloadUrl;
    final ext = sanitized.split('.').last.toLowerCase();
    if (ext == 'jpg' || ext == 'jpeg' || ext == 'png') {
      downloadUrl = await ref.getDownloadURL();
    }

    return SubmissionAttachment(
      displayName: filename,
      storagePath: storagePath,
      downloadUrl: downloadUrl,
    );
  }

  String _mimeFromExtension(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }
}
