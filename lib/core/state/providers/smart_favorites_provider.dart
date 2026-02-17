import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_offer_model.dart';
import 'auth_provider.dart';
import 'favorites_provider.dart';

const String _collectionsKeyPrefix = 'smart_favorites_collections';
const String _entriesKeyPrefix = 'smart_favorites_entries';

String _keyForUser(String prefix, String? userId) => '${prefix}_${userId ?? 'guest'}';

/// Stan: lista kolekcji + mapa propertyId -> SavedOfferEntry.
class SmartFavoritesState {
  const SmartFavoritesState({
    this.collections = const [],
    this.entries = const {},
  });

  final List<SavedCollection> collections;
  final Map<String, SavedOfferEntry> entries;

  SmartFavoritesState copyWith({
    List<SavedCollection>? collections,
    Map<String, SavedOfferEntry>? entries,
  }) {
    return SmartFavoritesState(
      collections: collections ?? this.collections,
      entries: entries ?? this.entries,
    );
  }

  SavedOfferEntry? entryFor(String propertyId) => entries[propertyId];
}

class SmartFavoritesNotifier extends Notifier<SmartFavoritesState> {
  String? _loadedUserId;

  @override
  SmartFavoritesState build() {
    return const SmartFavoritesState();
  }

  SharedPreferences? get _prefs => ref.read(sharedPreferencesProvider);
  String? get _currentUserId => ref.read(currentUserProvider).asData?.value?.id;

  Future<void> _loadCollections(String? userId) async {
    final prefs = _prefs;
    if (prefs == null) return;
    final key = _keyForUser(_collectionsKeyPrefix, userId);
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>?;
      if (list == null) return;
      state = state.copyWith(
        collections: list
            .map((e) => SavedCollection.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
    } catch (_) {}
  }

  Future<void> _saveCollections(String? userId) async {
    final prefs = _prefs;
    if (prefs == null) return;
    final key = _keyForUser(_collectionsKeyPrefix, userId);
    final list = state.collections.map((e) => e.toJson()).toList();
    await prefs.setString(key, jsonEncode(list));
  }

  Future<void> _loadEntries(String? userId) async {
    final prefs = _prefs;
    if (prefs == null) return;
    final key = _keyForUser(_entriesKeyPrefix, userId);
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>?;
      if (map == null) return;
      state = state.copyWith(
        entries: map.map(
          (k, v) => MapEntry(
            k,
            SavedOfferEntry.fromJson(Map<String, dynamic>.from(v as Map)),
          ),
        ),
      );
    } catch (_) {}
  }

  Future<void> _saveEntries(String? userId) async {
    final prefs = _prefs;
    if (prefs == null) return;
    final key = _keyForUser(_entriesKeyPrefix, userId);
    final map = state.entries.map((k, v) => MapEntry(k, v.toJson()));
    await prefs.setString(key, jsonEncode(map));
  }

  /// Inicjalizacja: zapisuje dane poprzedniego użytkownika, wczytuje dane aktualnego.
  /// Wywołaj przy starcie oraz przy zmianie użytkownika (logowanie/wylogowanie).
  Future<void> initialize() async {
    final newUserId = _currentUserId;
    if (_loadedUserId != null && _loadedUserId != newUserId) {
      await _saveCollections(_loadedUserId);
      await _saveEntries(_loadedUserId);
    }
    await _loadCollections(newUserId);
    if (state.collections.isEmpty) {
      state = state.copyWith(collections: defaultCollections);
      await _saveCollections(newUserId);
    }
    await _loadEntries(newUserId);
    _loadedUserId = newUserId;
  }

  /// Zapisanie oferty z wyborem kolekcji, notatki i powiadomień.
  /// Równocześnie dodaje propertyId do favoritesProvider.
  /// Nie zapisuje ofert własnego autorstwa: gdy [ownerId] == currentUser.id, operacja jest pomijana.
  Future<void> saveOffer({
    required String propertyId,
    required List<String> collectionIds,
    String? note,
    bool notifyPriceChange = false,
    bool notifyNewDocs = false,
    bool notifyOthersView = false,
    String? ownerId,
  }) async {
    final uid = _currentUserId;
    if (ownerId != null && uid != null && ownerId == uid) return;

    final entry = SavedOfferEntry(
      propertyId: propertyId,
      collectionIds: List.from(collectionIds),
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      notifyPriceChange: notifyPriceChange,
      notifyNewDocs: notifyNewDocs,
      notifyOthersView: notifyOthersView,
      savedAt: DateTime.now(),
    );
    state = state.copyWith(
      entries: Map.from(state.entries)..[propertyId] = entry,
    );
    await _saveEntries(_loadedUserId ?? _currentUserId);
    await ref.read(favoritesProvider.notifier).add(propertyId);
  }

  /// Aktualizacja wpisu (kolekcje, notatka, powiadomienia).
  Future<void> updateEntry(SavedOfferEntry entry) async {
    state = state.copyWith(
      entries: Map.from(state.entries)..[entry.propertyId] = entry,
    );
    await _saveEntries(_loadedUserId ?? _currentUserId);
  }

  /// Usunięcie zapisanej oferty (też z favoritesProvider).
  Future<void> removeOffer(String propertyId) async {
    state = state.copyWith(
      entries: Map.from(state.entries)..remove(propertyId),
    );
    await _saveEntries(_loadedUserId ?? _currentUserId);
    await ref.read(favoritesProvider.notifier).remove(propertyId);
  }

  /// Dodanie nowej kolekcji.
  Future<void> addCollection(SavedCollection c) async {
    if (state.collections.any((e) => e.id == c.id)) return;
    state = state.copyWith(
      collections: [...state.collections, c],
    );
    await _saveCollections(_loadedUserId ?? _currentUserId);
  }

  /// Usunięcie kolekcji (nie usuwa ofert, tylko odznacza je z tej kolekcji).
  Future<void> removeCollection(String collectionId) async {
    state = state.copyWith(
      collections: state.collections.where((e) => e.id != collectionId).toList(),
      entries: state.entries.map((propertyId, entry) {
        final newIds = entry.collectionIds.where((id) => id != collectionId).toList();
        return MapEntry(
          propertyId,
          entry.copyWith(collectionIds: newIds),
        );
      }),
    );
    await _saveCollections(_loadedUserId ?? _currentUserId);
    await _saveEntries(_loadedUserId ?? _currentUserId);
  }

  /// Liczba ofert w danej kolekcji.
  int countInCollection(String collectionId) {
    return state.entries.values.where((e) => e.collectionIds.contains(collectionId)).length;
  }
}

final smartFavoritesProvider =
    NotifierProvider<SmartFavoritesNotifier, SmartFavoritesState>(SmartFavoritesNotifier.new);
