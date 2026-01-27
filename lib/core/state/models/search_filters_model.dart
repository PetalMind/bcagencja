class SearchFilters {
  final String? location;
  final String? city;
  final String? district;
  final double? minPrice;
  final double? maxPrice;
  final String? propertyType; // 'apartment', 'house', 'land', 'commercial'
  final String? transactionType; // 'sale', 'rent'
  final double? minArea;
  final double? maxArea;
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
  final bool onlyVerified;
  final bool onlyWithPhotos;
  final bool fromOwner;
  final bool withVirtualTour;
  
  SearchFilters({
    this.location,
    this.city,
    this.district,
    this.minPrice,
    this.maxPrice,
    this.propertyType,
    this.transactionType,
    this.minArea,
    this.maxArea,
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
    this.onlyVerified = false,
    this.onlyWithPhotos = false,
    this.fromOwner = false,
    this.withVirtualTour = false,
  });
  
  SearchFilters copyWith({
    String? location,
    String? city,
    String? district,
    double? minPrice,
    double? maxPrice,
    String? propertyType,
    String? transactionType,
    double? minArea,
    double? maxArea,
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
    bool? onlyVerified,
    bool? onlyWithPhotos,
    bool? fromOwner,
    bool? withVirtualTour,
  }) {
    return SearchFilters(
      location: location ?? this.location,
      city: city ?? this.city,
      district: district ?? this.district,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      propertyType: propertyType ?? this.propertyType,
      transactionType: transactionType ?? this.transactionType,
      minArea: minArea ?? this.minArea,
      maxArea: maxArea ?? this.maxArea,
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
      onlyVerified: onlyVerified ?? this.onlyVerified,
      onlyWithPhotos: onlyWithPhotos ?? this.onlyWithPhotos,
      fromOwner: fromOwner ?? this.fromOwner,
      withVirtualTour: withVirtualTour ?? this.withVirtualTour,
    );
  }
  
  int get activeFiltersCount {
    int count = 0;
    if (location != null) count++;
    if (minPrice != null || maxPrice != null) count++;
    if (propertyType != null) count++;
    if (transactionType != null) count++;
    if (minArea != null || maxArea != null) count++;
    if (minRooms != null || maxRooms != null) count++;
    if (amenities.isNotEmpty) count++;
    if (onlyVerified) count++;
    if (onlyWithPhotos) count++;
    if (fromOwner) count++;
    return count;
  }
  
  bool get hasActiveFilters => activeFiltersCount > 0;
}
