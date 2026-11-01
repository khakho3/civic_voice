import 'dart:async';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/core/widgets/ghana_refresh_indicator.dart';
import 'package:civic_voice/features/admin/screens/admin_report_routing_screen.dart';
import 'package:civic_voice/features/admin/services/admin_routing_repository.dart';
import 'package:civic_voice/models/region.dart';
import 'package:civic_voice/services/app_cache_service.dart';
import 'package:civic_voice/widgets/app_dropdown_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_report_routing_test.dart' show routingFixture, routingAck;

Map<String, dynamic> uiReport({bool resolved = false}) => {
  ...routingFixture(resolved: resolved),
  'photoUrls': <String>[],
  'latitude': null,
  'longitude': null,
};
Future<void> chooseAssembly(WidgetTester tester) async {
  final assembly = find.byType(AppDropdownField<String>);
  await tester.ensureVisible(assembly);
  await tester.pumpAndSettle();
  await tester.tap(assembly);
  await tester.pumpAndSettle();
  final search = find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.hintText == 'Search…',
  );
  await tester.enterText(search, 'Ga Central');
  await tester.pumpAndSettle();
  await tester.tap(find.text('Ga Central Municipal Assembly'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byType(TextField));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byType(TextField),
    'Checked the recorded pin and issue address.',
  );
  await tester.pump();
  await tester.ensureVisible(find.text('Confirm routing area'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppCacheService.instance.initialize(accountId: 'routing-widgets');
  });
  for (final dark in [false, true]) {
    testWidgets(
      'routing queue pull refresh stays below app bar and keeps the list dark=$dark',
      (tester) async {
        tester.view.physicalSize = Size(dark ? 320 : 412, 900);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPadding);
        final pending = Completer<Map<String, dynamic>>();
        var calls = 0;
        final page = {
          'reports': [uiReport()],
          'total': 1,
          'nextCursor': null,
        };
        final repo = AdminRoutingRepository(
          owner: () => 'super-A',
          credential: () async => 'fixture',
          list: (_, _, _) => ++calls == 1 ? Future.value(page) : pending.future,
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: AdminReportRoutingScreen(repository: repo),
          ),
        );
        await tester.pumpAndSettle();
        final report = find.text('Broken road');
        final element = tester.element(report);
        final position = tester.getRect(report);
        final barBottom = tester.getBottomLeft(find.byType(AppBar)).dy;
        final list = tester.getRect(find.byType(ListView));
        await tester.dragFrom(
          Offset(list.left + 24, list.top + 40),
          const Offset(0, 300),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 600));
        expect(calls, 2);
        final bar = find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == '_GhanaLinearProgress',
        );
        expect(bar, findsOneWidget);
        expect(tester.getTopLeft(bar).dy, closeTo(barBottom, 0.1));
        expect(tester.element(report), same(element));
        expect(tester.getRect(report), position);
        expect(find.byType(GhanaLoadingIndicator), findsNothing);
        pending.complete(page);
        await tester.pumpAndSettle();
        expect(bar, findsNothing);
        expect(tester.getRect(report), position);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'routing detail refresh preserves unsaved reason and makes no write dark=$dark',
      (tester) async {
        tester.view.physicalSize = Size(dark ? 320 : 412, 900);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPadding);
        var calls = 0, writes = 0;
        final pending = Completer<Map<String, dynamic>>();
        final repo = AdminRoutingRepository(
          owner: () => 'super-A',
          credential: () async => 'fixture',
          read: (_, _) => ++calls == 1
              ? Future.value({'report': uiReport()})
              : pending.future,
          write: (_, _, _) async {
            writes++;
            return routingAck();
          },
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: AdminReportRoutingDetailScreen(
              id: 'report-one',
              repository: repo,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await chooseAssembly(tester);
        final reason = tester
            .widget<TextField>(find.byType(TextField))
            .controller!
            .text;
        final scroll = tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position;
        scroll.jumpTo(0);
        await tester.pumpAndSettle();
        final state = tester.state<CustomRefreshIndicatorState>(
          find.byType(CustomRefreshIndicator),
        );
        unawaited(state.refresh(draggingDuration: Duration.zero));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(calls, 2);
        final bar = find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == '_GhanaLinearProgress',
        );
        expect(
          tester.getTopLeft(bar).dy,
          closeTo(tester.getBottomLeft(find.byType(AppBar)).dy, 0.1),
        );
        expect(find.text('Broken road'), findsOneWidget);
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          reason,
        );
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );
        pending.complete({'report': uiReport()});
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          reason,
        );
        expect(
          tester
              .widget<AppDropdownField<String>>(
                find.byType(AppDropdownField<String>),
              )
              .value,
          'Ga Central',
        );
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNotNull,
        );
        expect(writes, 0);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'slow initial routing pull suppresses page loading text dark=$dark',
      (tester) async {
        final first = Completer<Map<String, dynamic>>();
        final refresh = Completer<Map<String, dynamic>>();
        var calls = 0;
        final repo = AdminRoutingRepository(
          owner: () => 'super-A',
          credential: () async => 'fixture',
          list: (_, _, _) => ++calls == 1 ? first.future : refresh.future,
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: AdminReportRoutingScreen(repository: repo),
          ),
        );
        await tester.pump();
        expect(find.text('Loading report routing'), findsOneWidget);
        final state = tester.state<CustomRefreshIndicatorState>(
          find.byType(CustomRefreshIndicator),
        );
        unawaited(state.refresh(draggingDuration: Duration.zero));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(calls, 2);
        expect(find.text('Loading report routing'), findsNothing);
        expect(tester.getSize(find.byType(GhanaLoadingIndicator)).height, 0);
        expect(
          find.byWidgetPredicate(
            (w) => w.runtimeType.toString() == '_GhanaLinearProgress',
          ),
          findsOneWidget,
        );
        first.complete({
          'reports': [uiReport()],
          'total': 1,
          'nextCursor': null,
        });
        await tester.pump();
        expect(find.text('Broken road'), findsNothing);
        refresh.complete({
          'reports': <Map<String, dynamic>>[],
          'total': 0,
          'nextCursor': null,
        });
        await tester.pumpAndSettle();
        expect(
          find.text('No reports are waiting for locality resolution.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
    for (final width in [320.0, 390.0, 412.0, 1440.0]) {
      testWidgets(
        'routing detail fits $width dark=$dark with dependent allowed geography',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final repo = AdminRoutingRepository(
            owner: () => 'super-A',
            credential: () async => 'fixture',
            read: (_, _) async => {'report': uiReport()},
          );
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              home: AdminReportRoutingDetailScreen(
                id: 'report-one',
                repository: repo,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('No saved issue pin.'), findsOneWidget);
          expect(
            tester
                .widget<AppDropdownField<Region>>(
                  find.byType(AppDropdownField<Region>),
                )
                .value,
            Region.greaterAccra,
          );
          expect(
            tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
            isNull,
          );
          await chooseAssembly(tester);
          expect(
            tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
            isNotNull,
          );
          // Changing region must clear the previous assembly, never carry an invalid pair.
          tester
              .widget<AppDropdownField<Region>>(
                find.byType(AppDropdownField<Region>),
              )
              .onChanged!(Region.ashanti);
          await tester.pump();
          expect(
            tester
                .widget<AppDropdownField<String>>(
                  find.byType(AppDropdownField<String>),
                )
                .value,
            isNull,
          );
          expect(
            tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
            isNull,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'confirmation is explicit; one matching write/read yields truthful zero-officer success',
    (tester) async {
      var writes = 0, resolved = false;
      final repo = AdminRoutingRepository(
        owner: () => 'super-A',
        credential: () async => 'fixture',
        read: (_, _) async => {'report': uiReport(resolved: resolved)},
        write: (_, _, body) async {
          writes++;
          expect(body['expectedUpdatedAt'], '2026-10-23T10:00:00.000Z');
          resolved = true;
          return {...routingAck(), 'report': uiReport(resolved: true)};
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminReportRoutingDetailScreen(
            id: 'report-one',
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await chooseAssembly(tester);
      await tester.tap(find.text('Confirm routing area'));
      await tester.pumpAndSettle();
      expect(writes, 0);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(writes, 0);
      await tester.tap(find.text('Confirm routing area'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save routing'));
      await tester.pumpAndSettle();
      expect(writes, 1);
      expect(find.text('Routing area saved'), findsOneWidget);
      expect(
        find.textContaining('No active Municipal officer'),
        findsOneWidget,
      );
      expect(find.textContaining('Audit collection is off'), findsOneWidget);
      expect(find.text('Confirm routing area'), findsNothing);
    },
  );
  testWidgets('conflict keeps reason, locks the save, and requires reload', (
    tester,
  ) async {
    var writes = 0;
    final repo = AdminRoutingRepository(
      owner: () => 'super-A',
      credential: () async => 'fixture',
      read: (_, _) async => {'report': uiReport()},
      write: (_, _, _) async {
        writes++;
        throw StateError('conflict');
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: AdminReportRoutingDetailScreen(
          id: 'report-one',
          repository: repo,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await chooseAssembly(tester);
    await tester.tap(find.text('Confirm routing area'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save routing'));
    await tester.pumpAndSettle();
    expect(writes, 1);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Checked the recorded pin and issue address.',
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.ensureVisible(find.text('Reload report'));
    await tester.tap(find.text('Reload report'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    expect(writes, 1);
  });
  testWidgets(
    'account change while confirmation is open cannot dispatch a write',
    (tester) async {
      String? owner = 'super-A';
      var writes = 0;
      final repo = AdminRoutingRepository(
        owner: () => owner,
        credential: () async => 'fixture',
        read: (_, _) async => {'report': uiReport()},
        write: (_, _, _) async {
          writes++;
          return routingAck();
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminReportRoutingDetailScreen(
            id: 'report-one',
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await chooseAssembly(tester);
      await tester.tap(find.text('Confirm routing area'));
      await tester.pumpAndSettle();
      owner = 'super-B';
      await tester.tap(find.text('Save routing'));
      await tester.pumpAndSettle();
      expect(writes, 0);
      expect(find.text('Broken road'), findsNothing);
    },
  );
  testWidgets(
    'unauthorized deep links dispatch no reads and locked reports have no editor',
    (tester) async {
      var calls = 0;
      final denied = AdminRoutingRepository(
        owner: () => null,
        credential: () async => 'fixture',
        read: (_, _) async {
          calls++;
          return {'report': uiReport()};
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminReportRoutingDetailScreen(
            id: 'report-one',
            repository: denied,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Super Admin access required'),
        findsOneWidget,
      );
      expect(calls, 0);
      final repo = AdminRoutingRepository(
        owner: () => 'super-A',
        credential: () async => 'fixture',
        read: (_, _) async => {
          'report': {
            ...uiReport(),
            'canRoute': false,
            'status': 'UNDER_REVIEW',
          },
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminReportRoutingDetailScreen(
            key: const ValueKey('locked'),
            id: 'report-one',
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Routing is locked'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    },
  );
  testWidgets(
    'queue pages and opens a fresh detail, rather than editing a list snapshot',
    (tester) async {
      final calls = <String>[];
      final repo = AdminRoutingRepository(
        owner: () => 'super-A',
        credential: () async => 'fixture',
        list: (_, q, c) async {
          calls.add('list:$q:$c');
          return {
            'reports': [uiReport()],
            'total': 2,
            'nextCursor': c == null ? 'next-page' : null,
          };
        },
        read: (_, id) async {
          calls.add('detail:$id');
          return {'report': uiReport()};
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminReportRoutingScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next page'));
      await tester.pumpAndSettle();
      expect(calls.last, 'list::next-page');
      await tester.tap(find.text('Broken road'));
      await tester.pumpAndSettle();
      expect(calls.last, 'detail:report-one');
      expect(find.text('Confirm the issue locality'), findsOneWidget);
    },
  );
}
