import 'dart:async';
import 'package:civic_voice/services/auth_transitions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'logout waits for SDK completion, cancels publication and deduplicates cleanup',
    () async {
      final transitions = AuthTransitions(), sdk = Completer<void>();
      final entered = Completer<void>();
      var published = false, cleanups = 0;
      final login = transitions
          .run((lease) async {
            entered.complete();
            await sdk.future;
            lease.recordSdkUser('old-fixture');
            lease.check();
            published = true;
          })
          .catchError((Object error) {
            expect(error, isA<AuthTransitionInterrupted>());
          });
      await entered.future;
      final first = transitions.close(() async {
        cleanups++;
      });
      final second = transitions.close(() async {
        cleanups++;
      });
      expect(first, same(second));
      expect(cleanups, 0);
      await expectLater(
        transitions.run((_) async {}),
        throwsA(isA<AuthTransitionBusy>()),
      );
      sdk.complete();
      await login;
      await first;
      expect(published, false);
      expect(cleanups, 1);
      expect(transitions.isBusy, false);
      expect(await transitions.run((_) async => 'new-fixture'), 'new-fixture');
    },
  );

  test(
    'route cancellation cleans only its own SDK work before another pipeline can start',
    () async {
      final transitions = AuthTransitions(),
          sdk = Completer<void>(),
          cleanup = Completer<void>();
      final entered = Completer<AuthTransitionLease>(),
          cleaning = Completer<void>();
      final job = transitions
          .run(
            (lease) async {
              entered.complete(lease);
              await sdk.future;
              lease.recordSdkUser('owned-fixture');
              lease.check();
            },
            onFailure: (lease) async {
              expect(transitions.owns(lease), true);
              expect(lease.cleanupUid, 'owned-fixture');
              cleaning.complete();
              await cleanup.future;
            },
          )
          .catchError((Object error) {
            expect(error, isA<AuthTransitionInterrupted>());
          });
      (await entered.future).cancel();
      sdk.complete();
      await cleaning.future;
      await expectLater(
        transitions.run((_) async {}),
        throwsA(isA<AuthTransitionBusy>()),
      );
      cleanup.complete();
      await job;
      expect(await transitions.run((_) async => true), true);
    },
  );

  test(
    'a failure before SDK mutation preserves the existing session',
    () async {
      final transitions = AuthTransitions();
      var cleanups = 0;
      await expectLater(
        transitions.run<void>(
          (_) async {
            throw StateError('fixture');
          },
          onFailure: (_) async {
            cleanups++;
          },
        ),
        throwsStateError,
      );
      expect(cleanups, 0);
      expect(transitions.isBusy, false);
    },
  );

  test('a failed owned cleanup cannot poison subsequent transitions', () async {
    final transitions = AuthTransitions();
    await expectLater(
      transitions.run<void>(
        (lease) async {
          lease.recordSdkUser('fixture');
          throw StateError('original');
        },
        onFailure: (_) async {
          throw ArgumentError('cleanup');
        },
      ),
      throwsStateError,
    );
    expect(await transitions.run((_) async => true), true);
  });

  test('disposing an old lease cannot cancel a subsequent session', () async {
    final transitions = AuthTransitions();
    late AuthTransitionLease old;
    await transitions.run((lease) async {
      old = lease;
    });
    await transitions.run((lease) async {
      old.cancel();
      expect(lease.isCurrent, true);
    });
    expect(old.isLatest, false);
  });

  test(
    'new SDK identity supersedes an earlier password-save cleanup target',
    () async {
      final transitions = AuthTransitions();
      await transitions.run((lease) async {
        lease.requireCleanupFor('original');
        lease.recordSdkUser('exchanged');
        lease.requireCleanupFor('original');
        expect(lease.cleanupUid, 'exchanged');
      });
    },
  );

  test(
    'cleanup failure releases the logout barrier and retains its error',
    () async {
      final transitions = AuthTransitions();
      await expectLater(
        transitions.close(() async {
          throw StateError('fixture');
        }),
        throwsStateError,
      );
      expect(transitions.isBusy, false);
      expect(await transitions.run((_) async => true), true);
    },
  );
}
