import 'package:cloud_firestore/cloud_firestore.dart';

/// Serwis panelu admina: użytkownicy, logi.
/// Wymaga reguł Firestore dopuszczających odczyt/zapis dla roli admin.
class AdminService {
  AdminService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _usersCollection = 'users';
  static const String _logsCollection = 'document_downloads';

  /// Stream listy użytkowników (dla panelu admina).
  Stream<List<AdminUserRecord>> streamUsers() {
    return _firestore
        .collection(_usersCollection)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AdminUserRecord.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// Aktualizuje rolę użytkownika.
  Future<void> updateUserRole(String uid, String role) async {
    await _firestore.collection(_usersCollection).doc(uid).update({
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream logów pobrań dokumentów (dla panelu admina).
  /// Kolekcja document_downloads: userId, listingId, documentId, ip, timestamp.
  Stream<List<AdminLogRecord>> streamDocumentDownloads({int limit = 100}) {
    return _firestore
        .collection(_logsCollection)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AdminLogRecord.fromFirestore(doc.id, doc.data()))
            .toList());
  }
}

/// Rekord użytkownika w panelu admina.
class AdminUserRecord {
  final String id;
  final String? email;
  final String? displayName;
  final String role;
  final String? regionVoivodeship;
  final DateTime? createdAt;

  AdminUserRecord({
    required this.id,
    this.email,
    this.displayName,
    required this.role,
    this.regionVoivodeship,
    this.createdAt,
  });

  static AdminUserRecord fromFirestore(String id, Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    return AdminUserRecord(
      id: id,
      email: data['email'] as String?,
      displayName: data['displayName'] as String?,
      role: data['role'] as String? ?? 'lead',
      regionVoivodeship: data['regionVoivodeship'] as String?,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }

  String get roleLabel {
    switch (role) {
      case 'admin': return 'Administrator';
      case 'director': return 'Dyrektor';
      case 'agent': return 'Agent';
      case 'lead': return 'Inwestor';
      default: return role;
    }
  }
}

/// Rekord logu (pobranie dokumentu).
class AdminLogRecord {
  final String id;
  final String? userId;
  final String? listingId;
  final String? documentId;
  final String? ipAddress;
  final DateTime? timestamp;

  AdminLogRecord({
    required this.id,
    this.userId,
    this.listingId,
    this.documentId,
    this.ipAddress,
    this.timestamp,
  });

  static AdminLogRecord fromFirestore(String id, Map<String, dynamic> data) {
    final timestamp = data['timestamp'];
    return AdminLogRecord(
      id: id,
      userId: data['userId'] as String?,
      listingId: data['listingId'] as String?,
      documentId: data['documentId'] as String?,
      ipAddress: data['ipAddress'] as String? ?? data['ip'] as String?,
      timestamp: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }
}
