import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/role_permissions.dart';
import '../../config/app_config.dart';
import '../../services/listing_submission_service.dart';
import '../../services/listings_service.dart';
import '../../services/recently_viewed_service.dart';
import '../models/property_model.dart';
import 'auth_provider.dart';
import 'favorites_provider.dart';

/// Serwis ofert (listings).
final listingsServiceProvider = Provider<ListingsService>((ref) => ListingsService());

/// Stream pojedynczej oferty po ID – najpierw kolekcja listings, gdy brak: listing_submissions (zgłoszenie jako Property).
final propertyDetailProvider =
    StreamProvider.autoDispose.family<Property?, String>((ref, id) {
  if (id.isEmpty) return Stream.value(null);
  final listService = ref.watch(listingsServiceProvider);
  final subService = ref.watch(listingSubmissionServiceProvider);
  final user = ref.watch(currentUserProvider).asData?.value;
  final ownerId = user?.id;
  final isAdmin = RolePermissions.hasAdminDashboard(user?.effectiveRoleLevel ?? UserRoleLevel.guest);
  return listService
      .streamListingById(id, ownerIdToAllowDraft: ownerId, adminBypass: isAdmin)
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
  final user = ref.watch(currentUserProvider).asData?.value;
  if (user?.id == null || user!.id.isEmpty) return Stream.value([]);
  final service = ref.watch(listingsServiceProvider);
  return service.streamPartnerListings(ownerId: user.id);
});

/// Liczba ogłoszeń partnera/agenta (moje oferty). Źródło: Firestore.
final partnerListingsCountProvider = Provider<int>((ref) {
  final list = ref.watch(partnerListingsStreamProvider).asData?.value;
  return list?.length ?? 0;
});

/// Statystyki partnera: suma wyświetleń wszystkich ofert (ostatnie 30 dni – w Firestore to pole to łączna liczba).
final partnerStatsViewsProvider = Provider<int>((ref) {
  final list = ref.watch(partnerListingsStreamProvider).asData?.value ?? [];
  return list.fold<int>(0, (sum, p) => sum + p.views);
});

/// Statystyki partnera: suma ulubionych (zapisanych przez użytkowników) dla wszystkich ofert.
final partnerStatsFavoritesProvider = Provider<int>((ref) {
  final list = ref.watch(partnerListingsStreamProvider).asData?.value ?? [];
  return list.fold<int>(0, (sum, p) => sum + p.favorites);
});

/// Statystyki partnera: liczba zapytań/kontaktów. Źródło: brak kolekcji – 0 do czasu wdrożenia.
final partnerStatsContactCountProvider = Provider<int>((ref) {
  ref.watch(currentUserProvider);
  return 0;
});

/// Najpopularniejsze ogłoszenia partnera (posortowane po wyświetleniach, max 10).
final partnerTopListingsByViewsProvider = Provider<List<Property>>((ref) {
  final list = ref.watch(partnerListingsStreamProvider).asData?.value ?? [];
  final sorted = List<Property>.from(list)
    ..sort((a, b) => b.views.compareTo(a.views));
  return sorted.take(10).toList();
});

/// Zwraca wynik podobieństwa oferty [other] do [current] (0–1; wyższy = bardziej podobna).
/// Kryteria: ta sama miejscowość, zbliżona cena, zbliżona powierzchnia.
double _similarityScore(Property current, Property other) {
  double score = 0.0;
  int factors = 0;

  final sameCity = (current.city.trim().toLowerCase() == other.city.trim().toLowerCase());
  score += sameCity ? 0.35 : 0.0;
  factors++;

  if (current.price > 0) {
    final priceDiff = (other.price - current.price).abs();
    final priceScore = 1.0 / (1.0 + (priceDiff / current.price));
    score += 0.4 * priceScore;
    factors++;
  }
  if (current.area > 0) {
    final areaDiff = (other.area - current.area).abs();
    final areaScore = 1.0 / (1.0 + (areaDiff / current.area));
    score += 0.25 * areaScore;
    factors++;
  }
  return factors > 0 ? score : 0.0;
}

/// Podobne oferty do danej oferty: ten sam typ, posortowane wg podobieństwa (miasto, cena, powierzchnia).
/// Pobiera oferty z Firestore, punktuje i zwraca do 4 pozycji.
final similarListingsProvider = FutureProvider.autoDispose.family<List<Property>, Property>((ref, property) async {
  final service = ref.watch(listingsServiceProvider);
  final candidates = await service.getPublishedListingsByType(
    property.propertyType,
    excludeId: property.id,
    limit: 40,
  );
  if (candidates.isEmpty) return [];
  final scored = candidates.map((p) => MapEntry(p, _similarityScore(property, p))).toList();
  scored.sort((a, b) => b.value.compareTo(a.value));
  return scored.map((e) => e.key).take(4).toList();
});

/// Wyróżnione oferty na stronie głównej: promowane first, potem uzupełnienie najnowszymi (max 6).
final featuredListingsProvider = StreamProvider<List<Property>>((ref) {
  final service = ref.watch(listingsServiceProvider);
  const limit = 6;
  return service.streamPublishedListings(limit: 24).map((list) {
    final promoted = list.where((p) => p.promoted).take(limit).toList();
    if (promoted.length >= limit) return promoted;
    final promotedIds = promoted.map((e) => e.id).toSet();
    final rest = list.where((p) => !promotedIds.contains(p.id)).take(limit - promoted.length).toList();
    return [...promoted, ...rest];
  });
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
  final user = ref.watch(currentUserProvider).asData?.value;
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
  final user = ref.watch(currentUserProvider).asData?.value;
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

const String _dashboardTutorialSeenKey = 'dashboard_tutorial_seen';

/// Czy użytkownik widział już tutorial coach mark na dashboardzie (po pierwszym logowaniu).
/// Gdy false – pokazujemy tutorial; po zakończeniu/pominięciu zapisujemy true w SharedPreferences.
final dashboardTutorialSeenProvider =
    AsyncNotifierProvider<DashboardTutorialSeenNotifier, bool>(DashboardTutorialSeenNotifier.new);

class DashboardTutorialSeenNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (prefs == null) return true;
    return prefs.getBool(_dashboardTutorialSeenKey) ?? false;
  }

  Future<void> markSeen() async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (prefs != null) await prefs.setBool(_dashboardTutorialSeenKey, true);
    state = const AsyncData(true);
  }
}
