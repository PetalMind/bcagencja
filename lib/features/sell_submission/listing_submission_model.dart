/// Model zgłoszenia "Chcę sprzedać" – lead magnet (6-krokowy wizard).
/// Zapis do Firestore `listing_submissions` ze statusem `pending` (Oczekiwanie).
class ListingSubmissionData {
  // Krok 1: Typ nieruchomości
  /// retail, office, land, warehouse, under_construction, unsure
  String? propertyType;

  // Krok 2: Lokalizacja
  String? city;
  String? voivodeship;
  /// Pełny adres z Google Places (gdy wybrano z autocomplete).
  String? formattedAddress;
  double? latitude;
  double? longitude;

  // Krok 3: Podstawowe dane (conditional)
  double? area; // m² GLA lub powierzchnia działki
  /// Dla nieruchomości: long_term, short_term, vacant
  String? tenantType;
  String? tenantName;
  DateTime? leaseUntil;
  double? monthlyRent; // PLN netto
  /// Dla gruntu: zoning w MPZP
  String? mpzp;
  /// Dla gruntu: lista uzbrojeń (prąd, woda, kanalizacja, gaz, droga)
  List<String> utilities = [];

  // Krok 4: Cena
  double? estimatedValueMin;
  double? estimatedValueMax;
  double? expectedPrice;
  /// flexible, minimum, want_valuation
  String? priceFlexibility;

  // Krok 5: Dokumentacja (opcjonalnie)
  List<String> attachmentNames = [];

  // Krok 6: Kontakt
  String? contactName;
  String? contactEmail;
  String? contactPhone;
  String? preferredContactTime;
  bool contactByEmail = true;
  bool contactByPhone = false;
  bool contactByWhatsApp = false;
  bool acceptedPrivacy = false;
  bool acceptedContact = false;

  /// Opis (legacy / dodatkowy)
  String? description;

  ListingSubmissionData();

  bool get isStep1Valid => propertyType != null && propertyType!.isNotEmpty;

  bool get isStep2Valid =>
      city != null && city!.trim().isNotEmpty;

  bool get isStep3Valid {
    if (propertyType == null) return false;
    if (propertyType == 'land') {
      return area != null && area! > 0;
    }
    return area != null && area! > 0;
  }

  bool get isStep4Valid => true;

  bool get isStep5Valid => true;

  bool get isStep6Valid =>
      contactName != null &&
      contactName!.trim().isNotEmpty &&
      contactEmail != null &&
      contactEmail!.trim().isNotEmpty &&
      contactPhone != null &&
      contactPhone!.trim().isNotEmpty &&
      acceptedPrivacy &&
      acceptedContact;

  /// Szacunkowa wartość (cap rate ~8%) dla lokalu z najemcą.
  double? get estimatedValueFromRent {
    if (monthlyRent == null || monthlyRent! <= 0) return null;
    const capRate = 0.08;
    return (monthlyRent! * 12) / capRate;
  }

  /// Przedział szacunkowy ±15%
  (double, double)? get estimatedRangeFromRent {
    final v = estimatedValueFromRent;
    if (v == null) return null;
    return (v * 0.85, v * 1.15);
  }

  Map<String, Object?> toFirestore() {
    return {
      'status': 'pending',
      'source': 'chce-sprzedac',
      'propertyType': propertyType,
      'city': city?.trim(),
      'voivodeship': voivodeship?.trim().isEmpty == true ? null : voivodeship?.trim(),
      'formattedAddress': formattedAddress?.trim().isEmpty == true ? null : formattedAddress?.trim(),
      'latitude': latitude,
      'longitude': longitude,
      'area': area,
      'tenantType': tenantType?.trim().isEmpty == true ? null : tenantType,
      'tenantName': tenantName?.trim().isEmpty == true ? null : tenantName,
      'leaseUntil': leaseUntil != null ? DateTime(leaseUntil!.year, leaseUntil!.month, leaseUntil!.day) : null,
      'monthlyRent': monthlyRent,
      'mpzp': mpzp?.trim().isEmpty == true ? null : mpzp,
      'utilities': utilities.isEmpty ? null : utilities,
      'estimatedValueMin': estimatedValueMin,
      'estimatedValueMax': estimatedValueMax,
      'expectedPrice': expectedPrice,
      'priceFlexibility': priceFlexibility?.trim().isEmpty == true ? null : priceFlexibility,
      'attachmentNames': attachmentNames.isEmpty ? null : attachmentNames,
      'contactName': contactName?.trim(),
      'contactEmail': contactEmail?.trim(),
      'contactPhone': contactPhone?.trim(),
      'preferredContactTime': preferredContactTime?.trim().isEmpty == true ? null : preferredContactTime?.trim(),
      'contactByEmail': contactByEmail,
      'contactByPhone': contactByPhone,
      'contactByWhatsApp': contactByWhatsApp,
      'acceptedPrivacy': acceptedPrivacy,
      'acceptedContact': acceptedContact,
      'description': description?.trim().isEmpty == true ? null : description?.trim(),
      'createdAt': null,
    };
  }
}
