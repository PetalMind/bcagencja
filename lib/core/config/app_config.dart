/// Application configuration
class AppConfig {
  // App info
  static const String appName = 'BC Agencja';
  static const String appVersion = '1.0.0';
  
  // API configuration
  static const String apiBaseUrl = 'https://api.bcagencja.pl'; // Replace with actual API URL
  static const String apiVersion = 'v1';
  
  // Map configuration
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY'; // Replace with actual key
  
  // Pagination
  static const int listingsPerPage = 20;
  static const int searchResultsPerPage = 24;
  
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
  static const String supportPhone = '+48 123 456 789';
  
  // Social media (optional)
  static const String facebookUrl = 'https://facebook.com/bcagencja';
  static const String instagramUrl = 'https://instagram.com/bcagencja';
  
  // Feature flags
  static const bool enableDarkMode = true;
  static const bool enableMapView = true;
  static const bool enableVirtualTours = true;
  static const bool enableChat = true;
  
  // Validation
  static const int minDescriptionLength = 50;
  static const int maxDescriptionLength = 2000;
  static const int minPrice = 0;
  static const int maxPrice = 10000000;
  static const double minArea = 10;
  static const double maxArea = 10000;
}
