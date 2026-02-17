import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Wynik autocomplete – jedna propozycja z place_id.
class PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });
}

/// Wynik Place Details – adres, współrzędne, składowe.
class PlaceDetails {
  final String formattedAddress;
  final double? latitude;
  final double? longitude;
  final String? locality; // miasto
  final String? administrativeArea; // województwo
  final String? street;
  final String? streetNumber;
  final String? postalCode; // XX-XXX

  PlaceDetails({
    required this.formattedAddress,
    this.latitude,
    this.longitude,
    this.locality,
    this.administrativeArea,
    this.street,
    this.streetNumber,
    this.postalCode,
  });
}

/// Serwis Google Places API (Autocomplete + Place Details).
/// Wymaga w AppConfig: googleMapsApiKey i włączonego Places API w Google Cloud.
class GooglePlacesService {
  GooglePlacesService({
    String? apiKey,
    http.Client? client,
  })  : _apiKey = apiKey ?? AppConfig.googleMapsApiKey,
        _client = client ?? http.Client();

  final String _apiKey;
  final http.Client _client;

  static const String _autocompleteUrl = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const String _detailsUrl = 'https://maps.googleapis.com/maps/api/place/details/json';
  static const String _geocodeUrl = 'https://maps.googleapis.com/maps/api/geocode/json';

  /// Zwraca propozycje adresów dla danego wpisu (Polska, język PL).
  /// Gdy apiKey jest pusty lub "YOUR_GOOGLE_MAPS_API_KEY", zwraca pustą listę.
  Future<List<PlacePrediction>> autocomplete(String input) async {
    final trimmed = input.trim();
    if (trimmed.length < 2) return [];
    if (_apiKey.isEmpty || _apiKey == 'YOUR_GOOGLE_MAPS_API_KEY') return [];

    try {
      final uri = Uri.parse(_autocompleteUrl).replace(
        queryParameters: {
          'input': trimmed,
          'key': _apiKey,
          'components': 'country:pl',
          'language': 'pl',
        },
      );
      final response = await _client.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return [];

      final json = _decodeJson(response.body);
      if (json == null) return [];

      final status = json['status'] as String?;
      if (status != 'OK' && status != 'ZERO_RESULTS') return [];

      final predictions = json['predictions'] as List<dynamic>?;
      if (predictions == null || predictions.isEmpty) return [];

      return predictions.map((p) {
        final map = p as Map<String, dynamic>;
        final terms = map['terms'] as List<dynamic>?;
        String mainText = '';
        String secondaryText = '';
        if (terms != null && terms.isNotEmpty) {
          mainText = (terms[0] as Map<String, dynamic>)['value'] as String? ?? '';
          if (terms.length > 1) {
            secondaryText = terms.sublist(1).map((t) => (t as Map<String, dynamic>)['value'] as String? ?? '').join(', ');
          }
        }
        return PlacePrediction(
          placeId: map['place_id'] as String? ?? '',
          description: map['description'] as String? ?? '',
          mainText: mainText.isNotEmpty ? mainText : (map['structured_formatting']?['main_text'] as String? ?? ''),
          secondaryText: secondaryText.isNotEmpty ? secondaryText : (map['structured_formatting']?['secondary_text'] as String? ?? ''),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Pobiera szczegóły miejsca po place_id (współrzędne, address_components).
  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    if (placeId.isEmpty) return null;
    if (_apiKey.isEmpty || _apiKey == 'YOUR_GOOGLE_MAPS_API_KEY') return null;

    try {
      final uri = Uri.parse(_detailsUrl).replace(
        queryParameters: {
          'place_id': placeId,
          'key': _apiKey,
          'language': 'pl',
          'fields': 'formatted_address,geometry,address_components',
        },
      );
      final response = await _client.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;

      final json = _decodeJson(response.body);
      if (json == null) return null;

      final status = json['status'] as String?;
      if (status != 'OK') return null;

      final result = json['result'] as Map<String, dynamic>?;
      if (result == null) return null;

      final formattedAddress = result['formatted_address'] as String? ?? '';
      double? lat;
      double? lng;
      final geometry = result['geometry'] as Map<String, dynamic>?;
      if (geometry != null) {
        final loc = geometry['location'] as Map<String, dynamic>?;
        if (loc != null) {
          lat = (loc['lat'] as num?)?.toDouble();
          lng = (loc['lng'] as num?)?.toDouble();
        }
      }

      String? locality;
      String? administrativeArea;
      String? street;
      String? streetNumber;
      String? postalCode;
      final components = result['address_components'] as List<dynamic>?;
      if (components != null) {
        for (final c in components) {
          final map = c as Map<String, dynamic>;
          final types = map['types'] as List<dynamic>? ?? [];
          final longName = map['long_name'] as String? ?? '';
          if (types.contains('locality')) locality = longName;
          if (types.contains('administrative_area_level_1')) administrativeArea = longName;
          if (types.contains('route')) street = longName;
          if (types.contains('street_number')) streetNumber = longName;
          if (types.contains('postal_code')) postalCode = longName;
        }
      }
      // Normalizuj kod do XX-XXX jeśli jest samymi cyframi
      if (postalCode != null && postalCode!.isNotEmpty && RegExp(r'^\d{5}$').hasMatch(postalCode!)) {
        postalCode = '${postalCode!.substring(0, 2)}-${postalCode!.substring(2)}';
      }

      return PlaceDetails(
        formattedAddress: formattedAddress,
        latitude: lat,
        longitude: lng,
        locality: locality,
        administrativeArea: administrativeArea,
        street: street,
        streetNumber: streetNumber,
        postalCode: postalCode,
      );
    } catch (_) {
      return null;
    }
  }

  /// Reverse geocode: współrzędne → adres (miasto, województwo). Używane przy "Użyj mojej lokalizacji".
  Future<PlaceDetails?> reverseGeocode(double latitude, double longitude) async {
    if (_apiKey.isEmpty || _apiKey == 'YOUR_GOOGLE_MAPS_API_KEY') return null;

    try {
      final uri = Uri.parse(_geocodeUrl).replace(
        queryParameters: {
          'latlng': '$latitude,$longitude',
          'key': _apiKey,
          'language': 'pl',
        },
      );
      final response = await _client.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;

      final json = _decodeJson(response.body);
      if (json == null) return null;

      final status = json['status'] as String?;
      if (status != 'OK' && status != 'ZERO_RESULTS') return null;

      final results = json['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;

      final result = results.first as Map<String, dynamic>;
      final formattedAddress = result['formatted_address'] as String? ?? '';
      final geometry = result['geometry'] as Map<String, dynamic>?;
      double? lat;
      double? lng;
      if (geometry != null) {
        final loc = geometry['location'] as Map<String, dynamic>?;
        if (loc != null) {
          lat = (loc['lat'] as num?)?.toDouble();
          lng = (loc['lng'] as num?)?.toDouble();
        }
      }
      lat ??= latitude;
      lng ??= longitude;

      String? locality;
      String? administrativeArea;
      String? street;
      String? streetNumber;
      String? postalCode;
      final components = result['address_components'] as List<dynamic>?;
      if (components != null) {
        for (final c in components) {
          final map = c as Map<String, dynamic>;
          final types = map['types'] as List<dynamic>? ?? [];
          final longName = map['long_name'] as String? ?? '';
          if (types.contains('locality')) locality = longName;
          if (types.contains('administrative_area_level_1')) administrativeArea = longName;
          if (types.contains('route')) street = longName;
          if (types.contains('street_number')) streetNumber = longName;
          if (types.contains('postal_code')) postalCode = longName;
        }
      }
      if (postalCode != null && postalCode!.isNotEmpty && RegExp(r'^\d{5}$').hasMatch(postalCode!)) {
        postalCode = '${postalCode!.substring(0, 2)}-${postalCode!.substring(2)}';
      }

      return PlaceDetails(
        formattedAddress: formattedAddress,
        latitude: lat,
        longitude: lng,
        locality: locality,
        administrativeArea: administrativeArea,
        street: street,
        streetNumber: streetNumber,
        postalCode: postalCode,
      );
    } catch (_) {
      return null;
    }
  }

  static dynamic _decodeJson(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }
}
