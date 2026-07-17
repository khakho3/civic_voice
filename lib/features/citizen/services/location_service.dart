import 'dart:async';

import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/location.dart';

enum LocationAccessStatus {
  ready,
  permissionDenied,
  permissionDeniedForever,
  gpsDisabled,
  unavailable,
}

class LocationAccessResult {
  const LocationAccessResult({
    required this.status,
    this.position,
    this.message,
  });

  final LocationAccessStatus status;
  final Position? position;
  final String? message;
}

class LocationService {
  const LocationService();

  /// Checks GPS/permission state without fetching a position — for callers
  /// that only need to know whether location access is usable (e.g. a
  /// dashboard nag banner), not an actual GPS fix. [requestCurrentPosition]
  /// does the same permission dance internally before fetching a position;
  /// this is the lighter-weight half of that logic for status-only checks.
  Future<LocationAccessStatus> checkAccessStatus({
    required bool requestPermission,
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return LocationAccessStatus.gpsDisabled;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && requestPermission) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return LocationAccessStatus.permissionDenied;
    }
    if (permission == LocationPermission.deniedForever) {
      return LocationAccessStatus.permissionDeniedForever;
    }
    return LocationAccessStatus.ready;
  }

  Future<LocationAccessResult> requestCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationAccessResult(
          status: LocationAccessStatus.gpsDisabled,
          message: 'Turn on phone location to select an accurate report place.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return const LocationAccessResult(
          status: LocationAccessStatus.permissionDenied,
          message: 'Allow location permission to detect your current place.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationAccessResult(
          status: LocationAccessStatus.permissionDeniedForever,
          message: 'Location permission is blocked. Open app settings.',
        );
      }

      final fresh = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 15),
        ),
      );

      return LocationAccessResult(
        status: LocationAccessStatus.ready,
        position: fresh,
      );
    } on TimeoutException {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return LocationAccessResult(
          status: LocationAccessStatus.ready,
          position: lastKnown,
          message: 'Using your most recent known location.',
        );
      }
      return const LocationAccessResult(
        status: LocationAccessStatus.unavailable,
        message: 'Location is taking too long. Move near a window and retry.',
      );
    } on LocationServiceDisabledException {
      return const LocationAccessResult(
        status: LocationAccessStatus.gpsDisabled,
        message: 'Turn on phone location to select an accurate report place.',
      );
    } on PermissionDeniedException {
      return const LocationAccessResult(
        status: LocationAccessStatus.permissionDenied,
        message: 'Allow location permission to detect your current place.',
      );
    } catch (_) {
      return const LocationAccessResult(
        status: LocationAccessStatus.unavailable,
        message: 'Location is unavailable. Check GPS and connection.',
      );
    }
  }

  Future<Location> reverseGeocode(LatLng target) async {
    final places = await geocoding.Geocoding()
        .placemarkFromCoordinates(target.latitude, target.longitude)
        .timeout(const Duration(seconds: 8));

    if (places.isEmpty) {
      return Location(
        formattedAddress: 'Selected map location',
        latitude: target.latitude,
        longitude: target.longitude,
        locality: '',
        administrativeArea: '',
        country: '',
      );
    }

    final place = places.first;
    return Location(
      formattedAddress: _formatAddress(place),
      latitude: target.latitude,
      longitude: target.longitude,
      landmark: _firstNonEmpty([
        place.name,
        place.thoroughfare,
        place.subThoroughfare,
      ]),
      locality: _firstNonEmpty([
        place.locality,
        place.subLocality,
        place.subAdministrativeArea,
      ]),
      administrativeArea: _clean(place.administrativeArea),
      country: _clean(place.country),
    );
  }

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  String _formatAddress(geocoding.Placemark place) {
    final parts = _dedupe(
      [
        place.street,
        place.subLocality,
        place.locality,
        place.administrativeArea,
        place.country,
      ].map(_clean).where((part) => part.isNotEmpty),
    );

    return parts.isEmpty ? 'Selected map location' : parts.join(', ');
  }

  List<String> _dedupe(Iterable<String> parts) {
    final seen = <String>{};
    final result = <String>[];
    for (final part in parts) {
      final key = part.toLowerCase();
      if (seen.add(key)) result.add(part);
    }
    return result;
  }

  String _firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      final clean = _clean(value);
      if (clean.isNotEmpty) return clean;
    }
    return '';
  }

  String _clean(String? value) => value?.trim() ?? '';
}
