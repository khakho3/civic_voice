import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:civic_voice/services/api_client.dart';
import 'package:civic_voice/features/citizen/services/profile_crud_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'trust_standing_data_test.dart' show standingPayload, standingUser;

void main() {
  late String? owner;
  late Future<SyncedUser> Function(String) sync;
  late ProfileCrudService service;
  setUp(() {
    owner = 'uid-A';
    sync = (_) async => SyncedUser.fromJson(standingUser());
    service = ProfileCrudService.forTesting(
      account: () => owner,
      credential: () async => 'fixture-token',
      sync: (token) => sync(token),
    );
    service.loadSignedInUser(SyncedUser.fromJson(standingUser()));
  });
  test(
    'latest refresh wins and does not overwrite an intervening name edit',
    () async {
      final first = Completer<SyncedUser>(), second = Completer<SyncedUser>();
      var count = 0;
      sync = (_) => count++ == 0 ? first.future : second.future;
      final a = service.refreshStanding();
      await Future<void>.delayed(Duration.zero);
      final b = service.refreshStanding();
      await Future<void>.delayed(Duration.zero);
      service.profile.value = service.profile.value.copyWith(
        fullName: 'Edited name',
      );
      second.complete(
        SyncedUser.fromJson(standingUser(rating: standingPayload(stars: 4))),
      );
      await b;
      first.complete(
        SyncedUser.fromJson(
          standingUser(rating: standingPayload(stars: 2, low: true)),
        ),
      );
      await a;
      expect(service.profile.value.trustRating!.stars, 4);
      expect(service.profile.value.fullName, 'Edited name');
    },
  );
  test('old failure cannot cross logout and a new account', () async {
    final pending = Completer<SyncedUser>();
    sync = (_) => pending.future;
    final request = service.refreshStanding();
    await Future<void>.delayed(Duration.zero);
    service.clearSession();
    owner = 'uid-B';
    service.loadSignedInUser(
      SyncedUser.fromJson(
        standingUser(uid: 'uid-B', id: 'B', rating: standingPayload(stars: 5)),
      ),
    );
    pending.completeError(StateError('old request failed'));
    await request;
    expect(service.profile.value.id, 'B');
    expect(service.profile.value.trustRating!.stars, 5);
  });
  test(
    'a token completing after account switch dispatches no request or old standing',
    () async {
      final token = Completer<String?>();
      var requests = 0;
      service = ProfileCrudService.forTesting(
        account: () => owner,
        credential: () => token.future,
        sync: (_) async {
          requests++;
          return SyncedUser.fromJson(standingUser());
        },
      );
      service.loadSignedInUser(SyncedUser.fromJson(standingUser()));
      final pending = service.refreshStanding();
      owner = 'uid-B';
      token.complete('old');
      await pending;
      expect(requests, 0);
      expect(service.profile.value.trustRating, isNull);
    },
  );
  test(
    'failed, missing and malformed standing hide the old value without losing identity',
    () async {
      for (final mode in ['failed', 'missing', 'malformed']) {
        service.loadSignedInUser(SyncedUser.fromJson(standingUser()));
        sync = (_) async {
          if (mode == 'failed') throw StateError('service unavailable');
          final raw = standingUser();
          raw['trustRating'] = mode == 'missing' ? null : {'stars': 5};
          return SyncedUser.fromJson(raw);
        };
        await service.refreshStanding();
        expect(service.profile.value.id, 'account-A');
        expect(service.profile.value.trustRating, isNull);
      }
    },
  );
  for (final changed in ['uid', 'id', 'role', 'guest', 'inactive']) {
    test('unverified $changed in a refresh cannot supply standing', () async {
      sync = (_) async => SyncedUser.fromJson(
        standingUser(
          uid: changed == 'uid' ? 'other' : 'uid-A',
          id: changed == 'id' ? 'other' : 'account-A',
          role: changed == 'role' ? 'ADMIN' : 'CITIZEN',
          guest: changed == 'guest',
          active: changed != 'inactive',
        ),
      );
      await service.refreshStanding();
      expect(service.profile.value.trustRating, isNull);
    });
  }
  test(
    'old success cannot restore standing after logout and a new account',
    () async {
      final pending = Completer<SyncedUser>();
      sync = (_) => pending.future;
      final request = service.refreshStanding();
      await Future<void>.delayed(Duration.zero);
      service.clearSession();
      owner = 'uid-B';
      service.loadSignedInUser(
        SyncedUser.fromJson(
          standingUser(
            uid: 'uid-B',
            id: 'B',
            rating: standingPayload(stars: 5),
          ),
        ),
      );
      pending.complete(SyncedUser.fromJson(standingUser()));
      await request;
      expect(service.profile.value.id, 'B');
      expect(service.profile.value.trustRating!.stars, 5);
    },
  );
  for (final switchAccount in [false, true]) {
    test(
      'a name save preserves fresh standing and ownership switch=$switchAccount',
      () async {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        final previous = ApiClient.baseUrl;
        ApiClient.baseUrl = 'http://127.0.0.1:${server.port}';
        addTearDown(() async {
          ApiClient.baseUrl = previous;
          await server.close(force: true);
        });
        final received = Completer<void>(), release = Completer<void>();
        server.listen((request) async {
          expect(request.method, 'PATCH');
          expect(request.uri.path, '/api/auth/me');
          await utf8.decoder.bind(request).join();
          received.complete();
          await release.future;
          request.response.headers.contentType = ContentType.json;
          request.response.write(jsonEncode({'user': standingUser()}));
          await request.response.close();
        });
        final saving = service
            .updateProfile(
              service.profile.value.copyWith(fullName: 'Edited name'),
            )
            .then<Object?>(
              (profile) => profile,
              onError: (Object error) => error,
            );
        await received.future;
        sync = (_) async => SyncedUser.fromJson(
          standingUser(rating: standingPayload(stars: 4)),
        );
        await service.refreshStanding();
        if (switchAccount) {
          owner = 'uid-B';
          service.clearSession();
          service.loadSignedInUser(
            SyncedUser.fromJson(
              standingUser(
                uid: 'uid-B',
                id: 'B',
                rating: standingPayload(stars: 5),
              ),
            ),
          );
        }
        release.complete();
        final result = await saving;
        if (switchAccount) {
          expect(result, isA<StateError>());
          expect(service.profile.value.id, 'B');
          expect(service.profile.value.trustRating!.stars, 5);
        } else {
          expect(result, isNot(isA<StateError>()));
          expect(service.profile.value.fullName, 'Edited name');
          expect(service.profile.value.trustRating!.stars, 4);
        }
      },
    );
  }
  test('guest and cleared sessions do not request standing', () async {
    var calls = 0;
    sync = (_) async {
      calls++;
      return SyncedUser.fromJson(standingUser());
    };
    service.loadSignedInUser(SyncedUser.fromJson(standingUser(guest: true)));
    await service.refreshStanding();
    service.clearSession();
    await service.refreshStanding();
    expect(calls, 0);
    expect(service.profile.value.trustRating, isNull);
  });
  test(
    'actual HTTP auth-sync response reaches the bound profile and refreshed standing',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final previous = ApiClient.baseUrl;
      ApiClient.baseUrl = 'http://127.0.0.1:${server.port}';
      addTearDown(() async {
        ApiClient.baseUrl = previous;
        await server.close(force: true);
      });
      var stars = 3.5, calls = 0;
      server.listen((request) async {
        expect(request.method, 'POST');
        expect(request.uri.path, '/api/auth/sync');
        expect(request.headers.value('authorization'), 'Bearer fixture-token');
        calls++;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'user': standingUser(
              rating: standingPayload(stars: stars, low: true),
            ),
          }),
        );
        await request.response.close();
      });
      sync = (token) => ApiClient.instance.syncUser(idToken: token);
      service.loadSignedInUser(await sync('fixture-token'));
      stars = 2;
      await service.refreshStanding();
      expect(calls, 2);
      expect(service.profile.value.trustRating!.stars, 2);
      expect(service.profile.value.trustRating!.lowStanding, isTrue);
    },
  );
}
