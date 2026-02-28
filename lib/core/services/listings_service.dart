import 'package:cloud_firestore/cloud_firestore.dart';

import '../state/models/property_model.dart';

/// Serwis publicznej bazy ofert (kolekcja listings).
/// Zgodnie z docs/WDROZENIE_FUNKCJONALNOSCI.md: teasery dla anonima, pełne dla Level 2.
/// Pobiera tylko oferty opublikowane (status == 'published').
class ListingsService {
  ListingsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String _listingsCollection = 'listings';
  static const String _statusPublished = 'published';

  /// Stream opublikowanych ofert – publicznie dostępny.
  /// [typ] – opcjonalny filtr: 'land' (grunty), 'vacant' (pustostany), 'tenanted' (z najemcą).
  /// Używa indeksów z firestore.indexes.json: status+propertyType+createdAt.
  Stream<List<Property>> streamPublishedListings({
    String? typ,
    int limit = 100,
  }) {
    var query = _firestore
        .collection(_listingsCollection)
        .where('status', isEqualTo: _statusPublished)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (typ == 'land') {
      query = _firestore
          .collection(_listingsCollection)
          .where('status', isEqualTo: _statusPublished)
          .where('propertyType', isEqualTo: 'land')
          .orderBy('createdAt', descending: true)
          .limit(limit);
    } else if (typ == 'vacant') {
      // Pustostany: typy inne niż land, bez najemcy (tenant null/brak).
      // Firestore: propertyType in [...], tenant == null – wymaga composite index.
      // Na start: typy budynków (office, retail, warehouse, industrial, hotel).
      const vacantTypes = ['office', 'retail', 'warehouse', 'industrial', 'hotel'];
      query = _firestore
          .collection(_listingsCollection)
          .where('status', isEqualTo: _statusPublished)
          .where('propertyType', whereIn: vacantTypes)
          .orderBy('createdAt', descending: true)
          .limit(limit);
    } else if (typ == 'tenanted') {
      // Obiekty z najemcą: pobieramy typy budynków i filtrujemy w pamięci (tenant != null).
      const tenantedTypes = ['office', 'retail', 'warehouse', 'industrial', 'hotel'];
      query = _firestore
          .collection(_listingsCollection)
          .where('status', isEqualTo: _statusPublished)
          .where('propertyType', whereIn: tenantedTypes)
          .orderBy('createdAt', descending: true)
          .limit(limit * 2); // Pobierz więcej, potem filtruj (część może nie mieć tenant)
    }

    return query.snapshots().map((snap) {
      final list = snap.docs
          .map((doc) => Property.fromFirestore(doc.id, doc.data()))
          .whereType<Property>()
          .toList();
      if (typ == 'tenanted') {
        return list.where((p) => p.tenant != null && p.tenant!.trim().isNotEmpty).take(limit).toList();
      }
      return list;
    });
  }

  /// Stream opublikowanych ofert danego partnera/agenta (ownerId).
  /// Używane w dashboardzie partnera (statystyki, moje oferty).
  /// Wymaga indeksu: status ASC, ownerId ASC, createdAt DESC.
  Stream<List<Property>> streamPartnerListings({
    required String ownerId,
    int limit = 200,
  }) {
    return _firestore
        .collection(_listingsCollection)
        .where('status', isEqualTo: _statusPublished)
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Property.fromFirestore(doc.id, doc.data()))
            .whereType<Property>()
            .toList());
  }

  /// Pobiera opublikowane oferty tego samego typu (np. do „Podobne oferty”).
  /// [excludeId] – ID oferty do wykluczenia (bieżąca).
  /// Wymaga indeksu: status ASC, propertyType ASC, createdAt DESC.
  Future<List<Property>> getPublishedListingsByType(
    String propertyType, {
    String? excludeId,
    int limit = 40,
  }) async {
    var query = _firestore
        .collection(_listingsCollection)
        .where('status', isEqualTo: _statusPublished)
        .where('propertyType', isEqualTo: propertyType)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    final snap = await query.get();
    final list = snap.docs
        .map((doc) => Property.fromFirestore(doc.id, doc.data()))
        .whereType<Property>()
        .where((p) => excludeId == null || p.id != excludeId)
        .toList();
    return list;
  }

  /// Stream pojedynczej oferty po ID dokumentu (Firestore).
  /// Zwraca null, jeśli dokument nie istnieje lub nie jest opublikowany.
  /// [ownerIdToAllowDraft] – jeśli podane i oferta ma ownerId == ten ID, zwróć ofertę
  ///   także gdy status != published (właściciel widzi swoje drafty).
  /// [adminBypass] – gdy true, zwróć ofertę niezależnie od statusu (administrator widzi wszystkie).
  Stream<Property?> streamListingById(
    String id, {
    String? ownerIdToAllowDraft,
    bool adminBypass = false,
  }) {
    return _firestore
        .collection(_listingsCollection)
        .doc(id)
        .snapshots()
        .map((snap) {
          if (!snap.exists) return null;
          final data = snap.data();
          if (data == null) return null;
          if (adminBypass) return Property.fromFirestore(snap.id, data);
          final status = data['status'] as String?;
          final ownerId = data['ownerId'] as String?;
          final isPublished = status == _statusPublished;
          final isOwnerViewingDraft = ownerIdToAllowDraft != null &&
              ownerId != null &&
              ownerIdToAllowDraft == ownerId &&
              !isPublished;
          if (!isPublished && !isOwnerViewingDraft) return null;
          return Property.fromFirestore(snap.id, data);
        });
  }

  /// Aktualizuje ofertę w Firestore. Zwraca Future z błędem lub null przy sukcesie.
  Future<String?> updateListing(Property property) async {
    try {
      final data = property.toFirestoreUpdate();
      await _firestore
          .collection(_listingsCollection)
          .doc(property.id)
          .update(data);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Stream wszystkich ofert danego agenta (draft, published itd.) – widok „Moje ogłoszenia”.
  /// Wymaga reguły: odczyt jeśli resource.data.ownerId == request.auth.uid.
  /// Indeks: ownerId ASC, createdAt DESC.
  Stream<List<Property>> streamMyListings({
    required String ownerId,
    int limit = 200,
  }) {
    return _firestore
        .collection(_listingsCollection)
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Property.fromFirestore(doc.id, doc.data()))
            .whereType<Property>()
            .toList());
  }
}
