import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/admin/models/admin_overview.dart';
import 'package:civic_voice/features/admin/screens/admin_overview_screen.dart';
import 'package:civic_voice/features/admin/screens/admin_alerts_screen.dart';
import 'package:civic_voice/features/admin/services/admin_resource.dart';
import 'admin_live_overview_test.dart' show overviewFixture, alertFixture;

void main() {
  for (final dark in [false, true]) {
    for (final width in [320.0, 412.0]) {
      testWidgets(
        'live dashboard $width dark=$dark uses server totals and compact alert navigation',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final resource = AdminResource<AdminOverview>(
            fetch: (_) async => overviewFixture(),
            parse: AdminOverview.parse,
            owner: () => 'fixture-admin',
            credential: () async => 'fixture',
          );
          addTearDown(resource.dispose);
          var alerts = 0;
          void nothing() {}
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              home: AdminOverviewScreen(
                directory: resource,
                superAdmin: false,
                onUsers: nothing,
                onTeams: nothing,
                onActivity: nothing,
                onAlerts: () {
                  alerts++;
                },
                onRoles: nothing,
                onSettings: nothing,
                onProfile: nothing,
                onNotifications: nothing,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('1234'), findsOneWidget);
          expect(find.text('601'), findsOneWidget);
          expect(find.text('7'), findsOneWidget);
          expect(find.text('Assembly Overview'), findsOneWidget);
          expect(find.text('System Settings'), findsNothing);
          expect(find.textContaining('route handoff'), findsNothing);
          expect(find.text('View alert events'), findsNothing);
          await tester.tap(find.text('Open alerts'));
          expect(alerts, 1);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'alert review confirms a versioned action and displays refreshed state',
    (tester) async {
      var state = 'OPEN', revision = 0, calls = 0;
      final resource = AdminResource<AdminAlertDetail>(
        owner: () => 'fixture-admin',
        credential: () async => 'fixture',
        fetch: (_) async => {
          'alert': alertFixture(state: state, revision: revision),
          'actions': [],
          'actionCount': 0,
        },
        parse: AdminAlertDetail.parse,
      );
      addTearDown(resource.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminAlertReviewScreen(
            id: 'event-one',
            resource: resource,
            save: (token, action, expected, note) async {
              calls++;
              expect(action, 'ACKNOWLEDGE');
              expect(expected, 0);
              expect(note, 'I am investigating this change.');
              state = 'ACKNOWLEDGED';
              revision = 1;
              return {
                'review': {
                  'state': state,
                  'revision': revision,
                  'updatedAt': '2026-10-23T12:00:00Z',
                },
              };
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Acknowledge'),
            )
            .onPressed,
        isNull,
      );
      await tester.enterText(
        find.byType(TextField),
        'I am investigating this change.',
      );
      await tester.pump();
      await tester.tap(find.text('Acknowledge'));
      await tester.pumpAndSettle();
      expect(calls, 0);
      await tester.tap(find.text('Save review'));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(find.text('ALERT · ACKNOWLEDGED'), findsOneWidget);
      expect(find.text('Acknowledge'), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'unconfirmed alert write keeps note and locks further actions until reload',
    (tester) async {
      final resource = AdminResource<AdminAlertDetail>(
        owner: () => 'fixture-admin',
        credential: () async => 'fixture',
        fetch: (_) async => {
          'alert': alertFixture(),
          'actions': [],
          'actionCount': 0,
        },
        parse: AdminAlertDetail.parse,
      );
      addTearDown(resource.dispose);
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: AdminAlertReviewScreen(
            id: 'event-one',
            resource: resource,
            save: (_, _, _, _) async {
              calls++;
              return {
                'review': {
                  'state': 'RESOLVED',
                  'revision': 99,
                  'updatedAt': '2026-10-23T12:00:00Z',
                },
              };
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        'Investigated and corrected configuration.',
      );
      await tester.pump();
      await tester.tap(find.text('Resolve'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save review'));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(resource.uncertain, isTrue);
      expect(
        find.textContaining('The change could not be confirmed'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Resolve'))
            .onPressed,
        isNull,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isNotEmpty,
      );
      await tester.scrollUntilVisible(
        find.text('Reload alert'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(
        tester.element(find.text('Reload alert')),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reload alert'));
      await tester.pumpAndSettle();
      expect(resource.uncertain, isFalse);
    },
  );
  testWidgets(
    'closed alert offers reopen and never directly acknowledges a resolution',
    (tester) async {
      final resource = AdminResource<AdminAlertDetail>(
        owner: () => 'fixture-admin',
        credential: () async => 'fixture',
        fetch: (_) async => {
          'alert': alertFixture(state: 'RESOLVED', revision: 2),
          'actions': [],
          'actionCount': 0,
        },
        parse: AdminAlertDetail.parse,
      );
      addTearDown(resource.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminAlertReviewScreen(id: 'event-one', resource: resource),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Reopen'), findsOneWidget);
      expect(find.text('Acknowledge'), findsNothing);
      expect(find.text('Resolve'), findsNothing);
    },
  );
  testWidgets(
    'alert list uses compact whole-card navigation without a review button',
    (tester) async {
      final resources = <AdminResource<AdminAlertPage>>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminAlertsScreen(
            resourceFactory: (state, query, cursor) {
              final resource = AdminResource<AdminAlertPage>(
                owner: () => 'fixture-admin',
                credential: () async => 'fixture',
                fetch: (_) async => {
                  'alerts': [alertFixture()],
                  'total': 1,
                  'nextCursor': null,
                },
                parse: AdminAlertPage.parse,
              );
              resources.add(resource);
              return resource;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('System setting changed'), findsOneWidget);
      expect(find.text('Review alert'), findsNothing);
      expect(find.text('Active'), findsOneWidget);
      expect(tester.takeException(), isNull);
      // The screen owns and disposes its page resource.
      await tester.pumpWidget(const SizedBox.shrink());
      expect(resources, isNotEmpty);
    },
  );
}
