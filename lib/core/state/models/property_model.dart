/// Odniesienie do dokumentu VDR (ścieżka w Storage + nazwa do wyświetlenia).
class VdrDocumentRef {
  const VdrDocumentRef({required this.name, required this.storagePath});
  final String name;
  final String storagePath;
}

class Property {
  final String id;
  final String title;
  final String description;
  final double price;
  final double? pricePerSqm;
  final double area; // powierzchnia użytkowa w m²
  final int floors; // liczba kondygnacji
  final int? parkingSpaces; // liczba miejsc parkingowych
  final String propertyType; // 'office', 'warehouse', 'retail', 'industrial', 'hotel', 'land'
  final String transactionType; // zawsze 'sale' dla komercyjnych
  final String location;
  final String city;
  final String? district;
  final String? street;
  final double? latitude;
  final double? longitude;
  final List<String> images;
  final String? mainImage;
  final List<String> features; // cechy komercyjne
  final int? yearBuilt;
  final String? condition; // 'new', 'excellent', 'good', 'requires_renovation'
  final String? buildingClass; // 'A+', 'A', 'B+', 'B', 'C'
  final bool hasLoadingDock; // rampa załadunkowa
  final bool hasParking;
  final bool hasElevator;
  final bool hasSecurity; // ochrona 24h
  final bool hasReception; // recepcja
  final double? ceilingHeight; // wysokość pomieszczeń
  final double? plotArea; // powierzchnia działki
  final String? zoning; // przeznaczenie w MPZP
  final double? roi; // rentowność (%)
  final double? currentRent; // obecny czynsz (jeśli wynajęte)
  final String? tenant; // obecny najemca
  final DateTime? leaseUntil; // umowa najmu do
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
  /// Dokumenty VDR (operaty, umowy) – pobierane z watermarkiem przez Cloud Function.
  final List<VdrDocumentRef> vdrDocuments;

  Property({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.pricePerSqm,
    required this.area,
    required this.floors,
    this.parkingSpaces,
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
    this.features = const [],
    this.yearBuilt,
    this.condition,
    this.buildingClass,
    this.hasLoadingDock = false,
    this.hasParking = false,
    this.hasElevator = false,
    this.hasSecurity = false,
    this.hasReception = false,
    this.ceilingHeight,
    this.plotArea,
    this.zoning,
    this.roi,
    this.currentRent,
    this.tenant,
    this.leaseUntil,
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
    this.vdrDocuments = const [],
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
      case 'office':
        return 'Biurowiec';
      case 'warehouse':
        return 'Magazyn / Hala';
      case 'retail':
        return 'Lokal handlowy';
      case 'industrial':
        return 'Obiekt przemysłowy';
      case 'hotel':
        return 'Hotel / Obiekt hotelarski';
      case 'land':
        return 'Działka inwestycyjna';
      default:
        return 'Nieruchomość komercyjna';
    }
  }
  
  String get transactionTypeLabel {
    return 'Sprzedaż'; // Tylko sprzedaż dla nieruchomości komercyjnych
  }
  
  String get buildingClassLabel {
    if (buildingClass == null) return 'Brak klasyfikacji';
    return 'Klasa $buildingClass';
  }
  
  String get conditionLabel {
    switch (condition) {
      case 'new':
        return 'Nowy obiekt';
      case 'excellent':
        return 'Stan doskonały';
      case 'good':
        return 'Stan dobry';
      case 'requires_renovation':
        return 'Wymaga remontu';
      default:
        return 'Nieznany';
    }
  }
  
  // Compatibility properties for widgets that still use old names
  int get rooms => floors; // For backward compatibility
  List<String> get amenities => features; // For backward compatibility

  /// Dla zapisanych ofert: zwraca Property z mocków gdy id ma postać "property_N".
  /// Gdy będzie backend (Firestore), można podmienić na pobieranie po id.
  static Property? fromMockId(String id) {
    final index = int.tryParse(id.replaceAll('property_', '').trim());
    if (index == null || index < 0) return null;
    return Property.mock(index);
  }

  // Factory constructor for creating mock data
  factory Property.mock(int index) {
    final descriptions = [
      'Nowoczesny biurowiec klasy A w prestiżowej lokalizacji biznesowej. Budynek oferuje wysokiej jakości przestrzeń biurową z panoramicznymi oknami, zapewniającymi doskonałe doświetlenie naturalne. Nieruchomość wyposażona w nowoczesne systemy klimatyzacji, wentylacji oraz BMS. Na każdej kondygnacji znajdują się zaplecza socjalne, toalety oraz węzły komunikacyjne. Budynek posiada recepcję 24h, ochronę oraz monitoring. Parking podziemny z 150 miejscami. Doskonała lokalizacja z bezpośrednim dostępem do węzła komunikacyjnego - metro, liczne linie autobusowe i tramwajowe. W okolicy rozwinięta infrastruktura gastronomiczna i usługowa. Idealna inwestycja dla firm poszukujących prestiżowej siedziby lub pod wynajem komercyjny z wysokim ROI.',
      'Obiekt magazynowo-logistyczny w strategicznej lokalizacji przy głównych arteriach komunikacyjnych. Hala produkcyjno-magazynowa o konstrukcji stalowej z pełnym zapleczem biurowym i socjalnym. Wysokość użytkowa 10m, posadzka przemysłowa o nośności 5t/m². Obiektem dysponuje 6 dokami załadunkowymi oraz bramą na poziomie terenu. System przeciwpożarowy, monitoring, oświetlenie LED, ogrzewanie gazowe. Plac manewrowy utwardzony, ogrodzony teren z ochroną. Doskonały dojazd - 5km od węzła autostradowego, 15km od portu lotniczego. Pełna infrastruktura techniczna: energia 250kW, woda, kanalizacja, gaz. Idealne dla branży logistycznej, e-commerce, produkcji lekkiej. Wysoka rentowność w segmencie warehouse.',
      'Atrakcyjny lokal handlowy w centrum miasta o dużym natężeniu ruchu pieszego. Przestrzeń na parterze prestiżowego budynku, z dużymi witrynami i bezpośrednim wejściem z głównej ulicy handlowej. Lokal w stanie deweloperskim, możliwość aranżacji według własnych potrzeb. Wysokość pomieszczeń 4,2m, możliwość wykonania antresoli. Wszystkie media: woda, kanalizacja, energia 63kW, klimatyzacja, wentylacja. Doskonała lokalizacja - okolica z intensywnym ruchem turystycznym i biznesowym, liczne biura, hotele, restauracje. Bezpośredni dostęp do komunikacji miejskiej - przystanek metra 100m. Idealny dla branży retail premium, gastronomii, showroomu. Świetna inwestycja z perspektywą wysokich zysków z najmu.',
      'Kompleks przemysłowy na dużej działce z pełną infrastrukturą techniczną. Nieruchomość składa się z hali produkcyjnej (3000m²), magazynu (1500m²) oraz budynku biurowo-socjalnego (500m²). Hale o konstrukcji stalowej, wysokość użytkowa 8-12m, suwnice pomostowe 5t, posadzka przemysłowa. Doki załadunkowe, plac manewrowy dla TIR-ów, parking dla 50 samochodów. Moc przyłączeniowa 800kW, własna transformatornia, gaz, studnia głębinowa. Teren ogrodzony, monitoring, ochrona. Położenie przy głównej trasie krajowej, 3km od autostrady. Zezwolenia na działalność produkcyjną. Doskonała okazja dla inwestora branży produkcyjnej, logistycznej lub pod redevelopment.',
      'Działka inwestycyjna pod zabudowę komercyjną w dynamicznie rozwijającej się strefie biznesowej. Grunt o pow. 5000m² z możliwością zabudowy do 40% powierzchni, intensywność do 2.0. Przeznaczenie w MPZP: usługi, handel, biura. Wszystkie media w granicy działki: energia, woda, kanalizacja, gaz, telekomunikacja. Działka ogrodzona, teren równy, bez obciążeń. Doskonała lokalizacja - w pobliżu centrum handlowe, hotele, nowe osiedla mieszkaniowe. Dojazd drogą asfaltową, węzeł autostradowy 2km. Świetna okazja inwestycyjna pod budowę biurowca, centrum handlowego, hotelu lub obiektów usługowych. Wysoka prognozowana rentowność inwestycji.',
    ];
    
    final cities = ['Warszawa', 'Kraków', 'Wrocław', 'Gdańsk', 'Poznań', 'Katowice', 'Łódź'];
    final districts = ['Mokotów', 'Wilanów', 'Bemowo', 'Praga Południe', 'Ursus', 'Ochota', 'Białołęka'];
    final streets = ['Al. Jerozolimskie', 'ul. Puławska', 'ul. Marynarska', 'ul. Postępu', 'ul. Łopuszańska', 'ul. Żwirki i Wigury'];
    
    final city = cities[index % cities.length];
    final district = districts[index % districts.length];
    final street = streets[index % streets.length];
    
    final propertyTypes = ['office', 'warehouse', 'retail', 'industrial', 'hotel', 'land'];
    final propertyType = propertyTypes[index % propertyTypes.length];
    
    final buildingClasses = ['A+', 'A', 'B+', 'B', 'C'];
    final conditions = ['new', 'excellent', 'good', 'requires_renovation'];
    
    final titles = [
      'Nowoczesny biurowiec klasy A w centrum miasta',
      'Hala magazynowo-logistyczna przy autostradzie',
      'Prestiżowy lokal handlowy w śródmieściu',
      'Kompleks przemysłowy z infrastrukturą',
      'Działka inwestycyjna pod zabudowę komercyjną',
      'Centrum handlowe z pełnym najemcą',
    ];
    
    final imagesByType = {
      'office': [
        'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=800&q=80',
        'https://images.unsplash.com/photo-1497366216548-37526070297c?w=800&q=80',
        'https://images.unsplash.com/photo-1497366754035-f200968a6e72?w=800&q=80',
        'https://images.unsplash.com/photo-1524758631624-e2822e304c36?w=800&q=80',
      ],
      'warehouse': [
        'https://images.unsplash.com/photo-1553413077-190dd305871c?w=800&q=80',
        'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?w=800&q=80',
        'https://images.unsplash.com/photo-1565610222536-ef2e4734fba0?w=800&q=80',
        'https://images.unsplash.com/photo-1619468129361-605ebea04b44?w=800&q=80',
      ],
      'retail': [
        'https://images.unsplash.com/photo-1555529902-5261145633bf?w=800&q=80',
        'https://images.unsplash.com/photo-1567696911980-2eed69a46042?w=800&q=80',
        'https://images.unsplash.com/photo-1582719471137-c3967ffb1c42?w=800&q=80',
        'https://images.unsplash.com/photo-1580511227046-e0f18a33e751?w=800&q=80',
      ],
      'industrial': [
        'https://images.unsplash.com/photo-1504917595217-d4dc5ebe6122?w=800&q=80',
        'https://images.unsplash.com/photo-1581092160562-40aa08e78837?w=800&q=80',
        'https://images.unsplash.com/photo-1581092918056-0c4c3acd3789?w=800&q=80',
        'https://images.unsplash.com/photo-1582407947304-fd86f028f716?w=800&q=80',
      ],
      'hotel': [
        'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=800&q=80',
        'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800&q=80',
        'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=800&q=80',
        'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',
      ],
      'land': [
        'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=800&q=80',
        'https://images.unsplash.com/photo-1501594907352-04cda38ebc29?w=800&q=80',
        'https://images.unsplash.com/photo-1464146072230-91cabc968266?w=800&q=80',
        'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800&q=80',
      ],
    };
    
    final images = imagesByType[propertyType] ?? imagesByType['office']!;
    
    final featuresByType = {
      'office': ['Recepcja 24h', 'Klimatyzacja', 'BMS', 'Parking podziemny', 'Winda towarowa', 'Ochrona', 'Monitoring CCTV', 'Kontrola dostępu'],
      'warehouse': ['Doki załadunkowe', 'Rampy', 'Suwnice', 'Posadzka przemysłowa', 'Ochrona 24h', 'Plac manewrowy', 'Parking TIR', 'System p.poż'],
      'retail': ['Duże witryny', 'Wejście główne', 'Klimatyzacja', 'Monitoring', 'Witryna LED', 'Zaplecze magazynowe', 'Toalety', 'System alarmowy'],
      'industrial': ['Hala produkcyjna', 'Suwnice', 'Doki', 'Transformatornia', 'Biura', 'Socjalne', 'Plac TIR', 'Waga samochodowa'],
      'hotel': ['Recepcja', 'Restauracja', 'Parking', 'Wi-Fi', 'Klimatyzacja', 'Sala konferencyjna', 'Monitoring', 'System rezerwacji'],
      'land': ['Media w granicy', 'MPZP', 'Ogrodzona', 'Dojazd asfaltowy', 'Teren równy', 'KW', 'Bez obciążeń', 'Wszystkie zgody'],
    };
    
    final basePrice = propertyType == 'office' ? 8500000 
        : propertyType == 'warehouse' ? 12000000
        : propertyType == 'retail' ? 3500000
        : propertyType == 'industrial' ? 15000000
        : propertyType == 'hotel' ? 25000000
        : 2500000; // land
    
    final baseArea = propertyType == 'office' ? 2500.0 
        : propertyType == 'warehouse' ? 5000.0
        : propertyType == 'retail' ? 350.0
        : propertyType == 'industrial' ? 8000.0
        : propertyType == 'hotel' ? 3500.0
        : 5000.0; // land
    
    final price = basePrice + (index * 500000);
    final area = baseArea + (index * 250);
    
    return Property(
      id: 'property_$index',
      title: titles[index % titles.length],
      description: descriptions[index % descriptions.length],
      price: price.toDouble(),
      pricePerSqm: price / area,
      area: area,
      floors: propertyType == 'land' ? 0 : (2 + (index % 5)),
      parkingSpaces: propertyType == 'land' ? null : (20 + (index * 10)),
      propertyType: propertyType,
      transactionType: 'sale',
      location: '$city, $district',
      city: city,
      district: district,
      street: '$street ${index + 15}',
      latitude: 52.2297 + (index * 0.001),
      longitude: 21.0122 + (index * 0.001),
      images: images,
      mainImage: images[0],
      features: featuresByType[propertyType] ?? [],
      yearBuilt: 2010 + (index % 13),
      condition: conditions[index % conditions.length],
      buildingClass: propertyType == 'office' || propertyType == 'retail' 
          ? buildingClasses[index % buildingClasses.length] 
          : null,
      hasLoadingDock: propertyType == 'warehouse' || propertyType == 'industrial',
      hasParking: true,
      hasElevator: propertyType == 'office' || propertyType == 'hotel',
      hasSecurity: index % 2 == 0,
      hasReception: propertyType == 'office' || propertyType == 'hotel',
      ceilingHeight: propertyType == 'warehouse' || propertyType == 'industrial' 
          ? (8.0 + (index % 4)) 
          : (3.0 + (index % 2) * 0.5),
      plotArea: propertyType == 'land' ? area : (area * 1.5),
      zoning: propertyType == 'land' ? 'UC - usługi i handel' : null,
      roi: (5.5 + (index % 3) * 0.5),
      currentRent: index % 3 == 0 ? (area * 45 * 1.23) : null,
      tenant: index % 3 == 0 ? 'Największy najemca w branży' : null,
      leaseUntil: index % 3 == 0 
          ? DateTime.now().add(Duration(days: 365 * (3 + index % 5))) 
          : null,
      verified: index % 2 == 0,
      promoted: index % 3 == 0,
      ownerId: 'owner_$index',
      ownerName: 'BC Agencja Nieruchomości',
      ownerPhone: '+48 123 456 789',
      ownerEmail: 'inwestycje@bcagencja.pl',
      createdAt: DateTime.now().subtract(Duration(days: index * 3)),
      updatedAt: DateTime.now().subtract(Duration(days: index)),
      views: 450 + (index * 85),
      favorites: 12 + (index * 4),
    );
  }
}
