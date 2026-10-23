import 'dart:async';

import 'package:civic_voice/features/citizen/controllers/location_picker_controller.dart';
import 'package:civic_voice/features/citizen/models/location.dart';
import 'package:civic_voice/features/citizen/services/location_service.dart';
import 'package:civic_voice/features/citizen/services/places_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

Location place(double lat, double lng) => Location(
  formattedAddress: 'Chosen issue',
  latitude: lat,
  longitude: lng,
  locality: 'Community',
  administrativeArea: 'Greater Accra',
  country: 'Ghana',
);
LocationAccessResult gps(double lat, double lng) => LocationAccessResult(
  status: LocationAccessStatus.ready,
  position: Position(
    latitude: lat,
    longitude: lng,
    timestamp: DateTime.now(),
    accuracy: 8,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  ),
);

class _Location extends LocationService {
  _Location({this.position, this.reverse});
  final Future<LocationAccessResult> Function()? position;
  final Future<Location> Function(LatLng)? reverse;
  int requests = 0, reverses = 0;
  @override
  Future<LocationAccessResult> requestCurrentPosition() {
    requests++;
    return position?.call() ??
        Future.value(
          const LocationAccessResult(
            status: LocationAccessStatus.permissionDenied,
          ),
        );
  }

  @override
  Future<Location> reverseGeocode(LatLng point) {
    reverses++;
    return reverse?.call(point) ??
        Future.value(place(point.latitude, point.longitude));
  }
}

class _Places extends PlacesService {
  _Places({this.searchRequest, this.details});
  final Future<List<PlaceSuggestion>> Function(String)? searchRequest;
  final Future<Location> Function(String)? details;
  @override
  Future<void> initialize() async {}
  @override
  bool get isConfigured => true;
  @override
  Future<List<PlaceSuggestion>> autocomplete(String input) async =>
      searchRequest == null ? [] : searchRequest!(input);
  @override
  Future<Location> fetchPlace(String id, {String? sessionToken}) =>
      details?.call(id) ?? Future.value(place(6.5, -0.5));
}

const suggestion = PlaceSuggestion(
  placeId: 'place-1',
  description: 'Test place',
);

void main() {
  testWidgets(
    'drag clears search and shows lookup feedback until the pin settles',
    (tester) async {
      final lookup = Completer<Location>();
      final controller = LocationPickerController(
        initialLocation: place(6, -1),
        locationService: _Location(reverse: (_) => lookup.future),
        placesService: _Places(),
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      controller.search('Old query');
      controller.beginMapGesture();
      controller.onCameraMove(
        const CameraPosition(target: LatLng(7, -2), zoom: 16),
      );
      expect(controller.resolvingAddress, isTrue);
      expect(controller.statusMessage, 'Finding address...');
      expect(controller.canConfirm, isFalse);
      expect(controller.suggestions, isEmpty);
      final idle = controller.onCameraIdle();
      lookup.complete(place(7, -2));
      await idle;
      await tester.pump(const Duration(milliseconds: 301));
      expect(controller.resolvingAddress, isFalse);
      expect(controller.canConfirm, isTrue);
      expect(controller.selectedLocation!.target, const LatLng(7, -2));
    },
  );
  testWidgets(
    'typing another search cancels the previous place-detail selection',
    (tester) async {
      final details = Completer<Location>();
      final controller = LocationPickerController(
        placesService: _Places(details: (_) => details.future),
      );
      addTearDown(controller.dispose);
      final old = controller.selectSuggestion(suggestion);
      controller.search('New place');
      details.complete(place(6, -1));
      await old;
      await tester.pump(const Duration(milliseconds: 301));
      expect(controller.selectedLocation, isNull);
      expect(controller.resolvingAddress, isFalse);
      expect(controller.canConfirm, isFalse);
    },
  );
  testWidgets('unexpected GPS provider failure cannot leave capture spinning', (
    tester,
  ) async {
    final controller = LocationPickerController(
      locationService: _Location(
        position: () async => throw StateError('last-known provider failed'),
      ),
      placesService: _Places(),
    );
    addTearDown(controller.dispose);
    await controller.initialize();
    expect(controller.resolvingAddress, isFalse);
    expect(controller.initializing, isFalse);
    expect(controller.canConfirm, isFalse);
    expect(controller.statusMessage, contains('Phone location is unavailable'));
  });
  testWidgets(
    'selected suggestion keeps its known landmark without an extra detail field',
    (tester) async {
      final controller = LocationPickerController(placesService: _Places());
      addTearDown(controller.dispose);
      await controller.selectSuggestion(
        const PlaceSuggestion(
          placeId: 'p1',
          description: 'Named landmark, Ghana',
          mainText: 'Named landmark',
        ),
      );
      expect(controller.selectedLocation!.landmark, 'Named landmark');
      expect(controller.canConfirm, isTrue);
    },
  );
  testWidgets(
    'initial idle and denied GPS never select the fallback map center',
    (tester) async {
      final response = Completer<LocationAccessResult>();
      final source = _Location(position: () => response.future);
      final controller = LocationPickerController(
        locationService: source,
        placesService: _Places(),
      );
      addTearDown(controller.dispose);
      final init = controller.initialize();
      await tester.pump();
      controller.onCameraMoveStarted();
      await controller.onCameraIdle();
      expect(source.reverses, 0);
      response.complete(
        const LocationAccessResult(
          status: LocationAccessStatus.permissionDenied,
          message: 'Allow GPS',
        ),
      );
      await init;
      expect(await controller.confirmSelection(), isNull);
      expect(controller.statusMessage, 'Allow GPS');
    },
  );
  testWidgets(
    'saved issue pin is preserved when reopening, without capturing home GPS',
    (tester) async {
      final source = _Location();
      final controller = LocationPickerController(
        locationService: source,
        placesService: _Places(),
        initialLocation: place(7, -1),
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      expect(source.requests, 0);
      expect((await controller.confirmSelection())!.latitude, 7);
    },
  );
  testWidgets('a drag wins over late GPS and confirms the drag pin', (
    tester,
  ) async {
    final response = Completer<LocationAccessResult>();
    final controller = LocationPickerController(
      locationService: _Location(position: () => response.future),
      placesService: _Places(),
    );
    addTearDown(controller.dispose);
    final init = controller.initialize();
    await tester.pump();
    controller.beginMapGesture();
    controller.onCameraMove(
      const CameraPosition(target: LatLng(7, -1), zoom: 16),
    );
    await controller.onCameraIdle();
    response.complete(gps(5.6, -0.2));
    await init;
    expect((await controller.confirmSelection())!.latitude, 7);
    expect(controller.cameraTarget, const LatLng(7, -1));
  });
  testWidgets('a new drag invalidates an older reverse-geocode result', (
    tester,
  ) async {
    final first = Completer<Location>();
    final controller = LocationPickerController(
      locationService: _Location(
        reverse: (point) =>
            point.latitude == 7 ? first.future : Future.value(place(8, -2)),
      ),
      placesService: _Places(),
    );
    addTearDown(controller.dispose);
    controller.beginMapGesture();
    controller.onCameraMove(
      const CameraPosition(target: LatLng(7, -1), zoom: 16),
    );
    final old = controller.onCameraIdle();
    controller.beginMapGesture();
    expect(await controller.confirmSelection(), isNull);
    controller.onCameraMove(
      const CameraPosition(target: LatLng(8, -2), zoom: 16),
    );
    await controller.onCameraIdle();
    first.complete(place(7, -1));
    await old;
    expect((await controller.confirmSelection())!.latitude, 8);
  });
  testWidgets('late place details cannot replace a newer map gesture', (
    tester,
  ) async {
    final details = Completer<Location>();
    final controller = LocationPickerController(
      locationService: _Location(),
      placesService: _Places(details: (_) => details.future),
    );
    addTearDown(controller.dispose);
    final old = controller.selectSuggestion(suggestion);
    controller.beginMapGesture();
    controller.onCameraMove(
      const CameraPosition(target: LatLng(8, -2), zoom: 16),
    );
    await controller.onCameraIdle();
    details.complete(place(6, -1));
    await old;
    expect((await controller.confirmSelection())!.latitude, 8);
  });
  testWidgets('selected place wins over late initial GPS', (tester) async {
    final response = Completer<LocationAccessResult>();
    final controller = LocationPickerController(
      locationService: _Location(position: () => response.future),
      placesService: _Places(),
    );
    addTearDown(controller.dispose);
    final init = controller.initialize();
    await tester.pump();
    await controller.selectSuggestion(suggestion);
    response.complete(gps(5.6, -0.2));
    await init;
    expect((await controller.confirmSelection())!.latitude, 6.5);
  });
  testWidgets(
    'cleared query immediately invalidates the in-flight suggestion response',
    (tester) async {
      final response = Completer<List<PlaceSuggestion>>();
      final controller = LocationPickerController(
        placesService: _Places(searchRequest: (_) => response.future),
      );
      addTearDown(controller.dispose);
      controller.search('Accra');
      await tester.pump(const Duration(milliseconds: 301));
      expect(controller.searching, isTrue);
      controller.search('');
      response.complete([suggestion]);
      await tester.pump();
      expect(controller.suggestions, isEmpty);
      expect(controller.searching, isFalse);
    },
  );
  testWidgets(
    'new query invalidates old results during the next debounce interval',
    (tester) async {
      final response = Completer<List<PlaceSuggestion>>();
      final controller = LocationPickerController(
        placesService: _Places(
          searchRequest: (query) =>
              query == 'Accra' ? response.future : Future.value([]),
        ),
      );
      addTearDown(controller.dispose);
      controller.search('Accra');
      await tester.pump(const Duration(milliseconds: 301));
      controller.search('Kumasi');
      response.complete([suggestion]);
      await tester.pump();
      expect(controller.suggestions, isEmpty);
      await tester.pump(const Duration(milliseconds: 301));
      expect(controller.suggestions, isEmpty);
    },
  );
  testWidgets(
    'reverse-geocoder centroid never replaces measured issue coordinates',
    (tester) async {
      final controller = LocationPickerController(
        locationService: _Location(
          position: () async => gps(5.6, -0.2),
          reverse: (_) async => place(5.7, -0.3),
        ),
        placesService: _Places(),
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      final chosen = await controller.confirmSelection();
      expect(chosen!.latitude, 5.6);
      expect(chosen.longitude, -0.2);
    },
  );
  testWidgets(
    'address failure preserves the explicitly chosen pin for server routing',
    (tester) async {
      final controller = LocationPickerController(
        locationService: _Location(
          position: () async => gps(5.6, -0.2),
          reverse: (_) async => throw StateError('geocoder down'),
        ),
        placesService: _Places(),
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      expect((await controller.confirmSelection())!.latitude, 5.6);
      expect(controller.selectedLocation!.assembly, isNull);
      expect(controller.statusMessage, contains('Address unavailable'));
    },
  );
  testWidgets('late GPS after disposal cannot notify or set a pin', (
    tester,
  ) async {
    final response = Completer<LocationAccessResult>();
    final controller = LocationPickerController(
      locationService: _Location(position: () => response.future),
      placesService: _Places(),
    );
    final init = controller.initialize();
    await tester.pump();
    controller.dispose();
    response.complete(gps(5.6, -0.2));
    await init;
    expect(controller.selectedLocation, isNull);
    expect(tester.takeException(), isNull);
  });
}
