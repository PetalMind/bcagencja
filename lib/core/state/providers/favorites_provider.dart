import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _favoritesKey = 'favorite_property_ids';

/// Provider for SharedPreferences (used by favorites persistence).
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'SharedPreferences must be overridden in main.dart with runWithPreferences',
  );
});

/// Favorites state: set of property IDs that the user has added to favorites.
class FavoritesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    return {};
  }

  Future<Set<String>> _loadFromDisk() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final list = prefs.getStringList(_favoritesKey);
    return list != null ? Set<String>.from(list) : {};
  }

  Future<void> _save() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setStringList(_favoritesKey, state.toList());
  }

  /// Initializes state from disk. Call once at app start (e.g. in root widget).
  Future<void> initialize() async {
    state = await _loadFromDisk();
  }

  bool isFavorite(String propertyId) => state.contains(propertyId);

  Future<void> toggle(String propertyId) async {
    state = Set<String>.from(state);
    if (state.contains(propertyId)) {
      state.remove(propertyId);
    } else {
      state.add(propertyId);
    }
    await _save();
  }

  Future<void> add(String propertyId) async {
    if (state.contains(propertyId)) return;
    state = Set<String>.from(state)..add(propertyId);
    await _save();
  }

  Future<void> remove(String propertyId) async {
    if (!state.contains(propertyId)) return;
    state = Set<String>.from(state)..remove(propertyId);
    await _save();
  }
}

final favoritesProvider =
    NotifierProvider<FavoritesNotifier, Set<String>>(FavoritesNotifier.new);
