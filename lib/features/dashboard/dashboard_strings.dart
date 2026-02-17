/// Stałe teksty widoku panelu użytkownika (dashboard).
/// Używane zamiast literałów w dashboard_page.dart i powiązanych widgetach.
class DashboardStrings {
  DashboardStrings._();

  // Nagłówek
  static const String titleShort = 'Panel użytkownika';
  static const String titleLong = 'Witaj w panelu użytkownika';
  static const String subtitle = 'Zarządzaj ogłoszeniami, ulubionymi i wiadomościami';

  // Sekcje
  static const String sectionLabelAgent = 'Panel Agenta';
  static const String sectionLabelInvestor = 'Panel Inwestora';

  // Szybkie wyszukiwanie
  static const String searchPlaceholder = 'Szukaj według lokalizacji, typu, najemcy...';
  static const String searchSemanticLabel = 'Szybkie wyszukiwanie nieruchomości';

  // Weryfikacja / NDA
  static const String verifyCtaNda = 'Zaakceptuj NDA, aby odblokować pełne oferty';
  static const String verifyCtaIdentity = 'Zweryfikuj konto – zobacz pełne oferty (lokalizacja, galeria)';

  // VDR CTA
  static const String vdrCtaTitle = 'ODBLOKUJ VDR';
  static const String vdrCtaTitleSidebar = 'ODBLOKUJ VDR ACCESS';
  static const String vdrCtaDescription =
      'Uzyskaj dostęp do pełnej dokumentacji, operatów szacunkowych i umów najmu';
  static const String vdrCtaDescriptionSidebar =
      'Zobacz pełną dokumentację, operaty i umowy najmu';
  static const String vdrCtaAction = 'Wyślij Proof of Funds →';

  // Akcje
  static const String addListing = 'Dodaj ogłoszenie';
  static const String addListingSemantic = 'Dodaj nowe ogłoszenie';

  // Karty sekcji (nazwy)
  static const String sectionMyListings = 'Moje ogłoszenia';
  static const String sectionMySubmissions = 'Moje zgłoszenia';
  static const String sectionFavorites = 'Zapisane oferty';
  static const String sectionFavoritesAlt = 'Ulubione';
  static const String sectionAlerts = 'Zapisane wyszukiwania';
  static const String sectionMessages = 'Wiadomości';
  static const String sectionStatistics = 'Statystyki';
  static const String sectionSettings = 'Ustawienia';
  static const String sectionAdminOverview = 'Przegląd całego systemu';
  static const String sectionAdminSubmissions = 'Oczekujące (Chcę sprzedać)';
  static const String sectionAdminUsers = 'Użytkownicy';
  static const String sectionAdminLogs = 'Logi systemowe';

  // Karty inwestora (quick actions)
  static const String cardNewListings = 'Nowe oferty';
  static const String cardSavedListings = 'Zapisane oferty';
  static const String cardMessages = 'Wiadomości';
  static const String actionSeeAll = 'Zobacz wszystkie';
  static const String actionManage = 'Zarządzaj';
  static const String actionSeeMessages = 'Zobacz wiadomości';
  static const String emptyFavorites = 'Brak zapisanych ofert';
  static const String favoritesCountLabel = 'ofert w ulubionych';
  /// Placeholder w karcie „Nowe oferty”, gdy brak ofert w zadanym przedziale dni.
  static String emptyNewListings(int days) =>
      'Brak nowych ofert w ostatnich $days dniach';

  // Sidebar inwestora (ostatnio oglądane / kryteria)
  static const String sidebarRecentlyViewed = 'Ostatnio oglądane';
  static const String sidebarYourCriteria = 'Twoje kryteria';
  static const String sidebarBackToListings = 'Wróć do ofert';
  static const String sidebarEditPreferences = 'Edytuj preferencje';

  // Wartość „brak” w sekcjach
  static const String valueDash = '—';

  // Domyślna nazwa użytkownika (fallback)
  static const String defaultDisplayName = 'Użytkownik';
}
