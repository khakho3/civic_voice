import 'dart:convert';
import 'dart:async';

import 'package:civic_voice/features/citizen/services/places_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('civic_voice/config');
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (call) async => {
            'apiKey': 'unit-key',
            'androidPackage': 'test.civic.dev',
            'androidCert': List.filled(20, 'AB').join(),
          },
        );
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );
  Map<String, Object> prediction() => {
    'placePrediction': {
      'placeId': 'p1',
      'text': {'text': 'Wusuta, Ghana'},
      'structuredFormat': {
        'mainText': {'text': 'Wusuta'},
        'secondaryText': {'text': 'Ghana'},
      },
    },
  };
  Map<String, Object> details() => {
    'id': 'p1',
    'formattedAddress': 'Wusuta, Ghana',
    'location': {'latitude': 6.9, 'longitude': 0.3},
    'addressComponents': [
      {
        'longText': 'Wusuta',
        'types': ['locality'],
      },
      {
        'longText': 'Volta Region',
        'types': ['administrative_area_level_1'],
      },
      {
        'longText': 'Ghana',
        'types': ['country'],
      },
    ],
  };
  test(
    'New autocomplete/details share session and mobile restrictions; next session is fresh',
    () async {
      final sessions = <String>[];
      final subject = PlacesService(
        client: MockClient((request) async {
          expect(request.url.host, 'places.googleapis.com');
          expect(request.url.queryParameters, isNot(contains('key')));
          expect(request.headers['X-Goog-Api-Key'], 'unit-key');
          expect(request.headers['X-Android-Package'], 'test.civic.dev');
          expect(
            request.headers['X-Android-Cert'],
            List.filled(20, 'AB').join(),
          );
          if (request.method == 'POST') {
            expect(request.url.path, '/v1/places:autocomplete');
            final body = jsonDecode(request.body) as Map;
            expect(body['includedRegionCodes'], ['gh']);
            expect(body.containsKey('includedPrimaryTypes'), isFalse);
            final token = body['sessionToken'] as String;
            // Google rejects tokens longer than 36 URL-safe ASCII characters.
            expect(token.length, inInclusiveRange(1, 36));
            expect(token, matches(RegExp(r'^[A-Za-z0-9_-]+$')));
            sessions.add(token);
            return http.Response(
              jsonEncode({
                'suggestions': [
                  {
                    'queryPrediction': {
                      'text': {'text': 'Not a place'},
                    },
                  },
                  {
                    'placePrediction': {'placeId': ''},
                  },
                  prediction(),
                ],
              }),
              200,
            );
          }
          expect(request.url.path, '/v1/places/p1');
          expect(request.url.queryParameters['sessionToken'], sessions.first);
          expect(
            request.headers['X-Goog-FieldMask'],
            'id,formattedAddress,location,addressComponents',
          );
          return http.Response(jsonEncode(details()), 200);
        }),
      );
      addTearDown(subject.dispose);
      final first = await subject.autocomplete('Wusuta');
      expect(first.length, 1);
      expect(first.single.mainText, 'Wusuta');
      await subject.autocomplete('Wusuta Ghana');
      expect(sessions[0], sessions[1]);
      final selected = await subject.fetchPlace(
        'p1',
        sessionToken: first.single.sessionToken,
      );
      expect(selected.latitude, 6.9);
      expect(selected.locality, 'Wusuta');
      await subject.autocomplete('Accra');
      expect(sessions.last, isNot(sessions.first));
    },
  );
  test(
    'a new search during details uses a fresh session that the old detail cannot clear',
    () async {
      final sessions = <String>[];
      final detailResponse = Completer<http.Response>();
      final detailSent = Completer<void>();
      final subject = PlacesService(
        client: MockClient((request) async {
          if (request.method == 'POST') {
            sessions.add(jsonDecode(request.body)['sessionToken'] as String);
            return http.Response(
              jsonEncode({
                'suggestions': [prediction()],
              }),
              200,
            );
          }
          detailSent.complete();
          return detailResponse.future;
        }),
      );
      addTearDown(subject.dispose);
      final first = await subject.autocomplete('Accra');
      final old = subject.fetchPlace(
        'p1',
        sessionToken: first.single.sessionToken,
      );
      await detailSent.future;
      await subject.autocomplete('Kumasi');
      detailResponse.complete(http.Response(jsonEncode(details()), 200));
      await old;
      await subject.autocomplete('Kumasi Ghana');
      expect(sessions[1], isNot(sessions[0]));
      expect(sessions[2], sessions[1]);
    },
  );
  test(
    'clearing the query resets its session without making a request',
    () async {
      final sessions = <String>[];
      final subject = PlacesService(
        client: MockClient((request) async {
          sessions.add(jsonDecode(request.body)['sessionToken'] as String);
          return http.Response('{}', 200);
        }),
      );
      addTearDown(subject.dispose);
      await subject.autocomplete('Accra');
      expect(await subject.autocomplete(''), isEmpty);
      await subject.autocomplete('Kumasi');
      expect(sessions.length, 2);
      expect(sessions.first, isNot(sessions.last));
    },
  );
  for (final status in [403, 429, 503]) {
    test(
      'HTTP $status does not expose provider diagnostics or fall back to legacy',
      () async {
        var requests = 0;
        final subject = PlacesService(
          client: MockClient((_) async {
            requests++;
            return http.Response(
              '{"error":{"message":"private provider key diagnostic"}}',
              status,
            );
          }),
        );
        addTearDown(subject.dispose);
        await expectLater(
          subject.autocomplete('Accra'),
          throwsA(
            isA<PlacesException>().having(
              (e) => e.message.contains('private provider'),
              'private diagnostic',
              false,
            ),
          ),
        );
        expect(requests, 1);
      },
    );
  }
  for (final mutation in <String, Object>{
    'id': 'other',
    'location': {'latitude': 91, 'longitude': 0},
  }.entries) {
    test(
      'invalid detail ${mutation.key} cannot become a selected pin',
      () async {
        final subject = PlacesService(
          client: MockClient(
            (_) async => http.Response(
              jsonEncode({...details(), mutation.key: mutation.value}),
              200,
            ),
          ),
        );
        addTearDown(subject.dispose);
        await expectLater(
          subject.fetchPlace('p1'),
          throwsA(isA<PlacesException>()),
        );
      },
    );
  }
  test(
    'native iOS bundle restriction is preserved on the New request',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (_) async => {
              'apiKey': 'ios-unit-key',
              'iosBundleIdentifier': 'test.civic.ios',
            },
          );
      final subject = PlacesService(
        client: MockClient((request) async {
          expect(request.headers['X-Ios-Bundle-Identifier'], 'test.civic.ios');
          expect(request.headers.containsKey('X-Android-Package'), isFalse);
          return http.Response('{}', 200);
        }),
      );
      addTearDown(subject.dispose);
      expect(await subject.autocomplete('Accra'), isEmpty);
    },
  );
}
