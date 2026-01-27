/// ARIA labels and accessibility strings for the application
class AriaLabels {
  // Navigation
  static const String navHome = 'Przejdź do strony głównej';
  static const String navSearch = 'Przejdź do wyszukiwarki';
  static const String navAddListing = 'Dodaj nowe ogłoszenie';
  static const String navDashboard = 'Przejdź do panelu użytkownika';
  static const String navFavorites = 'Pokaż ulubione oferty';
  static const String navProfile = 'Przejdź do profilu';
  static const String navMenu = 'Otwórz menu nawigacji';
  static const String navClose = 'Zamknij menu';
  static const String navBack = 'Wróć do poprzedniej strony';
  
  // Search
  static const String searchInput = 'Wpisz frazę wyszukiwania';
  static const String searchButton = 'Wyszukaj nieruchomości';
  static const String filterButton = 'Otwórz filtry wyszukiwania';
  static const String clearFilters = 'Wyczyść wszystkie filtry';
  static const String applyFilters = 'Zastosuj wybrane filtry';
  
  // Listings
  static const String listingCard = 'Karta oferty nieruchomości';
  static const String viewDetails = 'Zobacz szczegóły oferty';
  static const String addToFavorites = 'Dodaj do ulubionych';
  static const String removeFromFavorites = 'Usuń z ulubionych';
  static const String shareProperty = 'Udostępnij ofertę';
  
  // Forms
  static const String formRequired = 'To pole jest wymagane';
  static const String formInvalidEmail = 'Nieprawidłowy adres email';
  static const String formInvalidPhone = 'Nieprawidłowy numer telefonu';
  static const String formSubmit = 'Wyślij formularz';
  static const String formCancel = 'Anuluj i wróć';
  
  // Images
  static const String propertyImage = 'Zdjęcie nieruchomości';
  static const String profileImage = 'Zdjęcie profilowe użytkownika';
  static const String galleryImage = 'Zdjęcie z galerii';
  static const String thumbnailImage = 'Miniatura zdjęcia';
  
  // Actions
  static const String callOwner = 'Zadzwoń do właściciela';
  static const String sendMessage = 'Wyślij wiadomość';
  static const String scheduleViewing = 'Umów wizytę';
  static const String downloadPDF = 'Pobierz ofertę w PDF';
  
  // Accessibility hints
  static String propertyCardHint(String title, String price) {
    return 'Oferta: $title, cena: $price. Kliknij aby zobaczyć szczegóły.';
  }
  
  static String imageHint(int current, int total) {
    return 'Zdjęcie $current z $total';
  }
  
  static String filterActiveHint(int count) {
    return count == 1
        ? 'Aktywny $count filtr'
        : 'Aktywne $count filtry';
  }
}
