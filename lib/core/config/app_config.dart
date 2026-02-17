/// Application configuration
class AppConfig {
  // App info
  static const String appName = 'BC Agencja';
  static const String appVersion = '1.0.0';
  
  // API configuration
  static const String apiBaseUrl = 'https://api.bcagencja.pl'; // Replace with actual API URL
  static const String apiVersion = 'v1';
  /// Cloud Function proxy dla API WL (NIP) – unika CORS na web.
  /// Po deploy: https://europe-west1-bc-agencja.cloudfunctions.net/searchNip
  static const String wlApiProxyUrl = 'https://europe-west1-bc-agencja.cloudfunctions.net/searchNip';

  /// Cloud Function: pobranie PDF z VDR z dynamicznym znakiem wodnym (kto, data, IP).
  /// GET z Bearer tokenem; parametry: listingId, documentPath.
  static const String getDocumentWithWatermarkUrl =
      'https://europe-west1-bc-agencja.cloudfunctions.net/getDocumentWithWatermark';

  /// Cloud Function: wysłanie kalkulacji ROI na podany adres e-mail.
  /// POST, body: { "email": string, "subject": string, "body": string }.
  static const String sendRoiCalculationEmailUrl =
      'https://europe-west1-bc-agencja.cloudfunctions.net/sendRoiCalculationEmail';
  
  // Map configuration
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY'; // Replace with actual key
  
  // Pagination
  static const int listingsPerPage = 20;
  static const int searchResultsPerPage = 24;

  /// Oferty dodane (lub opublikowane) w ostatnich N dniach traktowane są jako „nowe” na dashboardzie.
  static const int newListingsMaxAgeDays = 14;
  /// Maksymalna liczba ofert w podglądzie „Nowe oferty” na dashboardzie.
  static const int newListingsPreviewMaxCount = 5;
  /// Maksymalna liczba pozycji w „Ostatnio oglądane” (Firestore).
  static const int recentlyViewedMaxCount = 20;

  // Image configuration
  static const int maxImagesPerListing = 20;
  static const int minImagesPerListing = 1;
  static const int maxImageSizeMB = 5;
  
  // Cache configuration
  static const Duration cacheDuration = Duration(hours: 24);
  static const Duration searchCacheDuration = Duration(hours: 1);
  
  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(seconds: 60);
  
  // Contact configuration
  static const String supportEmail = 'support@bcagencja.pl';
  static const String contactEmail = 'kontakt@bcagencja.pl';
  static const String supportPhone = '+48 123 456 789';
  /// Administrator danych osobowych (RODO).
  static const String dataControllerName = 'BC Agencja';
  /// Wersja NDA do logowania akceptacji.
  static const String ndaVersion = 'v1.0';
  /// Link do polityki prywatności.
  static const String privacyPolicyUrl = '/polityka-prywatnosci';
  /// Link do regulaminu.
  static const String termsUrl = '/regulamin';
  
  // Social media (optional)
  static const String facebookUrl = 'https://facebook.com/bcagencja';
  static const String instagramUrl = 'https://instagram.com/bcagencja';
  
  // Feature flags
  static const bool enableDarkMode = true;
  static const bool enableMapView = true;
  static const bool enableVirtualTours = true;
  static const bool enableChat = true;
  
  // reCAPTCHA Enterprise (App Check) – klucz z Google Cloud Console
  // Utwórz klucz typu Website (reCAPTCHA Enterprise) i zarejestruj w Firebase App Check
  static const String recaptchaEnterpriseSiteKey = 'YOUR_RECAPTCHA_ENTERPRISE_SITE_KEY';

  // Validation
  static const int minDescriptionLength = 50;
  static const int maxDescriptionLength = 2000;
  static const int minPrice = 0;
  static const int maxPrice = 10000000;
  static const double minArea = 10;
  static const double maxArea = 10000;
}
