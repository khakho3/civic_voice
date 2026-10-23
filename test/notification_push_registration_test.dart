import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice/services/notification_push_registration.dart';

void main() {
  test('late old-account registration is cleaned before new binding', () async {
    String? owner = 'A';
    final pending = Completer<void>();
    final events = <String>[];
    final service = NotificationPushRegistration(
      owner: () => owner,
      credential: () async => owner,
      register: (auth, token) async {
        events.add('bind-$auth');
        if (auth == 'A') await pending.future;
      },
      unregister: (auth, token) async {
        events.add('remove-$auth');
      },
    );
    final a = service.bind('device-token');
    await Future<void>.delayed(Duration.zero);
    owner = 'B';
    final b = service.bind('device-token');
    pending.complete();
    await Future.wait([a, b]);
    expect(events, ['bind-A', 'remove-A', 'bind-B']);
  });
  test(
    'account switch while acquiring credentials prevents dispatch',
    () async {
      String? owner = 'A';
      final pending = Completer<String?>();
      var calls = 0;
      final service = NotificationPushRegistration(
        owner: () => owner,
        credential: () => pending.future,
        register: (_, _) async {
          calls++;
        },
        unregister: (_, _) async {
          calls++;
        },
      );
      final a = service.bind('device-token');
      await Future<void>.delayed(Duration.zero);
      owner = null;
      pending.complete('old-credential');
      await a;
      expect(calls, 0);
    },
  );
  test(
    'a failed old registration does not poison queue or expose another owner',
    () async {
      String? owner = 'A';
      final pending = Completer<void>();
      final events = <String>[];
      final service = NotificationPushRegistration(
        owner: () => owner,
        credential: () async => owner,
        register: (auth, _) async {
          events.add('bind-$auth');
          if (auth == 'A') {
            await pending.future;
            throw StateError('uncertain transport');
          }
        },
        unregister: (auth, _) async {
          events.add('remove-$auth');
        },
      );
      final a = service.bind('device-token');
      await Future<void>.delayed(Duration.zero);
      owner = 'B';
      final b = service.bind('device-token');
      owner = 'C';
      final c = service.bind('device-token');
      pending.complete();
      await Future.wait([a, b, c]);
      expect(events, ['bind-A', 'remove-A', 'bind-C']);
    },
  );
}
