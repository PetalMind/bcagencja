import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../config/app_config.dart';

class SearchCache {
  static const String _cachePrefix = 'search_cache_';
  static const String _timestampSuffix = '_timestamp';
  
  static Future<void> cacheSearchResults({
    required String query,
    required Map<String, dynamic> results,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + query;
      final timestampKey = cacheKey + _timestampSuffix;
      
      await prefs.setString(cacheKey, json.encode(results));
      await prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // Silently fail - caching is optional
      print('Cache write error: $e');
    }
  }
  
  static Future<Map<String, dynamic>?> getCachedResults(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + query;
      final timestampKey = cacheKey + _timestampSuffix;
      
      final cachedData = prefs.getString(cacheKey);
      final timestamp = prefs.getInt(timestampKey);
      
      if (cachedData == null || timestamp == null) {
        return null;
      }
      
      // Check if cache is still valid
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (cacheAge > AppConfig.searchCacheDuration.inMilliseconds) {
        await clearCache(query);
        return null;
      }
      
      return json.decode(cachedData) as Map<String, dynamic>;
    } catch (e) {
      print('Cache read error: $e');
      return null;
    }
  }
  
  static Future<void> clearCache(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + query;
      final timestampKey = cacheKey + _timestampSuffix;
      
      await prefs.remove(cacheKey);
      await prefs.remove(timestampKey);
    } catch (e) {
      print('Cache clear error: $e');
    }
  }
  
  static Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      print('Clear all cache error: $e');
    }
  }
}
