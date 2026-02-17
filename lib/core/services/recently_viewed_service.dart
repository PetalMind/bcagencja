import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_config.dart';

/// Wpis „ostatnio oglądana oferta” – zapisywany w Firestore.
class RecentlyViewedEntry {
  const RecentlyViewedEntry({
    required this.listingId,
    required this.title,
    required this.city,
    required this.viewedAt,
  });

  final String listingId;
  final String title;
  final String city;
  final DateTime viewedAt;

  String get displayLabel => '$title – $city';

  Map<String, Object?> toMap() => {
        'listingId': listingId,
        'title': title,
        'city': city,
        'viewedAt': Timestamp.fromDate(viewedAt),
      };

  static RecentlyViewedEntry fromMap(Map<String, dynamic> data) {
    final viewedAt = data['viewedAt'];
    return RecentlyViewedEntry(
      listingId: data['listingId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      city: data['city'] as String? ?? '',
      viewedAt: viewedAt is Timestamp
          ? viewedAt.toDate()
          : DateTime.now(),
    );
  }
}

/// Serwis zapisu i odczytu „ostatnio oglądanych” ofert w Firestore.
/// Ścieżka: `users/{userId}/preferences/recently_viewed` (jeden dokument z tablicą).
class RecentlyViewedService {
  RecentlyViewedService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  int get _maxEntries => AppConfig.recentlyViewedMaxCount;

  String _docPath(String userId) =>
      'users/$userId/preferences/recently_viewed';

  /// Zapisuje obejrzenie oferty. Dla zalogowanego użytkownika.
  /// Przenosi istniejący wpis na początek; ogranicza listę do [_maxEntries].
  Future<void> recordView(
    String userId,
    String listingId,
    String title,
    String city,
  ) async {
    if (userId.isEmpty || listingId.isEmpty) return;

    final ref = _firestore.doc(_docPath(userId));
    final now = DateTime.now();
    final newEntry = RecentlyViewedEntry(
      listingId: listingId,
      title: title,
      city: city,
      viewedAt: now,
    );

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      List<Map<String, Object?>> entries;
      if (snap.exists && snap.data() != null) {
        final list = snap.data()!['entries'];
        if (list is List) {
          entries = list
              .cast<Map<String, dynamic>>()
              .map((e) => e.map((k, v) => MapEntry(k, v)))
              .toList();
        } else {
          entries = [];
        }
      } else {
        entries = [];
      }

      // Usuń stary wpis z tym samym listingId (jeśli jest) i dodaj na początek
      entries.removeWhere((e) => e['listingId'] == listingId);
      entries.insert(0, newEntry.toMap());
      if (entries.length > _maxEntries) {
        entries = entries.take(_maxEntries).toList();
      }

      tx.set(ref, {
        'entries': entries,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Stream ostatnio oglądanych ofert (najnowsze pierwsze).
  Stream<List<RecentlyViewedEntry>> watchRecentlyViewed(String userId) {
    if (userId.isEmpty) return Stream.value([]);

    return _firestore.doc(_docPath(userId)).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return <RecentlyViewedEntry>[];
      final list = snap.data()!['entries'];
      if (list is! List) return <RecentlyViewedEntry>[];
      return list
          .cast<Map<String, dynamic>>()
          .map(RecentlyViewedEntry.fromMap)
          .toList();
    });
  }
}
