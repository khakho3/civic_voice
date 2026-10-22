import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/location.dart';
import '../services/location_service.dart';
import '../services/places_service.dart';

/// The latest explicit GPS, search selection or map gesture owns the pin.
/// Initial/programmatic camera idle is never a citizen location selection.
class LocationPickerController extends ChangeNotifier {
  LocationPickerController({
    this.locationService = const LocationService(),
    PlacesService? placesService,
    Location? initialLocation,
  }) : _placesService = placesService ?? PlacesService(),
       selectedLocation = initialLocation,
       _cameraTarget = initialLocation?.target ?? _fallbackTarget;

  static const LatLng _fallbackTarget = LatLng(5.6037, -0.187);
  final LocationService locationService;
  final PlacesService _placesService;
  GoogleMapController? _mapController;
  Timer? _searchDebounce;
  int _operation = 0, _searchSerial = 0;
  bool _disposed = false, _manualMove = false, _programmaticMove = false;
  bool _detailsPending = false;
  LatLng _cameraTarget;
  Location? selectedLocation;
  List<PlaceSuggestion> suggestions = const [];
  bool initializing = true, resolvingAddress = false, searching = false;
  String? statusMessage;
  LocationAccessStatus accessStatus = LocationAccessStatus.unavailable;

  LatLng get cameraTarget => _cameraTarget;
  bool get placesConfigured => _placesService.isConfigured;
  String? get mapConfigurationWarning => initializing || placesConfigured
      ? null
      : 'Place search is not configured. Confirm the issue pin if map tiles are available.';
  CameraPosition get initialCameraPosition =>
      CameraPosition(target: _cameraTarget, zoom: 16);
  bool _owns(int serial) => !_disposed && serial == _operation;
  bool _samePoint(LatLng a, LatLng b) =>
      (a.latitude - b.latitude).abs() < 0.0000001 &&
      (a.longitude - b.longitude).abs() < 0.0000001;
  bool _valid(LatLng point) =>
      point.latitude.isFinite &&
      point.latitude.abs() <= 90 &&
      point.longitude.isFinite &&
      point.longitude.abs() <= 180;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    final serial = _operation;
    await _placesService.initialize();
    if (!_owns(serial)) return;
    // Reopening an explicitly selected pin must not replace it with home/GPS.
    if (selectedLocation != null) {
      initializing = false;
      _notify();
      return;
    }
    await useCurrentLocation();
  }

  void attachMap(GoogleMapController controller) {
    if (_disposed) return;
    _mapController = controller;
    if (selectedLocation != null) {
      unawaited(_animateTo(selectedLocation!.target));
    }
  }

  /// Called for a real touch pan even if it interrupts a camera animation.
  void beginMapGesture() {
    if (_disposed || _manualMove) return;
    ++_operation;
    _manualMove = true;
    _detailsPending = false;
    _programmaticMove = false;
    initializing = false;
    resolvingAddress = false;
    selectedLocation = null;
    statusMessage = 'Move the pin to the issue location.';
    _notify();
  }

  void onCameraMoveStarted() {
    if (!initializing && !_programmaticMove && selectedLocation != null) {
      beginMapGesture();
    }
  }

  void onCameraMove(CameraPosition position) {
    if (!_disposed && _valid(position.target)) _cameraTarget = position.target;
  }

  Future<void> onCameraIdle() async {
    if (_disposed) return;
    if (_programmaticMove) {
      _programmaticMove = false;
      return;
    }
    if (!_manualMove) return;
    _manualMove = false;
    await _resolveTarget(_cameraTarget, _operation);
  }

  Future<void> useCurrentLocation({bool animate = true}) async {
    if (_disposed) return;
    final serial = ++_operation;
    _manualMove = false;
    _detailsPending = false;
    selectedLocation = null;
    resolvingAddress = true;
    statusMessage = 'Detecting your current location...';
    _notify();
    LocationAccessResult result;
    try {
      result = await locationService.requestCurrentPosition().timeout(
        const Duration(seconds: 25),
      );
    } on TimeoutException {
      result = const LocationAccessResult(
        status: LocationAccessStatus.unavailable,
        message:
            'Location is taking too long. Try again or select the issue pin on the map.',
      );
    } catch (_) {
      result = const LocationAccessResult(
        status: LocationAccessStatus.unavailable,
        message:
            'Phone location is unavailable. Try again or select the issue pin on the map.',
      );
    }
    if (!_owns(serial)) return;
    initializing = false;
    accessStatus = result.status;
    statusMessage = result.message;
    final position = result.position;
    if (result.status != LocationAccessStatus.ready ||
        position == null ||
        !_valid(LatLng(position.latitude, position.longitude))) {
      resolvingAddress = false;
      _notify();
      return;
    }
    final target = LatLng(position.latitude, position.longitude);
    _cameraTarget = target;
    // Address resolution starts without waiting for a map animation callback.
    if (animate) unawaited(_animateTo(target));
    await _resolveTarget(target, serial);
    if (_owns(serial) && result.message != null) {
      statusMessage = result.message;
      _notify();
    }
  }

  void search(String query) {
    if (_disposed) return;
    if (_detailsPending) {
      ++_operation;
      _detailsPending = false;
      resolvingAddress = false;
      statusMessage = null;
    }
    _searchDebounce?.cancel();
    final serial = ++_searchSerial;
    suggestions = const [];
    searching = false;
    if (query.trim().length < 2) {
      _placesService.resetSession();
      _notify();
      return;
    }
    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      () => _runSearch(query, serial),
    );
    _notify();
  }

  Future<void> _runSearch(String query, int serial) async {
    if (_disposed || serial != _searchSerial) return;
    searching = true;
    _notify();
    try {
      final results = await _placesService.autocomplete(query);
      if (_disposed || serial != _searchSerial) return;
      suggestions = results;
      statusMessage = results.isEmpty
          ? 'No matching places. Try a nearby landmark or select a map pin.'
          : null;
    } catch (error) {
      if (_disposed || serial != _searchSerial) return;
      statusMessage = error is PlacesException
          ? error.message
          : 'Place search is unavailable. Try again or select a map pin.';
    } finally {
      if (!_disposed && serial == _searchSerial) {
        searching = false;
        _notify();
      }
    }
  }

  Future<void> selectSuggestion(PlaceSuggestion suggestion) async {
    if (_disposed) return;
    final serial = ++_operation;
    ++_searchSerial;
    _detailsPending = true;
    _searchDebounce?.cancel();
    searching = false;
    suggestions = const [];
    selectedLocation = null;
    _manualMove = false;
    initializing = false;
    resolvingAddress = true;
    statusMessage = 'Opening selected location...';
    _notify();
    try {
      final location = await _placesService.fetchPlace(
        suggestion.placeId,
        sessionToken: suggestion.sessionToken,
      );
      if (!_owns(serial)) return;
      _cameraTarget = location.target;
      selectedLocation = Location(
        formattedAddress: location.formattedAddress,
        latitude: location.latitude,
        longitude: location.longitude,
        locality: location.locality,
        administrativeArea: location.administrativeArea,
        country: location.country,
        assembly: location.assembly,
        landmark: location.landmark ?? suggestion.mainText,
      );
      statusMessage = null;
      unawaited(_animateTo(location.target));
    } catch (error) {
      if (_owns(serial)) {
        statusMessage = error is PlacesException
            ? error.message
            : 'Could not open this place. Try again or move the map pin.';
      }
    } finally {
      if (_owns(serial)) {
        _detailsPending = false;
        resolvingAddress = false;
        _notify();
      }
    }
  }

  Future<Location?> confirmSelection() async {
    final location = selectedLocation;
    return canConfirm ? location : null;
  }

  bool get canConfirm {
    final location = selectedLocation;
    return !_disposed &&
        !initializing &&
        !resolvingAddress &&
        !_manualMove &&
        location != null &&
        _samePoint(location.target, _cameraTarget);
  }

  Future<void> openSettingsForCurrentState() async {
    if (accessStatus == LocationAccessStatus.gpsDisabled) {
      await locationService.openLocationSettings();
      return;
    }
    if (accessStatus == LocationAccessStatus.permissionDeniedForever) {
      await locationService.openAppSettings();
      return;
    }
    await useCurrentLocation();
  }

  Future<void> _resolveTarget(LatLng target, int serial) async {
    if (!_owns(serial) || !_valid(target)) return;
    resolvingAddress = true;
    statusMessage = 'Finding address...';
    _notify();
    try {
      final location = await locationService
          .reverseGeocode(target)
          .timeout(const Duration(seconds: 8));
      if (!_owns(serial)) return;
      // Reverse-geocoder coordinates may be a nearby address centroid. The
      // selected pin remains the issue location and routing authority.
      selectedLocation = Location(
        formattedAddress: location.formattedAddress,
        latitude: target.latitude,
        longitude: target.longitude,
        locality: location.locality,
        administrativeArea: location.administrativeArea,
        country: location.country,
        landmark: location.landmark,
        assembly: location.assembly,
      );
      statusMessage = null;
    } catch (_) {
      if (!_owns(serial)) return;
      selectedLocation = Location(
        formattedAddress: 'Selected map location',
        latitude: target.latitude,
        longitude: target.longitude,
        locality: '',
        administrativeArea: '',
        country: '',
      );
      statusMessage =
          'Address unavailable. You can still confirm the selected issue pin.';
    } finally {
      if (_owns(serial)) {
        resolvingAddress = false;
        _notify();
      }
    }
  }

  Future<void> _animateTo(LatLng target) async {
    final map = _mapController;
    if (_disposed || map == null) return;
    _programmaticMove = true;
    try {
      await map.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 17),
        ),
      );
    } catch (_) {
      if (!_disposed) _programmaticMove = false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_operation;
    ++_searchSerial;
    _searchDebounce?.cancel();
    _mapController?.dispose();
    _placesService.dispose();
    super.dispose();
  }
}
