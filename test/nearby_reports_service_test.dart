import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:civic_voice/features/citizen/services/location_service.dart';
import 'package:civic_voice/features/citizen/services/nearby_reports_service.dart';
import 'package:civic_voice/features/citizen/widgets/nearby_seconding_card.dart';
import 'package:civic_voice/services/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

final now = DateTime.utc(2026, 10, 22, 12);
Position fix({double accuracy = 5, double latitude = 5.6, int age = 0}) =>
    Position(
      longitude: -0.2,
      latitude: latitude,
      timestamp: now.subtract(Duration(milliseconds: age)),
      accuracy: accuracy,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

class Locations extends LocationService {
  Locations(this.read);
  final Future<LocationAccessResult> Function() read;
  int calls = 0;
  @override
  Future<LocationAccessResult> requestCurrentPosition() {
    calls++;
    return read();
  }
}

Locations located(Position p) => Locations(
  () async =>
      LocationAccessResult(status: LocationAccessStatus.ready, position: p),
);
const report = NearbySecondingReport(
  id: 'report-1',
  reference: 'CV-1',
  title: 'Drain',
  category: 'Sanitation',
  distanceMeters: 10,
  seconderCount: 0,
  latitude: 5.6,
  longitude: -0.2,
);

void main() {
  for (final p in [
    fix(age: 60001),
    fix(age: -10001),
    fix(accuracy: 101),
    fix(accuracy: double.nan),
    fix(latitude: double.infinity),
  ]) {
    test(
      'invalid device fix never reaches nearby API: ${p.accuracy}/${p.timestamp}/${p.latitude}',
      () async {
        var requests = 0;
        final service = NearbyReportsService(
          locationService: located(p),
          now: () => now,
          account: () => 'one',
          token: () async => 'token',
          discover: (_, _) async {
            requests++;
            return [];
          },
          confirm: (_, _, _) async {
            requests++;
          },
        );
        await expectLater(service.discover(), throwsA(isA<ApiException>()));
        await expectLater(
          service.confirm(report),
          throwsA(isA<ApiException>()),
        );
        expect(requests, 0);
      },
    );
  }
  test(
    'confirmation reacquires GPS and does not use the earlier discovery fix',
    () async {
      var current = fix();
      final positions = <Position>[];
      final locations = Locations(
        () async => LocationAccessResult(
          status: LocationAccessStatus.ready,
          position: current,
        ),
      );
      final service = NearbyReportsService(
        locationService: locations,
        now: () => now,
        account: () => 'one',
        token: () async => 'token',
        discover: (_, p) async {
          positions.add(p);
          return [];
        },
        confirm: (_, id, p) async {
          expect(id, report.id);
          positions.add(p);
        },
      );
      await service.discover();
      current = fix(age: 1);
      await service.confirm(report);
      expect(locations.calls, 2);
      expect(positions, [fix(), current]);
    },
  );
  test(
    'distant GPS cannot second even if discovery previously returned the report',
    () async {
      var sent = false;
      final service = NearbyReportsService(
        locationService: located(fix(latitude: 5.7)),
        now: () => now,
        account: () => 'one',
        token: () async => 'token',
        confirm: (_, _, _) async {
          sent = true;
        },
      );
      await expectLater(service.confirm(report), throwsA(isA<ApiException>()));
      expect(sent, false);
    },
  );
  test(
    'account switch while location pending does not read token or send request',
    () async {
      final pending = Completer<LocationAccessResult>();
      var owner = 'one';
      var tokens = 0;
      final service = NearbyReportsService(
        locationService: Locations(() => pending.future),
        now: () => now,
        account: () => owner,
        token: () async {
          tokens++;
          return 'token';
        },
      );
      final future = service.discover();
      final assertion = expectLater(future, throwsA(isA<ApiException>()));
      owner = 'two';
      pending.complete(
        LocationAccessResult(
          status: LocationAccessStatus.ready,
          position: fix(),
        ),
      );
      await assertion;
      expect(tokens, 0);
    },
  );
  test('late discovery result after account switch is discarded', () async {
    final pending = Completer<List<Map<String, dynamic>>>();
    var owner = 'one';
    final service = NearbyReportsService(
      locationService: located(fix()),
      now: () => now,
      account: () => owner,
      token: () async => 'token',
      discover: (_, _) => pending.future,
    );
    final future = service.discover();
    final assertion = expectLater(future, throwsA(isA<ApiException>()));
    await Future<void>.delayed(Duration.zero);
    owner = 'two';
    pending.complete([]);
    await assertion;
  });
  test('permission denial never calls discovery', () async {
    var sent = false;
    final service = NearbyReportsService(
      locationService: Locations(
        () async => const LocationAccessResult(
          status: LocationAccessStatus.permissionDenied,
        ),
      ),
      account: () => 'one',
      discover: (_, _) async {
        sent = true;
        return [];
      },
    );
    await expectLater(service.discover(), throwsA(isA<ApiException>()));
    expect(sent, false);
  });
  for (final confirming in [false, true]) {
    test(
      'GPS expiry during token refresh blocks ${confirming ? "confirmation" : "discovery"}',
      () async {
        var clock = now;
        var writes = 0;
        final service = NearbyReportsService(
          locationService: located(fix()),
          now: () => clock,
          account: () => 'one',
          token: () async {
            clock = clock.add(const Duration(seconds: 61));
            return 'token';
          },
          discover: (_, _) async {
            writes++;
            return [];
          },
          confirm: (_, _, _) async {
            writes++;
          },
        );
        await expectLater(
          confirming ? service.confirm(report) : service.discover(),
          throwsA(isA<ApiException>()),
        );
        expect(writes, 0);
      },
    );
  }
  test(
    'transport sends exact fresh position metadata and requires confirmed response',
    () async {
      final previous = ApiClient.baseUrl;
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      ApiClient.baseUrl = 'http://127.0.0.1:${server.port}';
      addTearDown(() async {
        ApiClient.baseUrl = previous;
        await server.close(force: true);
      });
      var calls = 0;
      server.listen((request) async {
        calls++;
        expect(request.headers.value('authorization'), 'Bearer token');
        final position = {
          'latitude': 5.6,
          'longitude': -0.2,
          'accuracy': 5.0,
          'capturedAt': '2026-10-22T12:00:00.000Z',
        };
        request.response.headers.contentType = ContentType.json;
        if (request.method == 'GET') {
          expect(request.uri.path, '/api/reports/nearby-seconding');
          expect(
            request.uri.queryParameters,
            position.map((k, v) => MapEntry(k, '$v')),
          );
          request.response.write('{"reports":[]}');
        } else {
          expect(request.uri.path, '/api/reports/report-1/second');
          expect(jsonDecode(await utf8.decoder.bind(request).join()), position);
          request.response.write(calls == 2 ? '{"secondedByMe":true}' : '{}');
        }
        await request.response.close();
      });
      await ApiClient.instance.fetchNearbySeconding(
        idToken: 'token',
        latitude: 5.6,
        longitude: -0.2,
        accuracy: 5,
        capturedAt: now,
      );
      Future<void> confirm() => ApiClient.instance.secondReport(
        'report-1',
        idToken: 'token',
        latitude: 5.6,
        longitude: -0.2,
        accuracy: 5,
        capturedAt: now,
      );
      await confirm();
      await expectLater(confirm(), throwsA(isA<ApiException>()));
    },
  );
}
