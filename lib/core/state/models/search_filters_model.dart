/// Status oferty: na sprzedaż, w negocjacji, sprzedane (dla analiz porównawczych)
enum ListingStatus { forSale, inNegotiation, sold }

/// Sortowanie wyników
enum SearchSortBy { price, date, area, popularity }

/// Sentinel: pomiń pole w copyWith (zachowaj obecną wartość). Przekazanie null ustawia pole na null.
const _omit = _Omit();
class _Omit {
  const _Omit();
}

class SearchFilters {
  final String? location;
  final String? city;
  final String? district;
  final String? postalCode;
  final String? voivodeship;
  final List<String> selectedCities; // wiele obszarów jednocześnie
  final double? minPrice;
  final double? maxPrice;
  final String? propertyType; // 'office', 'warehouse', 'retail', 'industrial', 'hotel', 'land'
  final List<String> propertyTypes; // wiele typów (podkategorie)
  final String? transactionType; // 'sale', 'rent'
  final double? minArea;
  final double? maxArea;
  final double? minPlotArea; // pow. działki m²
  final double? maxPlotArea;
  final String? listingStatus; // 'for_sale', 'in_negotiation', 'sold'
  final String? keyword; // wyszukiwanie słowne/frazowe w opisach
  final int? minRooms;
  final int? maxRooms;
  final int? minFloor;
  final int? maxFloor;
  final int? minYearBuilt;
  final int? maxYearBuilt;
  final List<String> amenities;
  final bool? hasBalcony;
  final bool? hasParking;
  final bool? hasElevator;
  final bool? hasGarden;
  final bool? hasLoadingDock;
  final bool? hasSecurity;
  final bool? hasReception;
  final double? minCeilingHeight;
  final double? minFloorLoadCapacity; // nośność posadzki (t/m²)
  final String? buildingClass; // klasa budynku: A+, A, B+, B, C
  final int? minParkingSpaces;
  final double? minElectricalPower; // moc przyłączeniowa (kW)
  final bool onlyVerified;
  final bool onlyWithPhotos;
  final bool fromOwner;
  final bool withVirtualTour;
  final String? sortBy; // 'price', 'date', 'area', 'popularity'
  final String? sortOrder; // 'asc', 'desc'

  SearchFilters({
    this.location,
    this.city,
    this.district,
    this.postalCode,
    this.voivodeship,
    this.selectedCities = const [],
    this.minPrice,
    this.maxPrice,
    this.propertyType,
    this.propertyTypes = const [],
    this.transactionType,
    this.minArea,
    this.maxArea,
    this.minPlotArea,
    this.maxPlotArea,
    this.listingStatus,
    this.keyword,
    this.minRooms,
    this.maxRooms,
    this.minFloor,
    this.maxFloor,
    this.minYearBuilt,
    this.maxYearBuilt,
    this.amenities = const [],
    this.hasBalcony,
    this.hasParking,
    this.hasElevator,
    this.hasGarden,
    this.hasLoadingDock,
    this.hasSecurity,
    this.hasReception,
    this.minCeilingHeight,
    this.minFloorLoadCapacity,
    this.buildingClass,
    this.minParkingSpaces,
    this.minElectricalPower,
    this.onlyVerified = false,
    this.onlyWithPhotos = false,
    this.fromOwner = false,
    this.withVirtualTour = false,
    this.sortBy,
    this.sortOrder,
  });
  
  SearchFilters copyWith({
    Object? location = _omit,
    Object? city = _omit,
    Object? district = _omit,
    Object? postalCode = _omit,
    Object? voivodeship = _omit,
    List<String>? selectedCities,
    Object? minPrice = _omit,
    Object? maxPrice = _omit,
    Object? propertyType = _omit,
    List<String>? propertyTypes,
    Object? transactionType = _omit,
    Object? minArea = _omit,
    Object? maxArea = _omit,
    Object? minPlotArea = _omit,
    Object? maxPlotArea = _omit,
    Object? listingStatus = _omit,
    Object? keyword = _omit,
    int? minRooms,
    int? maxRooms,
    int? minFloor,
    int? maxFloor,
    int? minYearBuilt,
    int? maxYearBuilt,
    List<String>? amenities,
    bool? hasBalcony,
    bool? hasParking,
    bool? hasElevator,
    bool? hasGarden,
    bool? hasLoadingDock,
    bool? hasSecurity,
    bool? hasReception,
    double? minCeilingHeight,
    double? minFloorLoadCapacity,
    Object? buildingClass = _omit,
    int? minParkingSpaces,
    double? minElectricalPower,
    bool? onlyVerified,
    bool? onlyWithPhotos,
    bool? fromOwner,
    bool? withVirtualTour,
    Object? sortBy = _omit,
    Object? sortOrder = _omit,
  }) {
    T? pick<T>(Object? v, T? current) => identical(v, _omit) ? current : v as T?;
    return SearchFilters(
      location: pick(location, this.location),
      city: pick(city, this.city),
      district: pick(district, this.district),
      postalCode: pick(postalCode, this.postalCode),
      voivodeship: pick(voivodeship, this.voivodeship),
      selectedCities: selectedCities ?? this.selectedCities,
      minPrice: pick(minPrice, this.minPrice),
      maxPrice: pick(maxPrice, this.maxPrice),
      propertyType: pick(propertyType, this.propertyType),
      propertyTypes: propertyTypes ?? this.propertyTypes,
      transactionType: pick(transactionType, this.transactionType),
      minArea: pick(minArea, this.minArea),
      maxArea: pick(maxArea, this.maxArea),
      minPlotArea: pick(minPlotArea, this.minPlotArea),
      maxPlotArea: pick(maxPlotArea, this.maxPlotArea),
      listingStatus: pick(listingStatus, this.listingStatus),
      keyword: pick(keyword, this.keyword),
      minRooms: minRooms ?? this.minRooms,
      maxRooms: maxRooms ?? this.maxRooms,
      minFloor: minFloor ?? this.minFloor,
      maxFloor: maxFloor ?? this.maxFloor,
      minYearBuilt: minYearBuilt ?? this.minYearBuilt,
      maxYearBuilt: maxYearBuilt ?? this.maxYearBuilt,
      amenities: amenities ?? this.amenities,
      hasBalcony: hasBalcony ?? this.hasBalcony,
      hasParking: hasParking ?? this.hasParking,
      hasElevator: hasElevator ?? this.hasElevator,
      hasGarden: hasGarden ?? this.hasGarden,
      hasLoadingDock: hasLoadingDock ?? this.hasLoadingDock,
      hasSecurity: hasSecurity ?? this.hasSecurity,
      hasReception: hasReception ?? this.hasReception,
      minCeilingHeight: minCeilingHeight ?? this.minCeilingHeight,
      minFloorLoadCapacity: minFloorLoadCapacity ?? this.minFloorLoadCapacity,
      buildingClass: pick(buildingClass, this.buildingClass),
      minParkingSpaces: minParkingSpaces ?? this.minParkingSpaces,
      minElectricalPower: minElectricalPower ?? this.minElectricalPower,
      onlyVerified: onlyVerified ?? this.onlyVerified,
      onlyWithPhotos: onlyWithPhotos ?? this.onlyWithPhotos,
      fromOwner: fromOwner ?? this.fromOwner,
      withVirtualTour: withVirtualTour ?? this.withVirtualTour,
      sortBy: pick(sortBy, this.sortBy),
      sortOrder: pick(sortOrder, this.sortOrder),
    );
  }

  /// Wszystkie wybrane typy nieruchomości (propertyType + propertyTypes)
  List<String> get effectivePropertyTypes {
    final list = <String>[];
    if (propertyType != null && propertyType!.isNotEmpty) list.add(propertyType!);
    list.addAll(propertyTypes.where((t) => t.isNotEmpty));
    return list.toSet().toList();
  }

  int get activeFiltersCount {
    int count = 0;
    if (location != null && location!.isNotEmpty) count++;
    if (city != null && city!.isNotEmpty) count++;
    if (district != null && district!.isNotEmpty) count++;
    if (postalCode != null && postalCode!.isNotEmpty) count++;
    if (voivodeship != null && voivodeship!.isNotEmpty) count++;
    if (selectedCities.isNotEmpty) count++;
    if ((minPrice != null && minPrice! > 0) || (maxPrice != null && maxPrice! > 0)) count++;
    if (propertyType != null && propertyType!.isNotEmpty) count++;
    if (propertyTypes.isNotEmpty) count++;
    if (transactionType != null) count++;
    if (minArea != null || maxArea != null) count++;
    if (minPlotArea != null || maxPlotArea != null) count++;
    if (listingStatus != null && listingStatus!.isNotEmpty) count++;
    if (keyword != null && keyword!.isNotEmpty) count++;
    if (minRooms != null || maxRooms != null) count++;
    if (amenities.isNotEmpty) count++;
    if (onlyVerified) count++;
    if (onlyWithPhotos) count++;
    if (fromOwner) count++;
    if (hasLoadingDock == true || hasSecurity == true || hasReception == true) count++;
    if (minCeilingHeight != null) count++;
    if (minFloorLoadCapacity != null) count++;
    if (buildingClass != null && buildingClass!.isNotEmpty) count++;
    if (minParkingSpaces != null) count++;
    if (minElectricalPower != null) count++;
    return count;
  }

  bool get hasActiveFilters => activeFiltersCount > 0;
}
