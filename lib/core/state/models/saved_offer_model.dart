/// Kolekcja zapisanych ofert (np. "Na priorytet", "Portfolio Retail").
class SavedCollection {
  const SavedCollection({
    required this.id,
    required this.name,
    required this.icon,
  });

  final String id;
  final String name;
  final String icon;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
      };

  factory SavedCollection.fromJson(Map<String, dynamic> json) {
    return SavedCollection(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String? ?? '📁',
    );
  }
}

/// Rozszerzone dane zapisanej oferty: kolekcje, notatka, powiadomienia.
class SavedOfferEntry {
  const SavedOfferEntry({
    required this.propertyId,
    required this.collectionIds,
    this.note,
    this.notifyPriceChange = false,
    this.notifyNewDocs = false,
    this.notifyOthersView = false,
    required this.savedAt,
  });

  final String propertyId;
  final List<String> collectionIds;
  final String? note;
  final bool notifyPriceChange;
  final bool notifyNewDocs;
  final bool notifyOthersView;
  final DateTime savedAt;

  SavedOfferEntry copyWith({
    String? propertyId,
    List<String>? collectionIds,
    String? note,
    bool? notifyPriceChange,
    bool? notifyNewDocs,
    bool? notifyOthersView,
    DateTime? savedAt,
  }) {
    return SavedOfferEntry(
      propertyId: propertyId ?? this.propertyId,
      collectionIds: collectionIds ?? this.collectionIds,
      note: note ?? this.note,
      notifyPriceChange: notifyPriceChange ?? this.notifyPriceChange,
      notifyNewDocs: notifyNewDocs ?? this.notifyNewDocs,
      notifyOthersView: notifyOthersView ?? this.notifyOthersView,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'propertyId': propertyId,
        'collectionIds': collectionIds,
        'note': note,
        'notifyPriceChange': notifyPriceChange,
        'notifyNewDocs': notifyNewDocs,
        'notifyOthersView': notifyOthersView,
        'savedAt': savedAt.toIso8601String(),
      };

  factory SavedOfferEntry.fromJson(Map<String, dynamic> json) {
    final list = json['collectionIds'];
    return SavedOfferEntry(
      propertyId: json['propertyId'] as String? ?? '',
      collectionIds: list is List<dynamic>
          ? list.map((e) => e.toString()).toList()
          : <String>[],
      note: json['note'] as String?,
      notifyPriceChange: json['notifyPriceChange'] as bool? ?? false,
      notifyNewDocs: json['notifyNewDocs'] as bool? ?? false,
      notifyOthersView: json['notifyOthersView'] as bool? ?? false,
      savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// Domyślne kolekcje przy pierwszym uruchomieniu.
List<SavedCollection> get defaultCollections => [
      const SavedCollection(id: 'priority', name: 'Na priorytet', icon: '🔥'),
      const SavedCollection(id: 'retail', name: 'Portfolio Retail', icon: '💼'),
      const SavedCollection(id: 'compare', name: 'Do porównania', icon: '📊'),
      const SavedCollection(id: 'analysis', name: 'Wymaga analizy', icon: '🤔'),
    ];
