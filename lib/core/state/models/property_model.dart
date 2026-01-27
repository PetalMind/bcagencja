class Property {
  final String id;
  final String title;
  final String description;
  final double price;
  final double? pricePerSqm;
  final double area;
  final int rooms;
  final int? floor;
  final String propertyType; // 'apartment', 'house', 'land', 'commercial'
  final String transactionType; // 'sale', 'rent'
  final String location;
  final String city;
  final String? district;
  final String? street;
  final double? latitude;
  final double? longitude;
  final List<String> images;
  final String? mainImage;
  final List<String> amenities;
  final int? yearBuilt;
  final String? condition; // 'new', 'good', 'to_renovate'
  final String? heating; // 'central', 'gas', 'electric', 'other'
  final bool hasBalcony;
  final bool hasParking;
  final bool hasElevator;
  final bool hasGarden;
  final bool verified;
  final bool promoted;
  final String ownerId;
  final String? ownerName;
  final String? ownerPhone;
  final String? ownerEmail;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int views;
  final int favorites;
  
  Property({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.pricePerSqm,
    required this.area,
    required this.rooms,
    this.floor,
    required this.propertyType,
    required this.transactionType,
    required this.location,
    required this.city,
    this.district,
    this.street,
    this.latitude,
    this.longitude,
    required this.images,
    this.mainImage,
    this.amenities = const [],
    this.yearBuilt,
    this.condition,
    this.heating,
    this.hasBalcony = false,
    this.hasParking = false,
    this.hasElevator = false,
    this.hasGarden = false,
    this.verified = false,
    this.promoted = false,
    required this.ownerId,
    this.ownerName,
    this.ownerPhone,
    this.ownerEmail,
    required this.createdAt,
    required this.updatedAt,
    this.views = 0,
    this.favorites = 0,
  });
  
  String get formattedPrice {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(2)} mln zł';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)} tys. zł';
    }
    return '$price zł';
  }
  
  String get propertyTypeLabel {
    switch (propertyType) {
      case 'apartment':
        return 'Mieszkanie';
      case 'house':
        return 'Dom';
      case 'land':
        return 'Działka';
      case 'commercial':
        return 'Lokal użytkowy';
      default:
        return 'Nieruchomość';
    }
  }
  
  String get transactionTypeLabel {
    return transactionType == 'sale' ? 'Sprzedaż' : 'Wynajem';
  }
  
  // Factory constructor for creating mock data
  factory Property.mock(int index) {
    final descriptions = [
      'Przestronne i słoneczne mieszkanie w doskonałej lokalizacji. Nieruchomość składa się z dużego salonu z aneksem kuchennym, sypialni, łazienki oraz przestronnego balkonu z widokiem na zieleń. Mieszkanie jest w bardzo dobrym stanie technicznym, z wysokiej jakości wykończeniem. W pełni wyposażona kuchnia z nowoczesnymi sprzętami AGD. Cicha i spokojna okolica, idealna dla rodzin. W budynku znajduje się winda oraz monitoring. Do mieszkania przynależy miejsce parkingowe w garażu podziemnym oraz komórka lokatorska. Doskonała komunikacja z centrum miasta - w pobliżu przystanek metra, autobusy i tramwaje. W okolicy liczne sklepy, restauracje, szkoły i przedszkola.',
      'Oferujemy do sprzedaży wyjątkowe mieszkanie w prestiżowej lokalizacji. Lokal charakteryzuje się funkcjonalnym rozkładem pomieszczeń oraz bardzo dobrym stanem technicznym. Główne pomieszczenia wychodzą na stronę południową, co zapewnia doskonałe doświetlenie przez cały dzień. Mieszkanie posiada klimatyzację, ogrzewanie podłogowe oraz wysokiej klasy stolarkę okienną. Kuchnia w pełni wyposażona w sprzęt AGD renomowanych marek. Łazienka wykończona płytkami marki hiszpańskiej z kabiną prysznicową. Budynek z 2020 roku, zamknięte osiedle z ochroną 24h, monitoringiem i pięknie zagospodarowanymi terenami zielonymi. Na terenie osiedla znajduje się plac zabaw dla dzieci oraz miejsca rekreacyjne.',
      'Komfortowe mieszkanie w świetnej lokalizacji blisko centrum. Nieruchomość jest idealna zarówno na własne potrzeby mieszkaniowe jak i pod wynajem. Mieszkanie składa się z salonu połączonego z kuchnią, dwóch sypialni, łazienki oraz dużego balkonu. Lokal jest w pełni umeblowany i wyposażony, gotowy do zamieszkania. Budynek z lat 2015 z cegły, świetnie utrzymany, z windą i miejscem na rowery. W okolicy doskonale rozwinięta infrastruktura - sklepy, apteki, przychodnie, szkoły. Bardzo dobry dojazd komunikacją miejską, w pobliżu stacja metra. Dodatkowym atutem jest cisza i spokój mimo bliskości centrum.',
    ];
    
    final cities = ['Warszawa', 'Kraków', 'Wrocław', 'Gdańsk', 'Poznań'];
    final districts = ['Śródmieście', 'Mokotów', 'Ochota', 'Żoliborz', 'Ursynów'];
    final streets = ['Marszałkowska', 'Krakowskie Przedmieście', 'Nowy Świat', 'Aleje Jerozolimskie', 'Puławska'];
    
    final city = cities[index % cities.length];
    final district = districts[index % districts.length];
    final street = streets[index % streets.length];
    
    final propertyTypes = ['apartment', 'house', 'land', 'commercial'];
    final propertyType = propertyTypes[index % propertyTypes.length];
    
    final titles = [
      'Przestronne mieszkanie w centrum miasta',
      'Nowoczesny apartament z balkonem',
      'Komfortowe mieszkanie w doskonałej lokalizacji',
      'Stylowe mieszkanie z widokiem',
      'Przytulne mieszkanie idealne dla rodziny',
    ];
    
    return Property(
      id: 'property_$index',
      title: titles[index % titles.length],
      description: descriptions[index % descriptions.length],
      price: 450000 + (index * 25000),
      pricePerSqm: 8500.0 + (index * 150),
      area: 52.5 + (index * 3.5),
      rooms: 2 + (index % 4),
      floor: 3 + (index % 12),
      propertyType: propertyType,
      transactionType: index % 2 == 0 ? 'sale' : 'rent',
      location: '$city, $district',
      city: city,
      district: district,
      street: 'ul. $street ${index + 15}',
      latitude: 52.2297 + (index * 0.001),
      longitude: 21.0122 + (index * 0.001),
      images: [
        'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800&q=80',
        'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800&q=80',
        'https://images.unsplash.com/photo-1502672260066-6bc638a4f0dc?w=800&q=80',
        'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=800&q=80',
        'https://images.unsplash.com/photo-1556020685-ae41abfc9365?w=800&q=80',
      ],
      mainImage: 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800&q=80',
      amenities: ['Balkon', 'Parking', 'Winda', 'Piwnica', 'Komórka lokatorska'],
      yearBuilt: 2015 + (index % 8),
      condition: ['new', 'good', 'to_renovate'][index % 3],
      heating: ['central', 'gas', 'electric'][index % 3],
      hasBalcony: true,
      hasParking: index % 2 == 0,
      hasElevator: true,
      hasGarden: index % 5 == 0,
      verified: index % 3 == 0,
      promoted: index % 4 == 0,
      ownerId: 'owner_$index',
      ownerName: 'Jan Kowalski',
      ownerPhone: '+48 123 456 789',
      ownerEmail: 'kontakt@bcagencja.pl',
      createdAt: DateTime.now().subtract(Duration(days: index * 2)),
      updatedAt: DateTime.now().subtract(Duration(days: index)),
      views: 150 + (index * 25),
      favorites: 5 + (index * 2),
    );
  }
}
