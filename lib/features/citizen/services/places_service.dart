import 'dart:convert';
import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../models/location.dart';
import '../../../models/region.dart';
import 'report_jurisdiction.dart';

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.placeId,
    required this.description,
    this.mainText,
    this.secondaryText,
    this.sessionToken,
  });

  final String placeId;
  final String description;
  final String? mainText;
  final String? secondaryText;
  final String? sessionToken;
}

class PlacesService {
  PlacesService({
    http.Client? client,
    this.apiKey = const String.fromEnvironment('GOOGLE_MAPS_API_KEY'),
    Map<String, String> applicationHeaders = const {},
  }) : _client = client ?? http.Client(),
       _applicationHeaders = Map.of(applicationHeaders);

  static const MethodChannel _configChannel = MethodChannel(
    'civic_voice/config',
  );

  final http.Client _client;
  String apiKey;
  final Map<String, String> _applicationHeaders;
  Future<void>? _initialization;
  String? _session;
  bool _disposed = false;

  bool get isConfigured => apiKey.trim().isNotEmpty;

  Future<void> initialize() => _initialization ??= _initialize();
  Future<void> _initialize() async {
    try {
      final config = await _configChannel
          .invokeMapMethod<String, dynamic>('googleMapsRequestConfig')
          .timeout(const Duration(seconds: 3));
      if (_disposed || config == null) return;
      if (!isConfigured && config['apiKey'] is String) {
        apiKey = config['apiKey'] as String;
      }
      if (config['androidPackage'] is String &&
          config['androidCert'] is String) {
        _applicationHeaders['X-Android-Package'] =
            config['androidPackage'] as String;
        _applicationHeaders['X-Android-Cert'] = config['androidCert'] as String;
      }
      if (config['iosBundleIdentifier'] is String) {
        _applicationHeaders['X-Ios-Bundle-Identifier'] =
            config['iosBundleIdentifier'] as String;
      }
    } on PlatformException {
      // Non-Android builds can still use --dart-define.
    } on MissingPluginException {
      // Tests and unsupported platforms do not expose the native config channel.
    } on TimeoutException {
      // Native configuration must not leave the picker waiting indefinitely.
    }
  }

  void resetSession() => _session = null;
  String _newSession() {
    final random = Random.secure();
    // 24 random bytes encode to 32 URL-safe ASCII characters. Places New
    // rejects session tokens longer than 36 characters (hex would be 48).
    return base64UrlEncode(List.generate(24, (_) => random.nextInt(256)));
  }

  Map<String, String> _headers(String mask) => {
    'Content-Type': 'application/json',
    'X-Goog-Api-Key': apiKey,
    'X-Goog-FieldMask': mask,
    ..._applicationHeaders,
  };
  Map<String, dynamic> _decode(http.Response response) {
    // Provider diagnostics can contain configuration/URL details. Keep them out
    // of the interface and never retry with removed application restrictions.
    if (response.statusCode == 403) {
      throw const PlacesException(
        'Place search is temporarily unavailable. You can still choose the issue pin on the map.',
      );
    }
    if (response.statusCode == 429) {
      throw const PlacesException(
        'Place search is busy. Wait a moment and try again.',
      );
    }
    if (response.statusCode != 200) {
      throw const PlacesException(
        'Place lookup failed. Check your connection and try again.',
      );
    }
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body['error'] == null) return body;
    } on FormatException {
      // Use a bounded public error below.
    }
    throw const PlacesException(
      'Place lookup returned an invalid response. Try again.',
    );
  }

  Future<List<PlaceSuggestion>> autocomplete(String input) async {
    final query = input.trim();
    if (query.length < 2) {
      resetSession();
      return const [];
    }
    await initialize();
    if (_disposed || !isConfigured) {
      throw const PlacesException(
        'Place search is not configured. You can still select a map pin.',
      );
    }

    final uri = Uri.https('places.googleapis.com', '/v1/places:autocomplete');
    final session = _session ??= _newSession();
    final response = await _client
        .post(
          uri,
          headers: _headers(
            'suggestions.placePrediction.placeId,suggestions.placePrediction.text,suggestions.placePrediction.structuredFormat',
          ),
          body: jsonEncode({
            'input': query,
            'includedRegionCodes': ['gh'],
            'languageCode': 'en',
            'sessionToken': session,
          }),
        )
        .timeout(const Duration(seconds: 8));
    final predictions = _decode(response)['suggestions'] ?? const [];
    if (predictions is! List) {
      throw const PlacesException('Place suggestions could not be verified.');
    }
    return [
      for (final item in predictions)
        if (item is Map && item['placePrediction'] is Map)
          _suggestion(item['placePrediction'] as Map, session),
    ].whereType<PlaceSuggestion>().toList();
  }

  PlaceSuggestion? _suggestion(Map item, String session) {
    final id = item['placeId'], text = item['text'];
    final description = text is Map ? text['text'] : null;
    if (id is! String ||
        id.trim().isEmpty ||
        description is! String ||
        description.trim().isEmpty) {
      return null;
    }
    String? part(String key) {
      final format = item['structuredFormat'];
      final value = format is Map ? format[key] : null;
      return value is Map && value['text'] is String
          ? value['text'] as String
          : null;
    }

    return PlaceSuggestion(
      placeId: id,
      description: description,
      mainText: part('mainText'),
      secondaryText: part('secondaryText'),
      sessionToken: session,
    );
  }

  Future<Location> fetchPlace(String placeId, {String? sessionToken}) async {
    await initialize();
    if (_disposed || !isConfigured || placeId.trim().isEmpty) {
      throw const PlacesException('Google Places API key is not configured.');
    }

    final session = sessionToken ?? _session;
    // Selecting a place ends the active search session immediately. Typing a
    // new query while details are in flight must use a fresh token.
    if (_session == session) resetSession();
    try {
      final uri = Uri.https(
        'places.googleapis.com',
        '/v1/places/${Uri.encodeComponent(placeId)}',
        {'languageCode': 'en', 'sessionToken': ?session},
      );

      final response = await _client
          .get(
            uri,
            headers: _headers('id,formattedAddress,location,addressComponents'),
          )
          .timeout(const Duration(seconds: 8));
      final result = _decode(response);
      final point = result['location'];
      final latitude = point is Map ? point['latitude'] : null;
      final longitude = point is Map ? point['longitude'] : null;
      if (result['id'] != placeId ||
          latitude is! num ||
          longitude is! num ||
          !latitude.isFinite ||
          !longitude.isFinite ||
          latitude.abs() > 90 ||
          longitude.abs() > 180) {
        throw const PlacesException(
          'Place coordinates could not be verified. Select a map pin instead.',
        );
      }
      final components =
          result['addressComponents'] as List<dynamic>? ?? const [];

      return Location(
        formattedAddress:
            result['formattedAddress'] as String? ?? 'Selected map location',
        latitude: latitude.toDouble(),
        longitude: longitude.toDouble(),
        locality: _component(components, const [
          'locality',
          'sublocality',
          'administrative_area_level_2',
        ]),
        administrativeArea: _component(components, const [
          'administrative_area_level_1',
        ]),
        country: _component(components, const ['country']),
        assembly: reportAssemblyFor(
          Region.fromAdministrativeArea(
            _component(components, const ['administrative_area_level_1']),
          ),
          [
            _component(components, const ['administrative_area_level_2']),
            _component(components, const ['administrative_area_level_3']),
          ],
        ),
      );
    } finally {
      if (_session == session) resetSession();
    }
  }

  void dispose() {
    _disposed = true;
    resetSession();
    _client.close();
  }

  String _component(List<dynamic> components, List<String> acceptedTypes) {
    for (final component in components) {
      if (component is! Map<String, dynamic>) continue;
      final map = component;
      final types = (map['types'] as List<dynamic>? ?? const []).cast<String>();
      if (acceptedTypes.any(types.contains)) {
        return map['longText'] as String? ?? '';
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
