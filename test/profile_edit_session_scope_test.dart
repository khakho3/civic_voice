import 'dart:async';

import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/services/app_cache_service.dart';
import 'package:civic_voice/widgets/profile_name_edit_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppCacheService.instance.initialize();
    await AppCacheService.instance.activateAccount('fixture-owner');
  });

  Future<void> open(
    WidgetTester tester,
    Future<bool> Function(String) save,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showProfileNameEditSheet(
                context,
                initialName: 'Fixture A',
                onSave: save,
              ),
              child: const Text('Edit'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Entered name');
  }

  testWidgets(
    'an editor opened by another account cannot submit to the new account',
    (tester) async {
      var writes = 0;
      await open(tester, (_) async {
        writes++;
        return true;
      });
      await AppCacheService.instance.activateAccount('new-owner');
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();
      expect(writes, 0);
      expect(find.byType(ProfileNameEditSheet), findsOneWidget);
      expect(find.text('Entered name'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'a late save cannot close an editor after same-UID reactivation',
    (tester) async {
      final pending = Completer<bool>();
      await open(tester, (_) => pending.future);
      await tester.tap(find.text('Save changes'));
      await tester.pump();
      await AppCacheService.instance.activateAccount('fixture-owner');
      pending.complete(true);
      await tester.pumpAndSettle();
      expect(find.byType(ProfileNameEditSheet), findsOneWidget);
      expect(find.text('Entered name'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('an unchanged editor saves and closes normally', (tester) async {
    String? saved;
    await open(tester, (name) async {
      saved = name;
      return true;
    });
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(saved, 'Entered name');
    expect(find.byType(ProfileNameEditSheet), findsNothing);
  });
}
