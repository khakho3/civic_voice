import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../models/location.dart';

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.placeId,
    required this.description,
    this.mainText,
    this.secondaryText,
  });

  final String placeId;
  final String description;
  final String? mainText;
  final String? secondaryText;
}

class PlacesService {
  PlacesService({
    http.Client? client,
    this._apiKey = const String.fromEnvironment('GOOGLE_MAPS_API_KEY'),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String _apiKey;

  bool get isConfigured => _apiKey.trim().isNotEmpty;

  Future<List<PlaceSuggestion>> autocomplete(String input) async {
    final query = input.trim();
    if (!isConfigured || query.length < 2) return const [];

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      {'input': query, 'key': _apiKey, 'types': 'geocode'},
    );

    final response = await _client.get(uri).timeout(const Duration(seconds: 8));
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final status = body['status'] as String?;

    if (response.statusCode != 200 ||
        (status != 'OK' && status != 'ZERO_RESULTS')) {
      throw PlacesException(
        body['error_message'] as String? ?? 'Places autocomplete failed.',
      );
    }

    final predictions = body['predictions'] as List<dynamic>? ?? const [];
    return [
      for (final item in predictions)
        PlaceSuggestion(
          placeId: item['place_id'] as String? ?? '',
          description: item['description'] as String? ?? '',
          mainText:
              (item['structured_formatting']
                      as Map<String, dynamic>?)?['main_text']
                  as String?,
          secondaryText:
              (item['structured_formatting']
                      as Map<String, dynamic>?)?['secondary_text']
                  as String?,
        ),
    ].where((suggestion) => suggestion.placeId.isNotEmpty).toList();
  }

  Future<Location> fetchPlace(String placeId) async {
    if (!isConfigured) {
      throw const PlacesException('Google Places API key is not configured.');
    }

    final uri =
        Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
          'place_id': placeId,
          'key': _apiKey,
          'fields': 'formatted_address,geometry,address_component,name',
        });

    final response = await _client.get(uri).timeout(const Duration(seconds: 8));
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final status = body['status'] as String?;

    if (response.statusCode != 200 || status != 'OK') {
      throw PlacesException(
        body['error_message'] as String? ?? 'Place details failed.',
      );
    }

    final result = body['result'] as Map<String, dynamic>;
    final geometry = result['geometry'] as Map<String, dynamic>;
    final point = geometry['location'] as Map<String, dynamic>;
    final components =
        result['address_components'] as List<dynamic>? ?? const [];

    return Location(
      formattedAddress:
          result['formatted_address'] as String? ?? 'Selected location',
      latitude: (point['lat'] as num).toDouble(),
      longitude: (point['lng'] as num).toDouble(),
      landmark: result['name'] as String?,
      locality: _component(components, const [
        'locality',
        'sublocality',
        'administrative_area_level_2',
      ]),
      administrativeArea: _component(components, const [
        'administrative_area_level_1',
      ]),
      country: _component(components, const ['country']),
    );
  }

  void dispose() {
    _client.close();
  }

  String _component(List<dynamic> components, List<String> acceptedTypes) {
    for (final component in components) {
      final map = component as Map<String, dynamic>;
      final types = (map['types'] as List<dynamic>? ?? const []).cast<String>();
      if (acceptedTypes.any(types.contains)) {
        return map['long_name'] as String? ?? '';
      }
    }
    return '';
  }
}

class PlacesException implements Exception {
  const PlacesException(this.message);

  final String message;

  @override
  String toString() => message;
}

extension LocationMapTarget on Location {
  LatLng get target => LatLng(latitude, longitude);
}
