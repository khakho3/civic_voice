import 'package:civic_voice/features/ministry/models/ministry_dashboard_data.dart';
import 'package:civic_voice/features/ministry/screens/ministry_dashboard_screen.dart';
import 'package:civic_voice/features/ministry/services/ministry_data_directory.dart';
import 'package:civic_voice/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'missing dashboard data is unavailable, while confirmed empty data shows zero',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: MinistryDashboardScreen()),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(find.text('Unable to Load Dashboard'), findsOneWidget);
      expect(find.text('Welcome to the national dashboard'), findsNothing);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MinistryDashboardScreen(data: MinistryDashboardData.zero),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Unable to Load Dashboard'), findsNothing);
      expect(find.text('Welcome to the national dashboard'), findsOneWidget);
    },
  );

  testWidgets(
    'real route follows first-load failure, loading and confirmed empty snapshot',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final directory = MinistryDataDirectory.instance;
      directory.clearSession();
      addTearDown(directory.clearSession);
      await tester.pumpWidget(
        const app.CivicVoiceApp(initialRoute: app.AppRoutes.ministryDashboard),
      );
      await tester.pumpAndSettle();
      expect(find.text('Unable to Load Dashboard'), findsOneWidget);
      directory.state.value = MinistryDataDirectoryState.loading;
      await tester.pump();
      expect(find.text('Unable to Load Dashboard'), findsNothing);
      directory.state.value = MinistryDataDirectoryState.failed;
      await tester.pumpAndSettle();
      expect(find.text('Unable to Load Dashboard'), findsOneWidget);
      expect(find.text('Welcome to the national dashboard'), findsNothing);
      directory.hasLiveSnapshot = true;
      directory.state.value = MinistryDataDirectoryState.loaded;
      await tester.pumpAndSettle();
      expect(find.text('Welcome to the national dashboard'), findsOneWidget);
      expect(find.text('Unable to Load Dashboard'), findsNothing);
    },
  );
  testWidgets(
    'failed retry stays unavailable without an unhandled async error',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MinistryDashboardScreen(
            onRefresh: () async {
              throw StateError('offline');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Try again'));
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Unable to Load Dashboard'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
