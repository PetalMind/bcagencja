import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_provider.dart';

const String _favoritesKeyPrefix = 'favorite_property_ids';

/// Provider for SharedPreferences (used by favorites persistence).
/// Może być null na Safari Web (tryb prywatny / blokada storage) – wtedy ulubione nie są zapisywane.
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) {
  throw UnimplementedError(
    'SharedPreferences must be overridden in main.dart with runWithPreferences',
  );
});

/// Zwraca klucz do zapisu ulubionych dla danego użytkownika (lub 'guest' gdy niezalogowany).
String _favoritesKeyForUser(String? userId) =>
    '${_favoritesKeyPrefix}_${userId ?? 'guest'}';

/// Favorites state: set of property IDs that the user has added to favorites.
/// Przypisane do zalogowanego użytkownika – przy zmianie użytkownika wczytujemy jego dane.
class FavoritesNotifier extends Notifier<Set<String>> {
  String? _loadedUserId;

  @override
  Set<String> build() {
    return {};
  }

  String? get _currentUserId => ref.read(currentUserProvider).valueOrNull?.id;

  Future<Set<String>> _loadFromDisk(String? userId) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (prefs == null) return {};
    final key = _favoritesKeyForUser(userId);
    final list = prefs.getStringList(key);
    return list != null ? Set<String>.from(list) : {};
  }

  Future<void> _save(String? userId) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (prefs == null) return;
    final key = _favoritesKeyForUser(userId);
    await prefs.setStringList(key, state.toList());
  }

  /// Inicjalizacja: zapisuje dane poprzedniego użytkownika (jeśli był), wczytuje dane aktualnego.
  /// Wywołaj przy starcie aplikacji oraz przy każdej zmianie użytkownika (logowanie/wylogowanie).
  Future<void> initialize() async {
    final newUserId = _currentUserId;
    if (_loadedUserId != null && _loadedUserId != newUserId) {
      await _save(_loadedUserId);
    }
    state = await _loadFromDisk(newUserId);
    _loadedUserId = newUserId;
  }

  bool isFavorite(String propertyId) => state.contains(propertyId);

  Future<void> toggle(String propertyId) async {
    state = Set<String>.from(state);
    if (state.contains(propertyId)) {
      state.remove(propertyId);
    } else {
      state.add(propertyId);
    }
    await _save(_loadedUserId ?? _currentUserId);
  }

  Future<void> add(String propertyId) async {
    if (state.contains(propertyId)) return;
    state = Set<String>.from(state)..add(propertyId);
    await _save(_loadedUserId ?? _currentUserId);
  }

  Future<void> remove(String propertyId) async {
    if (!state.contains(propertyId)) return;
    state = Set<String>.from(state)..remove(propertyId);
    await _save(_loadedUserId ?? _currentUserId);
  }
}

final favoritesProvider =
    NotifierProvider<FavoritesNotifier, Set<String>>(FavoritesNotifier.new);
