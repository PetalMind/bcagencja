import '../../core/services/submission_document_service.dart';

/// Pojedynczy wpis najemcy (nazwa, termin umowy, czynsz).
class TenantEntry {
  String name;
  DateTime? leaseUntil;
  double? monthlyRent;

  TenantEntry({this.name = '', this.leaseUntil, this.monthlyRent});

  Map<String, Object?> toJson() => {
    'name': name.trim().isEmpty ? null : name.trim(),
    'leaseUntil': leaseUntil != null ? DateTime(leaseUntil!.year, leaseUntil!.month, leaseUntil!.day) : null,
    'monthlyRent': monthlyRent,
  };

}

/// Model zgłoszenia "Chcę sprzedać" – lead magnet (6-krokowy wizard).
/// Zapis do Firestore `listing_submissions` ze statusem `pending` (Oczekiwanie).
class ListingSubmissionData {
  // Krok 1: Typ nieruchomości
  /// retail, office, land, warehouse, under_construction, unsure
  String? propertyType;

  // Krok 2: Lokalizacja – pola adresowe (standard Poczty Polskiej)
  /// Ulica – typ i nazwa (np. "ul. Piotrkowska")
  String? street;
  /// Numer domu
  String? buildingNumber;
  /// Numer lokalu/mieszkania (opcjonalne)
  String? apartmentNumber;
  /// Kod pocztowy XX-XXX
  String? postalCode;
  /// Miejscowość (WIELKIMI LITERAMI)
  String? locality;
  String? voivodeship;
  /// Pełny adres z Google Places (gdy wybrano z autocomplete) – do kompatybilności.
  String? formattedAddress;
  double? latitude;
  double? longitude;
  /// Nie publikować dokładnego adresu – pokazywać tylko rejon (off-market).
  bool hideExactAddress = true;
  /// Miasto – alias dla locality (kompatybilność wsteczna).
  String? get city => locality;
  set city(String? v) => locality = v;

  // Krok 3: Podstawowe dane (conditional)
  double? area; // m² GLA lub powierzchnia działki
  /// Dla nieruchomości: long_term, short_term, vacant
  String? tenantType;
  /// Przeznaczenie lokalu: gastronomiczny, biurowy, handlowy, usługowy (multi-select)
  List<String> designation = [];
  /// Informacje dodatkowe – wybór z listy (multi-select)
  List<String> additionalInfo = [];
  /// Lista najemców (może być np. 4 najemców w jednej lokalizacji).
  List<TenantEntry> tenants = [];
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
  /// Lista załączników – każdy ma nazwę do wyświetlenia i ścieżkę w Storage.
  List<SubmissionAttachment> attachments = [];

  /// Nazwy załączników (do kompatybilności / wyświetlania).
  List<String> get attachmentNames => attachments.map((a) => a.displayName).toList();

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

  static final _postalCodeRegex = RegExp(r'^\d{2}-\d{3}$');

  bool get isStep2Valid {
    if (street == null || street!.trim().isEmpty) return false;
    if (buildingNumber == null || buildingNumber!.trim().isEmpty) return false;
    if (postalCode == null || !_postalCodeRegex.hasMatch(postalCode!.trim())) return false;
    if (locality == null || locality!.trim().isEmpty) return false;
    return true;
  }

  bool get isStep3Valid {
    if (propertyType == null) return false;
    if (propertyType == 'land') {
      return area != null && area! > 0;
    }
    return area != null && area! > 0;
  }

  bool get isStep4Valid =>
      (expectedPrice != null && expectedPrice! > 0) ||
      (priceFlexibility != null && priceFlexibility!.isNotEmpty);

  bool get isStep5Valid => true;

  static final _emailRegex = RegExp(r'^[\w\-+.]+@[\w\-]+(\.[\w\-]+)+$');

  bool get isStep6Valid {
    if (contactName == null || contactName!.trim().isEmpty) return false;
    if (contactEmail == null || contactEmail!.trim().isEmpty) return false;
    if (!_emailRegex.hasMatch(contactEmail!.trim())) return false;
    if (contactPhone == null || contactPhone!.trim().isEmpty) return false;
    return acceptedPrivacy && acceptedContact;
  }

  /// Suma czynszów wszystkich najemców (PLN netto/mies.).
  double get totalMonthlyRent => tenants
      .where((t) => t.monthlyRent != null && t.monthlyRent! > 0)
      .map((t) => t.monthlyRent!)
      .fold<double>(0, (a, b) => a + b);

  /// Szacunkowa wartość (cap rate ~8%) dla lokalu z najemcami.
  double? get estimatedValueFromRent {
    final total = totalMonthlyRent;
    if (total <= 0) return null;
    const capRate = 0.08;
    return (total * 12) / capRate;
  }

  /// Przedział szacunkowy ±15%
  (double, double)? get estimatedRangeFromRent {
    final v = estimatedValueFromRent;
    if (v == null) return null;
    return (v * 0.85, v * 1.15);
  }

  /// Kopiuje wartości z innego obiektu (np. do podglądu zgłoszenia).
  void copyFrom(ListingSubmissionData other) {
    propertyType = other.propertyType;
    street = other.street;
    buildingNumber = other.buildingNumber;
    apartmentNumber = other.apartmentNumber;
    postalCode = other.postalCode;
    locality = other.locality;
    voivodeship = other.voivodeship;
    formattedAddress = other.formattedAddress;
    latitude = other.latitude;
    longitude = other.longitude;
    hideExactAddress = other.hideExactAddress;
    area = other.area;
    tenantType = other.tenantType;
    tenants = other.tenants
        .map((t) => TenantEntry(name: t.name, leaseUntil: t.leaseUntil, monthlyRent: t.monthlyRent))
        .toList();
    designation = List.from(other.designation);
    additionalInfo = List.from(other.additionalInfo);
    mpzp = other.mpzp;
    utilities = List.from(other.utilities);
    estimatedValueMin = other.estimatedValueMin;
    estimatedValueMax = other.estimatedValueMax;
    expectedPrice = other.expectedPrice;
    priceFlexibility = other.priceFlexibility;
    description = other.description;
    attachments = other.attachments
        .map((a) => SubmissionAttachment(displayName: a.displayName, storagePath: a.storagePath, downloadUrl: a.downloadUrl))
        .toList();
    contactName = other.contactName;
    contactEmail = other.contactEmail;
    contactPhone = other.contactPhone;
    preferredContactTime = other.preferredContactTime;
    contactByEmail = other.contactByEmail;
    contactByPhone = other.contactByPhone;
    contactByWhatsApp = other.contactByWhatsApp;
    acceptedPrivacy = other.acceptedPrivacy;
    acceptedContact = other.acceptedContact;
  }

  Map<String, Object?> toFirestore() {
    return {
      'status': 'pending',
      'source': 'chce-sprzedac',
      'propertyType': propertyType,
      'street': street?.trim().isEmpty == true ? null : street?.trim(),
      'buildingNumber': buildingNumber?.trim().isEmpty == true ? null : buildingNumber?.trim(),
      'apartmentNumber': apartmentNumber?.trim().isEmpty == true ? null : apartmentNumber?.trim(),
      'postalCode': postalCode?.trim().isEmpty == true ? null : postalCode?.trim(),
      'city': locality?.trim().isEmpty == true ? null : locality?.trim(),
      'locality': locality?.trim().isEmpty == true ? null : locality?.trim(),
      'voivodeship': voivodeship?.trim().isEmpty == true ? null : voivodeship?.trim(),
      'formattedAddress': formattedAddress?.trim().isEmpty == true ? null : formattedAddress?.trim(),
      'latitude': latitude,
      'longitude': longitude,
      'hideExactAddress': hideExactAddress,
      'area': area,
      'tenantType': tenantType?.trim().isEmpty == true ? null : tenantType,
      'tenants': tenants.where((t) => t.name.trim().isNotEmpty).isEmpty
          ? null
          : tenants.where((t) => t.name.trim().isNotEmpty).map((t) => t.toJson()).toList(),
      'designation': designation.isEmpty ? null : designation,
      'additionalInfo': additionalInfo.isEmpty ? null : additionalInfo,
      'mpzp': mpzp?.trim().isEmpty == true ? null : mpzp,
      'utilities': utilities.isEmpty ? null : utilities,
      'estimatedValueMin': estimatedValueMin,
      'estimatedValueMax': estimatedValueMax,
      'expectedPrice': expectedPrice,
      'priceFlexibility': priceFlexibility?.trim().isEmpty == true ? null : priceFlexibility,
      'attachmentNames': attachmentNames.isEmpty ? null : attachmentNames,
      'attachments': attachments.isEmpty
          ? null
          : attachments.map((a) => a.toJson()).toList(),
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
