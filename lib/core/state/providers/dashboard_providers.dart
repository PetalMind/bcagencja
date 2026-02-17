import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_config.dart';
import '../../services/listing_submission_service.dart';
import '../../services/listings_service.dart';
import '../../services/recently_viewed_service.dart';
import '../models/property_model.dart';
import 'auth_provider.dart';

/// Serwis ofert (listings).
final listingsServiceProvider = Provider<ListingsService>((ref) => ListingsService());

/// Stream pojedynczej oferty po ID – najpierw kolekcja listings, gdy brak: listing_submissions (zgłoszenie jako Property).
final propertyDetailProvider =
    StreamProvider.autoDispose.family<Property?, String>((ref, id) {
  if (id.isEmpty) return Stream.value(null);
  final listService = ref.watch(listingsServiceProvider);
  final subService = ref.watch(listingSubmissionServiceProvider);
  final ownerId = ref.watch(currentUserProvider).valueOrNull?.id;
  return listService
      .streamListingById(id, ownerIdToAllowDraft: ownerId)
      .asyncExpand((p) async* {
        if (p != null) {
          yield p;
          return;
        }
        final s = await subService.getSubmission(id);
        yield s != null ? ListingSubmissionService.propertyFromRecord(s) : null;
      });
});

/// Stream opublikowanych ofert partnera/agenta (ownerId == currentUser.id).
final partnerListingsStreamProvider = StreamProvider<List<Property>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user?.id == null || user!.id.isEmpty) return Stream.value([]);
  final service = ref.watch(listingsServiceProvider);
  return service.streamPartnerListings(ownerId: user.id);
});

/// Liczba ogłoszeń partnera/agenta (moje oferty). Źródło: Firestore.
final partnerListingsCountProvider = Provider<int>((ref) {
  final list = ref.watch(partnerListingsStreamProvider).valueOrNull;
  return list?.length ?? 0;
});

/// Statystyki partnera: suma wyświetleń wszystkich ofert (ostatnie 30 dni – w Firestore to pole to łączna liczba).
final partnerStatsViewsProvider = Provider<int>((ref) {
  final list = ref.watch(partnerListingsStreamProvider).valueOrNull ?? [];
  return list.fold<int>(0, (sum, p) => sum + p.views);
});

/// Statystyki partnera: suma ulubionych (zapisanych przez użytkowników) dla wszystkich ofert.
final partnerStatsFavoritesProvider = Provider<int>((ref) {
  final list = ref.watch(partnerListingsStreamProvider).valueOrNull ?? [];
  return list.fold<int>(0, (sum, p) => sum + p.favorites);
});

/// Statystyki partnera: liczba zapytań/kontaktów. Źródło: brak kolekcji – 0 do czasu wdrożenia.
final partnerStatsContactCountProvider = Provider<int>((ref) {
  ref.watch(currentUserProvider);
  return 0;
});

/// Najpopularniejsze ogłoszenia partnera (posortowane po wyświetleniach, max 10).
final partnerTopListingsByViewsProvider = Provider<List<Property>>((ref) {
  final list = ref.watch(partnerListingsStreamProvider).valueOrNull ?? [];
  final sorted = List<Property>.from(list)
    ..sort((a, b) => b.views.compareTo(a.views));
  return sorted.take(10).toList();
});

/// Liczba zapisanych wyszukiwań (alertów). Źródło: API.
final dashboardAlertsCountProvider = Provider<int>((ref) {
  ref.watch(currentUserProvider);
  // TODO: połączyć z API zapisanych wyszukiwań
  return 0;
});

/// Liczba nieprzeczytanych / wszystkich wiadomości. Źródło: API.
final dashboardMessagesCountProvider = Provider<int>((ref) {
  ref.watch(currentUserProvider);
  // TODO: połączyć z API wiadomości
  return 0;
});

/// Serwis zgłoszeń "Chcę sprzedać".
final listingSubmissionServiceProvider = Provider<ListingSubmissionService>((ref) => ListingSubmissionService());

/// Liczba zgłoszeń użytkownika (Moje zgłoszenia). Stream z Firestore.
final mySubmissionsCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user?.id == null || user!.id.isEmpty) return Stream.value(0);
  final service = ref.watch(listingSubmissionServiceProvider);
  return service.streamSubmissionsByUser(user.id).map((list) => list.length);
});

/// Źródło ofert do filtrowania „nowych”. Na razie mocki; po wdrożeniu Firestore
/// zastąpić przez zapytanie do kolekcji `listings` z filtrem po `publishedAt` / `createdAt`.
/// Indeksy w firestore.indexes.json: status+publishedAt DESC, status+createdAt DESC.
List<Property> _allListingsForNewFilter() {
  return List.generate(8, (i) => Property.mock(i));
}

/// Data graniczna: oferty „nowe” to te z createdAt >= (now - newListingsMaxAgeDays).
DateTime _newListingsCutoff() {
  return DateTime.now().subtract(
    Duration(days: AppConfig.newListingsMaxAgeDays),
  );
}

/// Skrót listy „nowe oferty” na dashboardzie inwestora.
/// Oferty uznawane za nowe: createdAt w ostatnich [AppConfig.newListingsMaxAgeDays] dniach.
/// Etykieta: "Tytuł – X% ROI" lub "Tytuł – Miasto" gdy brak ROI.
final newListingsPreviewProvider = Provider<List<String>>((ref) {
  ref.watch(currentUserProvider);
  final cutoff = _newListingsCutoff();
  final all = _allListingsForNewFilter();
  final newList = all
      .where((p) => p.createdAt.isAfter(cutoff) || p.createdAt.isAtSameMomentAs(cutoff))
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return newList
      .take(AppConfig.newListingsPreviewMaxCount)
      .map((p) => p.roi != null
          ? '${p.title} – ${p.roi!.toStringAsFixed(1)}% ROI'
          : '${p.title} – ${p.city}')
      .toList();
});

/// Skrót listy wiadomości na dashboardzie. Puste dopóki brak API.
final messagesPreviewProvider = Provider<List<String>>((ref) {
  ref.watch(currentUserProvider);
  return [];
});

/// Serwis ostatnio oglądanych (Firestore).
final recentlyViewedServiceProvider = Provider<RecentlyViewedService>((ref) {
  return RecentlyViewedService();
});

/// Element „ostatnio oglądane” w sidebarze: etykieta + link do oferty.
class RecentlyViewedItem {
  const RecentlyViewedItem({required this.listingId, required this.displayLabel});
  final String listingId;
  final String displayLabel;
}

/// Ostatnio oglądane oferty – stream z Firestore. Puste dla niezalogowanego.
final recentlyViewedPreviewProvider =
    StreamProvider<List<RecentlyViewedItem>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  final service = ref.watch(recentlyViewedServiceProvider);
  return service.watchRecentlyViewed(user.id).map((entries) =>
      entries.map((e) => RecentlyViewedItem(listingId: e.listingId, displayLabel: e.displayLabel)).toList());
});

/// Kryteria użytkownika (np. ROI min, budżet). Puste dopóki brak API.
final userCriteriaPreviewProvider = Provider<List<String>>((ref) {
  ref.watch(currentUserProvider);
  return [];
});
