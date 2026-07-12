import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/location.dart';
import '../services/location_service.dart';
import '../services/places_service.dart';

class LocationPickerController extends ChangeNotifier {
  LocationPickerController({
    this._locationService = const LocationService(),
    PlacesService? placesService,
    Location? initialLocation,
  }) : _placesService = placesService ?? PlacesService(),
       selectedLocation = initialLocation,
       _cameraTarget = initialLocation?.target ?? _fallbackTarget;

  static const LatLng _fallbackTarget = LatLng(6.5244, 3.3792);

  final LocationService _locationService;
  final PlacesService _placesService;
  GoogleMapController? _mapController;
  Timer? _searchDebounce;
  int _resolveSerial = 0;
  int _searchSerial = 0;

  LatLng _cameraTarget;
  Location? selectedLocation;
  List<PlaceSuggestion> suggestions = const [];
  bool initializing = true;
  bool resolvingAddress = false;
  bool searching = false;
  String? statusMessage;
  LocationAccessStatus accessStatus = LocationAccessStatus.unavailable;

  LatLng get cameraTarget => _cameraTarget;
  bool get placesConfigured => _placesService.isConfigured;
  String? get mapConfigurationWarning {
    if (placesConfigured) return null;
    return 'Google Maps API key is missing. Map tiles and search may appear blank.';
  }

  CameraPosition get initialCameraPosition {
    return CameraPosition(target: _cameraTarget, zoom: 16);
  }

  Future<void> initialize() async {
    initializing = true;
    statusMessage = 'Detecting your current location...';
    notifyListeners();
    await useCurrentLocation(animate: false);
    initializing = false;
    notifyListeners();
  }

  void attachMap(GoogleMapController controller) {
    _mapController = controller;
    final location = selectedLocation;
    if (location != null) {
      _animateTo(location.target, zoom: 17);
    }
  }

  void onCameraMove(CameraPosition position) {
    _cameraTarget = position.target;
  }

  Future<void> onCameraIdle() {
    return _resolveTarget(_cameraTarget);
  }

  Future<void> useCurrentLocation({bool animate = true}) async {
    resolvingAddress = true;
    statusMessage = 'Detecting your current location...';
    notifyListeners();

    final result = await _locationService.requestCurrentPosition();
    accessStatus = result.status;
    statusMessage = result.message;

    if (result.status == LocationAccessStatus.ready &&
        result.position != null) {
      final position = result.position!;
      final target = LatLng(position.latitude, position.longitude);
      _cameraTarget = target;
      if (animate) await _animateTo(target, zoom: 17);
      await _resolveTarget(target);
      return;
    }

    resolvingAddress = false;
    notifyListeners();
  }

  void search(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _runSearch(query);
    });
  }

  Future<void> selectSuggestion(PlaceSuggestion suggestion) async {
    searching = false;
    suggestions = const [];
    resolvingAddress = true;
    statusMessage = 'Opening selected location...';
    notifyListeners();

    try {
      final location = await _placesService.fetchPlace(suggestion.placeId);
      selectedLocation = location;
      _cameraTarget = location.target;
      await _animateTo(location.target, zoom: 17);
      statusMessage = null;
    } catch (error) {
      statusMessage = error.toString();
    } finally {
      resolvingAddress = false;
      notifyListeners();
    }
  }

  Future<Location?> confirmSelection() async {
    if (selectedLocation != null) return selectedLocation;
    await _resolveTarget(_cameraTarget);
    return selectedLocation;
  }

  Future<void> openSettingsForCurrentState() async {
    if (accessStatus == LocationAccessStatus.gpsDisabled) {
      await _locationService.openLocationSettings();
      return;
    }
    if (accessStatus == LocationAccessStatus.permissionDeniedForever) {
      await _locationService.openAppSettings();
      return;
    }
    await useCurrentLocation();
  }

  Future<void> _runSearch(String query) async {
    final serial = ++_searchSerial;
    if (query.trim().length < 2) {
      suggestions = const [];
      searching = false;
      notifyListeners();
      return;
    }

    searching = true;
    statusMessage = placesConfigured ? null : 'Google Places API key missing.';
    notifyListeners();

    try {
      final results = await _placesService.autocomplete(query);
      if (serial != _searchSerial) return;
      suggestions = results;
      statusMessage = null;
    } catch (error) {
      if (serial != _searchSerial) return;
      suggestions = const [];
      statusMessage = error.toString();
    } finally {
      if (serial == _searchSerial) {
        searching = false;
        notifyListeners();
      }
    }
  }

  Future<void> _resolveTarget(LatLng target) async {
    final serial = ++_resolveSerial;
    resolvingAddress = true;
    statusMessage = 'Finding address...';
    notifyListeners();

    try {
      final location = await _locationService.reverseGeocode(target);
      if (serial != _resolveSerial) return;
      selectedLocation = location;
      statusMessage = null;
    } catch (_) {
      if (serial != _resolveSerial) return;
      statusMessage = 'Could not find this address. Move the map and retry.';
    } finally {
      if (serial == _resolveSerial) {
        resolvingAddress = false;
        notifyListeners();
      }
    }
  }

  Future<void> _animateTo(LatLng target, {required double zoom}) async {
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: zoom),
      ),
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _mapController?.dispose();
    _placesService.dispose();
    super.dispose();
  }
}
