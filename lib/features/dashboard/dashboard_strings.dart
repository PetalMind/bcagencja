/// Stałe teksty widoku panelu użytkownika (dashboard).
/// Używane zamiast literałów w dashboard_page.dart i powiązanych widgetach.
class DashboardStrings {
  DashboardStrings._();

  // Nagłówek – personalizowany
  static const String titleShort = 'Panel użytkownika';
  static const String titleLong = 'Witaj w panelu użytkownika';
  /// Powitanie z imieniem: "Cześć, Jan" / "Witaj, Jan"
  static String greetingWithName(String firstName) => 'Cześć, $firstName';
  static const String subtitle = 'Zarządzaj ogłoszeniami, ulubionymi i wiadomościami';
  static const String subtitleVerified = 'Masz dostęp do pełnych ofert – przeglądaj, porównuj i inwestuj';
  static const String subtitleUnverified = 'Dokończ weryfikację, aby odblokować pełne oferty i lokalizacje';

  // Sekcje
  static const String sectionLabelAgent = 'Panel Agenta';
  static const String sectionLabelInvestor = 'Panel Inwestora';

  // Szybkie wyszukiwanie
  static const String searchPlaceholder = 'Szukaj według lokalizacji, typu, najemcy...';
  static const String searchSemanticLabel = 'Szybkie wyszukiwanie nieruchomości';

  // —— Niezweryfikowany użytkownik (Level 1) ——
  static const String unverifiedTitle = 'Dokończ weryfikację konta';
  static const String unverifiedSubtitle = 'Odkryj pełne oferty – lokalizacje, zdjęcia i szczegóły';
  static const String unverifiedStep1 = 'Zweryfikuj tożsamość (NIP lub LinkedIn)';
  static const String unverifiedStep2 = 'Zaakceptuj regulamin i NDA';
  static const String unverifiedStep3 = 'Zobacz pełne oferty i zacznij inwestować';
  static const String unverifiedBenefit1 = 'Pełne adresy i lokalizacje na mapie';
  static const String unverifiedBenefit2 = 'Galeria zdjęć i dokumenty';
  static const String unverifiedBenefit3 = 'Szczegółowe parametry i ceny';
  static const String unverifiedCta = 'Zweryfikuj konto – to zajmie chwilę';
  static const String verifyCtaNda = 'Zaakceptuj NDA, aby odblokować pełne oferty';
  static const String verifyCtaIdentity = 'Zweryfikuj konto – zobacz pełne oferty (lokalizacja, galeria)';

  // —— Zweryfikowany użytkownik (Level 2) ——
  static const String verifiedBadge = 'Konto zweryfikowane';
  static const String verifiedBadgeShort = 'Zweryfikowany';

  // VDR CTA (Level 2 → Level 3)
  static const String vdrCtaTitle = 'ODBLOKUJ VDR';
  static const String vdrCtaTitleSidebar = 'ODBLOKUJ VDR ACCESS';
  static const String vdrCtaDescription =
      'Uzyskaj dostęp do pełnej dokumentacji, operatów szacunkowych i umów najmu';
  static const String vdrCtaDescriptionSidebar =
      'Zobacz pełną dokumentację, operaty i umowy najmu';
  static const String vdrCtaAction = 'Wyślij Proof of Funds →';

  // Zachęty do działania (CTA)
  static const String ctaBrowseListings = 'Przeglądaj oferty';
  static const String ctaBrowseListingsDesc = 'Oferty dopasowane do Twoich kryteriów';
  static const String ctaRoiCalculator = 'Kalkulator ROI';
  static const String ctaRoiCalculatorDesc = 'Oblicz zwrot z inwestycji';
  static const String ctaWantToSell = 'Chcesz sprzedać?';
  static const String ctaWantToSellDesc = 'Zgłoś nieruchomość – skontaktujemy się z Tobą';
  static const String ctaForYou = 'Dla Ciebie';
  static const String ctaSetPreferences = 'Ustaw preferencje (budżet, typ) – pokażemy oferty dopasowane do Ciebie';

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

  /// Imię do powitania (displayName pierwszy token lub email prefix).
  static String firstName(String? displayName, String? email) {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) return name.split(' ').first;
    final prefix = email?.split('@').first;
    return prefix != null && prefix.isNotEmpty ? prefix : 'Użytkowniku';
  }

  // ——————————————————————————————————————————
  // Tutorial coach mark – po pierwszym logowaniu
  // ——————————————————————————————————————————

  // Wspólne
  static const String tutorialSkip = 'Pomiń';
  static const String tutorialNext = 'Dalej';
  static const String tutorialDone = 'Gotowe';

  // ── Level 1 (investorBasic) ──────────────────────────────
  static const String tutorialL1WelcomeTitle = 'Witaj w panelu inwestora';
  static const String tutorialL1WelcomeDesc =
      'To Twoje centrum zarządzania. Zaraz pokażemy Ci, jak zacząć.';

  static const String tutorialL1VerifyTitle = '⚠️ Krok 1 – Zweryfikuj konto';
  static const String tutorialL1VerifyDesc =
      'To najważniejszy krok. Po weryfikacji odblokujesz pełne adresy, zdjęcia i dokumenty ofert. Zajmuje to dosłownie chwilę.';

  static const String tutorialL1SearchTitle = 'Już teraz przeglądaj teasery';
  static const String tutorialL1SearchDesc =
      'Możesz szukać ofert przed weryfikacją – zobaczysz parametry finansowe i typ nieruchomości.';

  static const String tutorialL1CardsTitle = 'Po weryfikacji tu ożyje panel';
  static const String tutorialL1CardsDesc =
      'Nowe oferty, ulubione i wiadomości – te sekcje napełnią się danymi, gdy odblokujesz konto.';

  // ── Level 2 (investorVerified) ───────────────────────────
  static const String tutorialL2WelcomeTitle = 'Pełny dostęp odblokowany';
  static const String tutorialL2WelcomeDesc =
      'Widzisz teraz pełne oferty z lokalizacją, galerią i dokumentacją. Pokażemy Ci, jak efektywnie korzystać z panelu.';

  static const String tutorialL2CtaTitle = 'Trzy szybkie drogi działania';
  static const String tutorialL2CtaDesc =
      'Przeglądaj oferty, sprawdź Kalkulator ROI lub zgłoś nieruchomość do sprzedaży.';

  static const String tutorialL2SearchTitle = 'Szukaj ofert błyskawicznie';
  static const String tutorialL2SearchDesc =
      'Wpisz lokalizację, typ nieruchomości lub nazwę najemcy – trafisz prosto do wyników.';

  static const String tutorialL2NewListingsTitle = 'Świeże oferty na start';
  static const String tutorialL2NewListingsDesc =
      'Tu wyświetlamy oferty dodane w ostatnich dniach – przeglądaj, zanim zrobi to ktoś inny.';

  static const String tutorialL2FavoritesTitle = 'Zapisuj i porównuj oferty';
  static const String tutorialL2FavoritesDesc =
      'Kliknij serce na ofercie, żeby ją zapisać. Tu znajdziesz wszystkie ulubione do spokojnej analizy.';

  static const String tutorialL2CriteriaTitle = 'Twoje kryteria inwestycyjne';
  static const String tutorialL2CriteriaDesc =
      'Ustaw budżet i typ preferowanych nieruchomości – system wyfiltruje oferty specjalnie dla Ciebie.';

  // ── Level 4+ (agent / director) ─────────────────────────
  static const String tutorialAgentWelcomeTitle = 'Witaj w Panelu Agenta';
  static const String tutorialAgentWelcomeDesc =
      'Stąd zarządzasz swoim portfolio ofert, statystykami i klientami. Szybki przegląd możliwości.';

  static const String tutorialAgentAddListingTitle = 'Dodaj pierwsze ogłoszenie';
  static const String tutorialAgentAddListingDesc =
      'Kliknij, aby przesłać nieruchomość do bazy. Ogłoszenie trafi do moderacji i po zatwierdzeniu pojawi się na stronie.';

  static const String tutorialAgentSearchTitle = 'Szukaj w bazie ofert';
  static const String tutorialAgentSearchDesc =
      'Sprawdzaj aktualne oferty, filtry i parametry – przydatne przy porównywaniu z własnym portfolio.';

  static const String tutorialAgentMyListingsTitle = 'Twoje ogłoszenia';
  static const String tutorialAgentMyListingsDesc =
      'Tu masz podgląd wszystkich dodanych przez Ciebie ofert – status, wyświetlenia, edycja.';

  static const String tutorialAgentStatsTitle = 'Śledź wyniki';
  static const String tutorialAgentStatsDesc =
      'Statystyki pokazują wyświetlenia i zainteresowanie Twoimi ofertami w czasie.';

  static const String tutorialAgentSettingsTitle = 'Uzupełnij profil agenta';
  static const String tutorialAgentSettingsDesc =
      'Dodaj zdjęcie, dane firmy i numer telefonu – zwiększy to wiarygodność Twoich ofert u inwestorów.';
}
