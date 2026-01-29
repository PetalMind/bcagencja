class ListingFormData {
  // Step 1: Type and Location (wymagane: transactionType, propertyType, city)
  String? transactionType; // 'sale' or 'rent'
  String? propertyType; // commercial: 'office', 'warehouse', 'retail', 'industrial', 'hotel', 'land'
  String? city;
  String? district; // opcjonalne
  String? street; // opcjonalne
  double? latitude;
  double? longitude;

  // Step 2: Basic Info (wymagane: price, area, rooms)
  double? price;
  double? area;
  int? rooms;
  int? floor;
  int? yearBuilt;
  String? condition;

  // Step 3: Details (wymagane: description min. 50 znaków)
  List<String> amenities = [];
  String? heating;
  String? description;

  // Step 4: Photos (wymagane: min. 1 zdjęcie)
  List<String> images = [];

  // Step 5: Contact (wymagane: contactName, contactPhone, contactEmail)
  String? contactName;
  String? contactPhone;
  String? contactEmail;
  String? preferredContactTime;

  // Step 6: Package (wymagane: package, acceptedTerms)
  String? package; // 'basic' or 'promoted'
  bool acceptedTerms = false;

  ListingFormData();

  bool isStep1Valid() {
    return transactionType != null &&
        propertyType != null &&
        city != null &&
        city!.trim().isNotEmpty;
  }
  
  bool isStep2Valid() {
    return price != null && 
           area != null && 
           rooms != null;
  }
  
  bool isStep3Valid() {
    return description != null && 
           description!.length >= 50;
  }
  
  bool isStep4Valid() {
    return images.isNotEmpty;
  }
  
  bool isStep5Valid() {
    return contactName != null &&
        contactName!.trim().isNotEmpty &&
        contactPhone != null &&
        contactPhone!.trim().isNotEmpty &&
        contactEmail != null &&
        contactEmail!.trim().isNotEmpty;
  }
  
  bool isStep6Valid() {
    return package != null && acceptedTerms;
  }

  /// Zwraca mapę: klucz pola → komunikat błędu (null = brak błędu).
  /// Używane do wyświetlania errorText w polach formularza.
  Map<String, String?> validationErrorsForStep1() {
    final errors = <String, String?>{};
    if (transactionType == null || transactionType!.isEmpty) {
      errors['transactionType'] = 'Wybierz typ transakcji';
    } else {
      errors['transactionType'] = null;
    }
    if (propertyType == null || propertyType!.isEmpty) {
      errors['propertyType'] = 'Wybierz typ nieruchomości';
    } else {
      errors['propertyType'] = null;
    }
    if (city == null || city!.trim().isEmpty) {
      errors['city'] = 'Podaj miasto';
    } else {
      errors['city'] = null;
    }
    return errors;
  }
}
