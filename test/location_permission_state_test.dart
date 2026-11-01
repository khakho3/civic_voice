import 'package:civic_voice/features/citizen/services/location_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

class _PermissionPlatform extends GeolocatorPlatform {
  bool enabled = true;
  LocationPermission permission = LocationPermission.unableToDetermine;
  LocationPermission decision = LocationPermission.denied;
  int checks = 0, requests = 0, positions = 0;

  @override
  Future<bool> isLocationServiceEnabled() async => enabled;
  @override
  Future<LocationPermission> checkPermission() async {
    checks++;
    return permission;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    requests++;
    return decision;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    positions++;
    return Position(
      latitude: 5.6,
      longitude: -0.2,
      timestamp: DateTime.now(),
      accuracy: 8,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}

void main() {
  late GeolocatorPlatform previous;
  late _PermissionPlatform platform;
  const service = LocationService();
  setUp(() {
    previous = GeolocatorPlatform.instance;
    platform = _PermissionPlatform();
    GeolocatorPlatform.instance = platform;
  });
  tearDown(() => GeolocatorPlatform.instance = previous);

  for (final request in [false, true]) {
    test(
      'undetermined permission is unavailable rather than ready (request=$request)',
      () async {
        expect(
          await service.checkAccessStatus(requestPermission: request),
          LocationAccessStatus.unavailable,
        );
        expect(platform.requests, 0);
        expect(platform.positions, 0);
      },
    );
  }
  test(
    'a status-only resume preserves denied access without another OS request',
    () async {
      platform.permission = LocationPermission.denied;
      expect(
        await service.checkAccessStatus(requestPermission: false),
        LocationAccessStatus.permissionDenied,
      );
      expect(platform.requests, 0);
    },
  );
  test('an explicit request uses the actual granted decision', () async {
    platform.permission = LocationPermission.denied;
    platform.decision = LocationPermission.whileInUse;
    expect(
      await service.checkAccessStatus(requestPermission: true),
      LocationAccessStatus.ready,
    );
    expect(platform.requests, 1);
  });
  test(
    'permanent denial never attempts an ineffective OS permission request',
    () async {
      platform.permission = LocationPermission.deniedForever;
      expect(
        await service.checkAccessStatus(requestPermission: true),
        LocationAccessStatus.permissionDeniedForever,
      );
      expect(platform.requests, 0);
    },
  );
  test('disabled GPS is distinct from permission state', () async {
    platform.enabled = false;
    expect(
      await service.checkAccessStatus(requestPermission: true),
      LocationAccessStatus.gpsDisabled,
    );
    expect(platform.checks, 0);
    expect(platform.requests, 0);
  });
  for (final permission in [
    LocationPermission.whileInUse,
    LocationPermission.always,
  ]) {
    test(
      'existing $permission grant is usable without another prompt',
      () async {
        platform.permission = permission;
        expect(
          await service.checkAccessStatus(requestPermission: true),
          LocationAccessStatus.ready,
        );
        expect(platform.requests, 0);
        expect(platform.positions, 0);
      },
    );
  }
  test(
    'explicit acquisition can still obtain a real fix when a browser cannot query permission',
    () async {
      final result = await service.requestCurrentPosition();
      expect(result.status, LocationAccessStatus.ready);
      expect(result.position?.latitude, 5.6);
      expect(platform.positions, 1);
    },
  );
}
