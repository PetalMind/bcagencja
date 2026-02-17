/// Model zgłoszenia "Chcę sprzedać" – lead magnet.
/// Zapis do Firestore `listing_submissions` ze statusem `pending` (Oczekiwanie).
class ListingSubmissionData {
  /// Typ: nieruchomość komercyjna lub grunt
  String? assetType; // 'property' | 'land'

  /// Lokalizacja
  String? city;
  String? voivodeship;
  String? description;

  /// Kontakt (wymagane)
  String? contactName;
  String? contactEmail;
  String? contactPhone;
  String? preferredContactTime;

  ListingSubmissionData();

  bool get isStep1Valid =>
      assetType != null &&
      city != null &&
      city!.trim().isNotEmpty;

  bool get isStep2Valid =>
      contactName != null &&
      contactName!.trim().isNotEmpty &&
      contactEmail != null &&
      contactEmail!.trim().isNotEmpty &&
      contactPhone != null &&
      contactPhone!.trim().isNotEmpty;

  /// Mapowanie do dokumentu Firestore (bez id – ustawiane przy zapisie).
  Map<String, Object?> toFirestore() {
    return {
      'status': 'pending',
      'source': 'chce-sprzedac',
      'assetType': assetType,
      'city': city?.trim(),
      'voivodeship': voivodeship?.trim().isEmpty == true ? null : voivodeship?.trim(),
      'description': description?.trim().isEmpty == true ? null : description?.trim(),
      'contactName': contactName?.trim(),
      'contactEmail': contactEmail?.trim(),
      'contactPhone': contactPhone?.trim(),
      'preferredContactTime': preferredContactTime?.trim().isEmpty == true
          ? null
          : preferredContactTime?.trim(),
      'createdAt': null, // FieldValue.serverTimestamp() w serwisie
    };
  }
}
