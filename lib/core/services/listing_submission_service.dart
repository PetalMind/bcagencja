import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../state/models/property_model.dart';
import 'submission_document_service.dart';
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
  static const String statusPublished = 'published';

  static const String _listingsCollection = 'listings';
  static const String _notificationsCollection = 'notifications';

  /// Zapisuje zgłoszenie. Ustawia `createdAt` na serverTimestamp.
  /// [submittedByUid] – gdy użytkownik jest zalogowany, zapisujemy uid, aby mógł zobaczyć zgłoszenie w "Moje zgłoszenia".
  Future<String> submit(ListingSubmissionData data, {String? submittedByUid}) async {
    final map = data.toFirestore();
    map['createdAt'] = FieldValue.serverTimestamp();
    if (submittedByUid != null && submittedByUid.isNotEmpty) {
      map['submittedByUid'] = submittedByUid;
    }

    final ref = await _firestore.collection(_collection).add(map);
    return ref.id;
  }

  /// Stream zgłoszeń użytkownika (widok /#/dashboard/my-submissions).
  /// Zapytanie korzysta z indeksu zdefiniowanego w firestore.indexes.json:
  /// listing_submissions: submittedByUid ASC, createdAt DESC.
  Stream<List<ListingSubmissionRecord>> streamSubmissionsByUser(String uid) {
    return _firestore
        .collection(_collection)
        .where('submittedByUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ListingSubmissionRecord.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// Pobiera jedno zgłoszenie po id (dla widoku szczegółów).
  Future<ListingSubmissionRecord?> getSubmission(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (doc.data() == null) return null;
    return ListingSubmissionRecord.fromFirestore(doc.id, doc.data()!);
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

  /// Stream zgłoszeń do widoku "Baza ofert" (/#/oferty).
  /// Tylko statusy pending i published – zgodne z regułami Firestore (odczyt bez logowania).
  Stream<List<ListingSubmissionRecord>> streamSubmissionsForOffers({int limit = 100}) {
    return _firestore
        .collection(_collection)
        .where('status', whereIn: [statusPending, statusPublished])
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ListingSubmissionRecord.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// Konwersja zgłoszenia na Property (do kart na /#/oferty i szczegółów).
  /// Zdjęcia z załączników (jpg/jpeg/png) z polem [downloadUrl] trafiają do [images] i [mainImage].
  static Property propertyFromRecord(ListingSubmissionRecord r) {
    final city = r.locality ?? r.city ?? '';
    final voivodeship = _normalizeVoivodeship(r.voivodeship);
    final title = _teaserTitleFromRecord(r, voivodeship);
    final price = r.expectedPrice ?? r.estimatedValueMin ?? r.estimatedValueMax ?? 0.0;
    final area = r.area ?? 0.0;
    final firstTenant = r.tenants.isNotEmpty && r.tenants.first.name.isNotEmpty ? r.tenants.first : null;
    final monthlyRent = firstTenant?.monthlyRent ?? r.monthlyRent;
    final roi = price > 0 && monthlyRent != null && monthlyRent > 0
        ? (monthlyRent * 12 / price) * 100
        : null;
    final now = r.createdAt ?? DateTime.now();
    final imageUrls = r.attachments
        .where((a) => a.isPhoto && a.downloadUrl != null && a.downloadUrl!.isNotEmpty)
        .map((a) => a.downloadUrl!)
        .toList();
    final mainImageUrl = imageUrls.isNotEmpty ? imageUrls.first : null;
    return Property(
      id: r.id,
      title: title,
      description: r.description?.trim() ?? '',
      price: price,
      pricePerSqm: area > 0 && price > 0 ? price / area : null,
      area: area,
      floors: 0,
      parkingSpaces: null,
      propertyType: r.propertyType ?? r.assetType ?? 'office',
      transactionType: 'sale',
      location: r.displayAddress ?? city,
      city: city,
      district: null,
      street: r.street,
      latitude: null,
      longitude: null,
      images: imageUrls,
      mainImage: mainImageUrl,
      features: const [],
      designation: r.designation,
      additionalInfo: r.additionalInfo,
      yearBuilt: null,
      condition: null,
      buildingClass: null,
      hasLoadingDock: false,
      hasParking: false,
      hasElevator: false,
      hasSecurity: false,
      hasReception: false,
      ceilingHeight: null,
      plotArea: r.propertyType == 'land' ? area : null,
      zoning: r.mpzp,
      roi: roi,
      currentRent: firstTenant?.monthlyRent ?? monthlyRent,
      tenant: firstTenant?.name,
      leaseUntil: firstTenant?.leaseUntil,
      verified: false,
      promoted: false,
      ownerId: r.assignedToAgentId ?? r.submittedByUid ?? 'unknown',
      ownerName: r.contactName,
      ownerPhone: r.contactPhone,
      ownerEmail: r.contactEmail,
      createdAt: now,
      updatedAt: now,
      views: 0,
      favorites: 0,
      vdrDocuments: const [],
      estimatedValueMin: r.estimatedValueMin,
      estimatedValueMax: r.estimatedValueMax,
      voivodeship: voivodeship,
    );
  }

  static String? _normalizeVoivodeship(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final t = v.trim();
    if (t.toLowerCase().startsWith('woj.')) return t;
    return 'woj. $t';
  }

  /// Teasery: realne tytuły typu „Park handlowy z najemcą spożywczym – woj. śląskie”.
  static String _teaserTitleFromRecord(ListingSubmissionRecord r, String? voivodeship) {
    final typeLabel = _teaserTypeLabel(r);
    final locPart = voivodeship != null ? voivodeship : (r.locality ?? r.city ?? '');
    if (locPart.isEmpty) return typeLabel;
    return '$typeLabel – $locPart';
  }

  static String _teaserTypeLabel(ListingSubmissionRecord r) {
    final t = r.propertyType ?? r.assetType ?? 'office';
    final tenantName = r.tenantName?.toLowerCase() ?? '';
    final hasTenant = r.tenants.isNotEmpty && r.tenants.first.name.isNotEmpty;
    final tenantCategory = _inferTenantCategory(tenantName);

    switch (t) {
      case 'retail':
        if (hasTenant && tenantCategory != null) {
          return 'Lokal handlowy z najemcą $tenantCategory';
        }
        if (hasTenant) return 'Lokal handlowy z najemcą';
        return 'Lokal handlowy';
      case 'office':
        if (hasTenant) return 'Biurowiec z najemcą';
        return 'Biurowiec';
      case 'warehouse':
        if (hasTenant) return 'Magazyn / hala z najemcą';
        return 'Magazyn / hala';
      case 'industrial':
        if (hasTenant) return 'Obiekt przemysłowy z najemcą';
        return 'Obiekt przemysłowy';
      case 'land':
        return 'Działka inwestycyjna';
      case 'hotel':
        return 'Hotel / obiekt hotelarski';
      default:
        if (hasTenant) return 'Nieruchomość z najemcą';
        return 'Nieruchomość komercyjna';
    }
  }

  static String? _inferTenantCategory(String name) {
    const spozywcze = ['biedronka', 'lidl', 'kaufland', 'dino', 'lewiatan', 'stokrotka', 'netto', 'aldi', 'carrefour', 'auchan', 'tesco'];
    const diy = ['leroy', 'castorama', 'obi', 'praktiker', 'bauhaus', 'jysk'];
    const uslugi = ['pepco', 'action', 'tk maxx', 'primark', 'ccc', 'deichmann', 'new yorker'];
    final n = name.trim().toLowerCase();
    for (final s in spozywcze) { if (n.contains(s)) return 'spożywczym'; }
    for (final s in diy) { if (n.contains(s)) return 'DIY/budowlanym'; }
    for (final s in uslugi) { if (n.contains(s)) return 'usługowym'; }
    return null;
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

  /// Udostępnia zgłoszenie do sprzedaży: zmienia status na published, tworzy ofertę w systemie (listings),
  /// powiadamia przypisanego agenta (kolekcja notifications).
  /// Wymaga, aby zgłoszenie miało przypisanego agenta (assignedToAgentId).
  /// Zdjęcia z załączników (jpg/jpeg/png) są kopiowane do oferty jako [images] i [mainImage].
  Future<String> shareForSale(String submissionId) async {
    final record = await getSubmission(submissionId);
    if (record == null) {
      throw StateError('Zgłoszenie nie istnieje');
    }
    final agentId = record.assignedToAgentId;
    if (agentId == null || agentId.isEmpty) {
      throw StateError('Zgłoszenie musi być najpierw przypisane do agenta');
    }
    if (record.status == statusPublished) {
      return record.listingId ?? submissionId;
    }

    final imageUrls = await _resolvePhotoUrls(record.attachments);

    final title = _listingTitleFromRecord(record);
    final description = record.description?.trim().isNotEmpty == true
        ? record.description!
        : 'Oferta udostępniona ze zgłoszenia do sprzedaży (${record.referenceNumber}).';
    final price = record.expectedPrice ?? record.estimatedValueMin ?? record.estimatedValueMax ?? 0.0;
    final area = record.area ?? 0.0;
    final location = _formatAddressFromRecord(record);
    final city = record.locality ?? record.city ?? '';

    final listingData = <String, dynamic>{
      'title': title,
      'description': description,
      'price': price,
      'area': area,
      'floors': 0,
      'propertyType': record.propertyType ?? record.assetType ?? 'property',
      'transactionType': 'sale',
      'location': location.isNotEmpty ? location : city,
      'city': city,
      'ownerId': agentId,
      'images': imageUrls,
      'mainImage': imageUrls.isNotEmpty ? imageUrls.first : null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'sourceSubmissionId': submissionId,
      'verified': false,
      'promoted': false,
      if (record.designation.isNotEmpty) 'designation': record.designation,
      if (record.additionalInfo.isNotEmpty) 'additionalInfo': record.additionalInfo,
    };

    final listingRef = await _firestore.collection(_listingsCollection).add(listingData);
    final listingId = listingRef.id;

    await _firestore.collection(_notificationsCollection).add({
      'userId': agentId,
      'type': 'submission_published',
      'submissionId': submissionId,
      'listingId': listingId,
      'title': 'Udostępniono ofertę do sprzedaży',
      'body': 'Zgłoszenie $title zostało udostępnione w systemie.',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection(_collection).doc(submissionId).set({
      'status': statusPublished,
      'publishedAt': FieldValue.serverTimestamp(),
      'listingId': listingId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return listingId;
  }

  /// Dla załączników będących zdjęciami (jpg/jpeg/png) zwraca listę URL-i.
  /// Gdy załącznik ma [downloadUrl] – używa go; w przeciwnym razie pobiera URL ze Storage (np. stare zgłoszenia).
  Future<List<String>> _resolvePhotoUrls(List<SubmissionAttachment> attachments) async {
    final storage = FirebaseStorage.instance;
    final urls = <String>[];
    for (final a in attachments) {
      if (!a.isPhoto) continue;
      if (a.downloadUrl != null && a.downloadUrl!.isNotEmpty) {
        urls.add(a.downloadUrl!);
        continue;
      }
      try {
        final url = await storage.ref().child(a.storagePath).getDownloadURL();
        if (url.isNotEmpty) urls.add(url);
      } catch (_) {
        // Pomiń załącznik, jeśli nie udało się pobrać URL (np. plik usunięty).
      }
    }
    return urls;
  }

  static String _formatAddressFromRecord(ListingSubmissionRecord r) {
    final parts = <String>[];
    if (r.street != null && r.street!.isNotEmpty) parts.add(r.street!);
    if (r.buildingNumber != null && r.buildingNumber!.isNotEmpty) parts.add(r.buildingNumber!);
    if (r.apartmentNumber != null && r.apartmentNumber!.isNotEmpty) parts.add('m. ${r.apartmentNumber!}');
    if (r.postalCode != null && r.postalCode!.isNotEmpty) parts.add(r.postalCode!);
    if (r.locality != null && r.locality!.isNotEmpty) parts.add(r.locality!);
    if (parts.isNotEmpty) return parts.join(', ');
    if (r.formattedAddress != null && r.formattedAddress!.trim().isNotEmpty) return r.formattedAddress!;
    return '${r.city ?? ''}${r.voivodeship != null ? ', ${r.voivodeship}' : ''}'.trim();
  }

  static String _listingTitleFromRecord(ListingSubmissionRecord r) {
    final type = r.typeShortLabel;
    final loc = r.locality ?? r.city ?? '';
    final locFull = loc.isNotEmpty && r.voivodeship != null ? '$loc, ${r.voivodeship}' : (loc.isNotEmpty ? loc : (r.voivodeship ?? ''));
    return locFull.isNotEmpty ? '$type – $locFull' : type;
  }

  /// Tworzy [ListingSubmissionData] z rekordu (do podglądu zgłoszenia w formularzu).
  static ListingSubmissionData dataFromRecord(ListingSubmissionRecord r) {
    final data = ListingSubmissionData();
    data.propertyType = r.propertyType ?? r.assetType;
    data.street = r.street;
    data.buildingNumber = r.buildingNumber;
    data.apartmentNumber = r.apartmentNumber;
    data.postalCode = r.postalCode;
    data.locality = r.locality ?? r.city;
    data.voivodeship = r.voivodeship;
    data.formattedAddress = r.formattedAddress;
    data.hideExactAddress = r.hideExactAddress ?? true;
    data.area = r.area;
    data.tenantType = r.tenantType;
    if (r.tenants.isNotEmpty) {
      data.tenants = r.tenants
          .map((t) => TenantEntry(name: t.name, leaseUntil: t.leaseUntil, monthlyRent: t.monthlyRent))
          .toList();
    }
    data.mpzp = r.mpzp;
    data.designation = List.from(r.designation);
    data.additionalInfo = List.from(r.additionalInfo);
    data.utilities = List.from(r.utilities);
    data.estimatedValueMin = r.estimatedValueMin;
    data.estimatedValueMax = r.estimatedValueMax;
    data.expectedPrice = r.expectedPrice;
    data.priceFlexibility = r.priceFlexibility;
    data.description = r.description;
    data.attachments = r.attachments
        .map((a) => SubmissionAttachment(displayName: a.displayName, storagePath: a.storagePath, downloadUrl: a.downloadUrl))
        .toList();
    data.contactName = r.contactName;
    data.contactEmail = r.contactEmail;
    data.contactPhone = r.contactPhone;
    data.preferredContactTime = r.preferredContactTime;
    data.acceptedPrivacy = true;
    data.acceptedContact = true;
    return data;
  }
}

/// Rekord zgłoszenia z Firestore (id + dane).
class ListingSubmissionRecord {
  final String id;
  final String status;
  final String? submittedByUid;
  final String? assetType;
  final String? propertyType;
  final String? street;
  final String? buildingNumber;
  final String? apartmentNumber;
  final String? postalCode;
  final String? city;
  final String? locality;
  final String? voivodeship;
  final String? formattedAddress;
  /// Nie publikować dokładnego adresu (off-market).
  final bool? hideExactAddress;
  final double? area;
  final String? tenantType;
  final List<TenantEntry> tenants;
  /// Pierwszy najemca (dla kompatybilności).
  String? get tenantName => tenants.isNotEmpty && tenants.first.name.isNotEmpty ? tenants.first.name : null;
  /// Suma czynszów wszystkich najemców.
  double? get monthlyRent {
    final sum = tenants
        .where((t) => t.monthlyRent != null && t.monthlyRent! > 0)
        .map((t) => t.monthlyRent!)
        .fold<double>(0, (a, b) => a + b);
    return sum > 0 ? sum : null;
  }
  final String? mpzp;
  final List<String> designation;
  final List<String> additionalInfo;
  final List<String> utilities;
  final double? estimatedValueMin;
  final double? estimatedValueMax;
  final double? expectedPrice;
  final String? priceFlexibility;
  final String? description;
  final String? contactName;
  final String? contactEmail;
  final String? contactPhone;
  final String? preferredContactTime;
  final DateTime? createdAt;
  final String? assignedToAgentId;
  final String? rejectionReason;
  final DateTime? rejectedAt;
  final List<SubmissionAttachment> attachments;
  final DateTime? publishedAt;
  final String? listingId;

  ListingSubmissionRecord({
    required this.id,
    required this.status,
    this.submittedByUid,
    this.assetType,
    this.propertyType,
    this.street,
    this.buildingNumber,
    this.apartmentNumber,
    this.postalCode,
    this.city,
    this.locality,
    this.voivodeship,
    this.formattedAddress,
    this.hideExactAddress,
    this.area,
    this.tenantType,
    this.tenants = const [],
    this.mpzp,
    this.designation = const [],
    this.additionalInfo = const [],
    this.utilities = const [],
    this.estimatedValueMin,
    this.estimatedValueMax,
    this.expectedPrice,
    this.priceFlexibility,
    this.description,
    this.contactName,
    this.contactEmail,
    this.contactPhone,
    this.preferredContactTime,
    this.createdAt,
    this.assignedToAgentId,
    this.rejectionReason,
    this.rejectedAt,
    this.attachments = const [],
    this.publishedAt,
    this.listingId,
  });

  static List<String> _toStringList(dynamic v) {
    if (v == null || v is! List) return const [];
    return v.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
  }

  static ListingSubmissionRecord fromFirestore(String id, Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    final rejectedAt = data['rejectedAt'];
    final publishedAt = data['publishedAt'];
    final utilities = data['utilities'];
    final attachmentsRaw = data['attachments'];
    final attachments = attachmentsRaw is List
        ? attachmentsRaw
            .map((e) => e is Map ? SubmissionAttachment.fromJson(Map<String, dynamic>.from(e)) : null)
            .whereType<SubmissionAttachment>()
            .toList()
        : <SubmissionAttachment>[];

    // Parsowanie najemców (nowy format: lista, lub stary: tenantName/leaseUntil/monthlyRent)
    List<TenantEntry> tenants = [];
    final tenantsRaw = data['tenants'];
    if (tenantsRaw is List) {
      for (final e in tenantsRaw) {
        if (e is Map) {
          final m = Map<String, dynamic>.from(e);
          final name = (m['name'] as String?)?.trim();
          if (name != null && name.isNotEmpty) {
            final le = m['leaseUntil'];
            final leaseUntilDate = le is Timestamp ? le.toDate() : (le is DateTime ? le : null);
            tenants.add(TenantEntry(
              name: name,
              leaseUntil: leaseUntilDate,
              monthlyRent: (m['monthlyRent'] as num?)?.toDouble(),
            ));
          }
        }
      }
    } else {
      final oldName = (data['tenantName'] as String?)?.trim();
      if (oldName != null && oldName.isNotEmpty) {
        final le = data['leaseUntil'];
        final leaseUntilDate = le is Timestamp ? le.toDate() : (le is DateTime ? le : null);
        tenants.add(TenantEntry(
          name: oldName,
          leaseUntil: leaseUntilDate,
          monthlyRent: (data['monthlyRent'] as num?)?.toDouble(),
        ));
      }
    }

    return ListingSubmissionRecord(
      id: id,
      status: data['status'] as String? ?? 'pending',
      submittedByUid: data['submittedByUid'] as String?,
      assetType: data['assetType'] as String?,
      propertyType: data['propertyType'] as String?,
      street: data['street'] as String?,
      buildingNumber: data['buildingNumber'] as String?,
      apartmentNumber: data['apartmentNumber'] as String?,
      postalCode: data['postalCode'] as String?,
      city: data['city'] as String?,
      locality: data['locality'] as String? ?? data['city'] as String?,
      voivodeship: data['voivodeship'] as String?,
      formattedAddress: data['formattedAddress'] as String?,
      hideExactAddress: data['hideExactAddress'] as bool?,
      area: (data['area'] as num?)?.toDouble(),
      tenantType: data['tenantType'] as String?,
      tenants: tenants,
      mpzp: data['mpzp'] as String?,
      designation: _toStringList(data['designation']),
      additionalInfo: _toStringList(data['additionalInfo']),
      utilities: utilities is List<dynamic>
          ? utilities.map((e) => e.toString()).toList()
          : const [],
      estimatedValueMin: (data['estimatedValueMin'] as num?)?.toDouble(),
      estimatedValueMax: (data['estimatedValueMax'] as num?)?.toDouble(),
      expectedPrice: (data['expectedPrice'] as num?)?.toDouble(),
      priceFlexibility: data['priceFlexibility'] as String?,
      description: data['description'] as String?,
      contactName: data['contactName'] as String?,
      contactEmail: data['contactEmail'] as String?,
      contactPhone: data['contactPhone'] as String?,
      preferredContactTime: data['preferredContactTime'] as String?,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
      assignedToAgentId: data['assignedToAgentId'] as String?,
      rejectionReason: data['rejectionReason'] as String?,
      rejectedAt: rejectedAt is Timestamp ? rejectedAt.toDate() : null,
      attachments: attachments,
      publishedAt: publishedAt is Timestamp ? publishedAt.toDate() : null,
      listingId: data['listingId'] as String?,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'pending': return 'Nowe';
      case 'in_progress': return 'W trakcie';
      case 'contracted': return 'Zakontraktowane';
      case 'rejected': return 'Odrzucone';
      case 'published': return 'Udostępnione';
      default: return status;
    }
  }

  String get typeDisplayLabel {
    final t = propertyType ?? assetType;
    if (t == null) return '—';
    switch (t) {
      case 'retail': return 'Lokal handlowy';
      case 'office': return 'Budynek biurowy';
      case 'land': return 'Grunt';
      case 'warehouse': return 'Hala magazynowa';
      case 'under_construction': return 'Obiekt w budowie';
      case 'unsure': return 'Nie jestem pewien';
      case 'property': return 'Nieruchomość';
      default: return t;
    }
  }

  /// Krótka etykieta do tabeli (np. "Lokal + Najemca", "Grunt").
  String get typeShortLabel {
    final t = propertyType ?? assetType;
    if (t == null) return '—';
    if (t == 'land') return 'Grunt';
    if (tenantType != null && tenantType!.isNotEmpty) return 'Lokal + Najemca';
    switch (t) {
      case 'retail': return 'Lokal';
      case 'office': return 'Biuro';
      case 'warehouse': return 'Hala';
      case 'under_construction': return 'W budowie';
      case 'unsure': return '?';
      case 'property': return 'Nieruchomość';
      default: return typeDisplayLabel;
    }
  }

  String get referenceNumber => 'BC-2026-$id';

  /// Sformatowany adres do wyświetlenia (ulica, nr, lokalu, kod, miejscowość lub formattedAddress/city).
  String? get displayAddress {
    final parts = <String>[];
    if (street != null && street!.isNotEmpty) parts.add(street!);
    if (buildingNumber != null && buildingNumber!.isNotEmpty) parts.add(buildingNumber!);
    if (apartmentNumber != null && apartmentNumber!.isNotEmpty) parts.add('m. ${apartmentNumber!}');
    if (postalCode != null && postalCode!.isNotEmpty) parts.add(postalCode!);
    if (locality != null && locality!.isNotEmpty) parts.add(locality!);
    if (parts.isNotEmpty) return parts.join(', ');
    if (formattedAddress != null && formattedAddress!.trim().isNotEmpty) return formattedAddress;
    return city;
  }
}
