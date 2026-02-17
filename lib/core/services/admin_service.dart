import 'package:cloud_firestore/cloud_firestore.dart';

import '../state/models/property_model.dart';

/// Serwis panelu admina: użytkownicy, logi, globalna lista ofert.
/// Wymaga reguł Firestore dopuszczających odczyt/zapis dla roli admin.
class AdminService {
  AdminService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _usersCollection = 'users';
  static const String _logsCollection = 'document_downloads';
  static const String _listingsCollection = 'listings';

  /// Lista agentów (rola agent) do przypisywania zgłoszeń.
  Future<List<AdminUserRecord>> getAgents() async {
    final snap = await _firestore.collection(_usersCollection).get();
    return snap.docs
        .map((d) => AdminUserRecord.fromFirestore(d.id, d.data()))
        .where((u) => u.role == 'agent')
        .toList();
  }

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

  /// Stream globalnej listy ofert (kolekcja listings). Tylko dla admina.
  /// Zapytanie: orderBy('createdAt') – indeks w firestore.indexes.json (listings, createdAt DESC).
  Stream<List<Property>> streamGlobalListings({int limit = 500}) {
    return _firestore
        .collection(_listingsCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Property.fromFirestore(doc.id, doc.data()))
            .whereType<Property>()
            .toList());
  }
}

/// Rekord użytkownika w panelu admina.
/// Pola weryfikacji (NDA, accessLevel, VDR) używane w widoku „Weryfikacje tożsamości”.
class AdminUserRecord {
  final String id;
  final String? email;
  final String? displayName;
  final String role;
  final String? regionVoivodeship;
  final DateTime? createdAt;
  /// Data akceptacji NDA (Grant Level 2).
  final DateTime? ndaAcceptedAt;
  /// Poziom dostępu: teaser | identityVerified | vdr.
  final String accessLevel;
  /// Identyfikatory ofert, do których użytkownik ma dostęp VDR (Grant Level 3).
  final List<String> vdrAccessForListingIds;

  AdminUserRecord({
    required this.id,
    this.email,
    this.displayName,
    required this.role,
    this.regionVoivodeship,
    this.createdAt,
    this.ndaAcceptedAt,
    this.accessLevel = 'teaser',
    this.vdrAccessForListingIds = const [],
  });

  static AdminUserRecord fromFirestore(String id, Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    final ndaAcceptedAt = data['ndaAcceptedAt'];
    final vdrList = data['vdrAccessForListingIds'];
    return AdminUserRecord(
      id: id,
      email: data['email'] as String?,
      displayName: data['displayName'] as String?,
      role: data['role'] as String? ?? 'lead',
      regionVoivodeship: data['regionVoivodeship'] as String?,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
      ndaAcceptedAt: ndaAcceptedAt is Timestamp ? ndaAcceptedAt.toDate() : null,
      accessLevel: data['accessLevel'] as String? ?? 'teaser',
      vdrAccessForListingIds: vdrList is List
          ? List<String>.from(vdrList.map((e) => e.toString()))
          : const [],
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

  /// Czy użytkownik ma Level 2 (Identity Verified) – NDA zaakceptowane, pełna oferta.
  bool get isIdentityVerified =>
      accessLevel == 'identityVerified' || accessLevel == 'vdr' || ndaAcceptedAt != null;

  /// Etykieta poziomu dostępu do wyświetlenia.
  String get accessLevelLabel {
    switch (accessLevel) {
      case 'vdr':
        return 'VDR';
      case 'identityVerified':
        return 'Identity Verified';
      default:
        return 'Teaser';
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
