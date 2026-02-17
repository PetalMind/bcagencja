import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/sell_submission/listing_submission_model.dart';

/// Zapis zgłoszeń "Chcę sprzedać" do kolekcji `listing_submissions`.
/// Dokumenty trafiają do bazy "Oczekiwanie" w panelu admina (status: pending).
class ListingSubmissionService {
  ListingSubmissionService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _collection = 'listing_submissions';
  static const String statusPending = 'pending';
  static const String statusInProgress = 'in_progress';
  static const String statusContracted = 'contracted';
  static const String statusRejected = 'rejected';

  /// Zapisuje zgłoszenie. Ustawia `createdAt` na serverTimestamp.
  /// Zwraca id utworzonego dokumentu.
  Future<String> submit(ListingSubmissionData data) async {
    final map = data.toFirestore();
    map['createdAt'] = FieldValue.serverTimestamp();

    final ref = await _firestore.collection(_collection).add(map);
    return ref.id;
  }

  /// Stream zgłoszeń (dla panelu admina). Opcjonalny filtr statusu (filtrowanie po stronie klienta).
  Stream<List<ListingSubmissionRecord>> streamSubmissions({
    String? statusFilter,
  }) {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      var list = snap.docs
          .map((doc) => ListingSubmissionRecord.fromFirestore(doc.id, doc.data()))
          .toList();
      if (statusFilter != null && statusFilter.isNotEmpty) {
        list = list.where((r) => r.status == statusFilter).toList();
      }
      return list;
    });
  }

  /// Aktualizuje status zgłoszenia.
  Future<void> updateStatus(String id, String status, {String? rejectionReason}) async {
    final data = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (status == ListingSubmissionService.statusRejected && rejectionReason != null) {
      data['rejectionReason'] = rejectionReason;
      data['rejectedAt'] = FieldValue.serverTimestamp();
    }
    if (status == ListingSubmissionService.statusInProgress ||
        status == ListingSubmissionService.statusContracted) {
      data['rejectionReason'] = null;
    }
    await _firestore.collection(_collection).doc(id).set(data, SetOptions(merge: true));
  }

  /// Przypisuje zgłoszenie do agenta.
  Future<void> assignToAgent(String id, String agentId) async {
    await _firestore.collection(_collection).doc(id).set({
      'assignedToAgentId': agentId,
      'status': ListingSubmissionService.statusInProgress,
      'assignedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

/// Rekord zgłoszenia z Firestore (id + dane).
class ListingSubmissionRecord {
  final String id;
  final String status;
  final String? assetType;
  final String? city;
  final String? voivodeship;
  final String? description;
  final String? contactName;
  final String? contactEmail;
  final String? contactPhone;
  final String? preferredContactTime;
  final DateTime? createdAt;
  final String? assignedToAgentId;
  final String? rejectionReason;
  final DateTime? rejectedAt;

  ListingSubmissionRecord({
    required this.id,
    required this.status,
    this.assetType,
    this.city,
    this.voivodeship,
    this.description,
    this.contactName,
    this.contactEmail,
    this.contactPhone,
    this.preferredContactTime,
    this.createdAt,
    this.assignedToAgentId,
    this.rejectionReason,
    this.rejectedAt,
  });

  static ListingSubmissionRecord fromFirestore(String id, Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    final rejectedAt = data['rejectedAt'];
    return ListingSubmissionRecord(
      id: id,
      status: data['status'] as String? ?? 'pending',
      assetType: data['assetType'] as String?,
      city: data['city'] as String?,
      voivodeship: data['voivodeship'] as String?,
      description: data['description'] as String?,
      contactName: data['contactName'] as String?,
      contactEmail: data['contactEmail'] as String?,
      contactPhone: data['contactPhone'] as String?,
      preferredContactTime: data['preferredContactTime'] as String?,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
      assignedToAgentId: data['assignedToAgentId'] as String?,
      rejectionReason: data['rejectionReason'] as String?,
      rejectedAt: rejectedAt is Timestamp ? rejectedAt.toDate() : null,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'pending': return 'Nowe';
      case 'in_progress': return 'W trakcie';
      case 'contracted': return 'Zakontraktowane';
      case 'rejected': return 'Odrzucone';
      default: return status;
    }
  }
}
