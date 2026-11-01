import 'dart:async';
import 'package:civic_voice/features/citizen/models/report_draft.dart';
import 'package:civic_voice/models/app_role.dart';
import 'package:civic_voice/services/api_client.dart';
import 'package:civic_voice/services/app_cache_service.dart';
import 'package:civic_voice/services/auth_transitions.dart';
import 'package:civic_voice/services/mock_auth_service.dart';
import 'package:civic_voice/services/notification_directory.dart';
import 'package:civic_voice/services/session_actions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const draft = ReportDraft(
  title: 'Synthetic retained draft',
  description: 'Fixture',
  category: 'Road',
  location: 'Fixture',
  community: 'Fixture',
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppCacheService.instance.initialize(accountId: 'guest-fixture');
    await NotificationDirectory.instance.initialize();
    await MockAuthService().initialize();
    await MockAuthService().selectRole(AppRole.citizen);
    await AppCacheService.instance.setKeepSignedIn(true);
    await AppCacheService.instance.saveReportDraft(draft);
    final original = ApiClient.baseUrl;
    ApiClient.baseUrl = 'http://127.0.0.1:1';
    addTearDown(() => ApiClient.baseUrl = original);
  });

  test(
    'local publication failure preserves a reused identity preference and durable draft',
    () async {
      await expectLater(
        AuthTransitions.instance.run<void>((lease) async {
          lease.requireCleanupFor('guest-fixture');
          throw StateError('Synthetic publication failure');
        }, onFailure: clearFailedAuthTransition),
        throwsStateError,
      );
      expect(MockAuthService().getCurrentRole(), isNull);
      expect(AppCacheService.instance.keepSignedIn, true);
      await AppCacheService.instance.activateAccount('guest-fixture');
      expect(AppCacheService.instance.reportDraft?.title, draft.title);
    },
  );

  test(
    'owned failure cannot clear a different verified local namespace',
    () async {
      await AppCacheService.instance.activateAccount('newer-fixture');
      await AppCacheService.instance.saveReportDraft(draft);
      await MockAuthService().selectRole(AppRole.ministrySupervisor);
      await expectLater(
        AuthTransitions.instance.run<void>((lease) async {
          lease.recordSdkUser('old-fixture');
          throw StateError('Synthetic old failure');
        }, onFailure: clearFailedAuthTransition),
        throwsStateError,
      );
      expect(MockAuthService().getCurrentRole(), AppRole.ministrySupervisor);
      expect(AppCacheService.instance.activeAccountId, 'newer-fixture');
      expect(AppCacheService.instance.reportDraft?.title, draft.title);
      expect(AppCacheService.instance.keepSignedIn, true);
    },
  );

  test(
    'shared logout waits for pending work then clears local scope once without deleting its draft',
    () async {
      final sdk = Completer<void>(), entered = Completer<void>();
      final job = AuthTransitions.instance
          .run<void>((lease) async {
            entered.complete();
            await sdk.future;
            lease.recordSdkUser('guest-fixture');
            lease.check();
          }, onFailure: clearFailedAuthTransition)
          .catchError((Object error) {
            expect(error, isA<AuthTransitionInterrupted>());
          });
      await entered.future;
      final first = endSession(), second = endSession();
      expect(first, same(second));
      expect(MockAuthService().getCurrentRole(), AppRole.citizen);
      sdk.complete();
      await job;
      await first;
      expect(MockAuthService().getCurrentRole(), isNull);
      expect(AppCacheService.instance.activeAccountId, isNull);
      expect(AppCacheService.instance.keepSignedIn, false);
      await AppCacheService.instance.activateAccount('guest-fixture');
      expect(AppCacheService.instance.reportDraft?.title, draft.title);
    },
  );
}
