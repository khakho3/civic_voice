import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/admin/models/admin_role_management_data.dart';
import 'package:civic_voice/features/admin/models/admin_user_management_data.dart';
import 'package:civic_voice/features/admin/screens/admin_user_details_screen.dart';
import 'package:civic_voice/features/admin/services/admin_user_directory.dart';
import 'package:civic_voice/models/app_role.dart';
import 'package:civic_voice/services/mock_auth_service.dart';
import 'package:civic_voice/widgets/app_dropdown_field.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final directory = AdminUserDirectory.instance;
  final own = mockAdminUsers().firstWhere(
    (u) => u.role == AppRole.systemAdministrator,
  );
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    directory.currentApiUserId = own.apiRecordId;
  });
  tearDown(() async {
    directory.invalidateAndClear();
    directory.firebaseAvailableForTesting = null;
    directory.tokenProviderForTesting = null;
    directory.updateUserForTesting = null;
    directory.deleteUserForTesting = null;
    await MockAuthService().clearUser();
  });
  test(
    'self save, deactivate and delete are rejected before token or network access',
    () async {
      var calls = 0;
      directory.firebaseAvailableForTesting = true;
      directory.tokenProviderForTesting = () async {
        calls++;
        return 'fixture';
      };
      directory.updateUserForTesting = (_, _, _) async {
        calls++;
        return {};
      };
      directory.deleteUserForTesting = (_, _) async {
        calls++;
      };
      await expectLater(directory.saveOnServer(own), throwsStateError);
      await expectLater(directory.toggleActiveOnServer(own), throwsStateError);
      await expectLater(directory.deleteOnServer(own), throwsStateError);
      expect(calls, 0);
      expect(directory.pendingMutationCount, 0);
    },
  );
  for (final tier in AdminTier.values) {
    testWidgets('own $tier details remain viewable without edit controls', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await MockAuthService().initialize();
      await MockAuthService().selectRole(
        AppRole.systemAdministrator,
        adminTier: tier,
      );
      tester.view.physicalSize = const Size(412, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminUserDetailsScreen(user: own),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Your own account is read-only here'),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate((w) => w is AppDropdownField),
        findsNothing,
      );
      final save = find.widgetWithText(FilledButton, 'Save Changes');
      await tester.scrollUntilVisible(save, 300);
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
      expect(find.text('Save access changes?'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('status sits beside role with wrapping at large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final citizen = mockAdminUsers()
        .firstWhere((u) => u.role == AppRole.citizen)
        .copyWith(status: AdminUserStatus.active);
    for (final scale in [1.0, 1.5]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: AdminUserDetailsScreen(key: ValueKey(scale), user: citizen),
        ),
      );
      await tester.pumpAndSettle();
      if (scale == 1) {
        final role = tester.getRect(find.text('Citizen').first);
        final status = tester.getRect(find.text('Active').first);
        expect((role.center.dy - status.center.dy).abs(), lessThan(2));
        expect(status.left, greaterThan(role.right));
      }
      expect(tester.takeException(), isNull);
    }
  });
}
