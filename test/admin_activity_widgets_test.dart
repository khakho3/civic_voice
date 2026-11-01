import 'dart:async';
import 'dart:convert';
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/core/widgets/ghana_refresh_indicator.dart';
import 'package:civic_voice/features/admin/screens/admin_activity_detail_screen.dart';
import 'package:civic_voice/features/admin/screens/admin_system_activity_screen.dart';
import 'package:civic_voice/features/admin/services/admin_activity_repository.dart';
import 'package:civic_voice/services/api_client.dart';
import 'package:civic_voice/services/app_cache_service.dart';
import 'package:civic_voice/widgets/app_dropdown_field.dart';
import 'package:civic_voice/widgets/civic_filter_chip.dart';
import 'package:civic_voice/widgets/form_section_card.dart';
import 'package:civic_voice/widgets/search_filter_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_activity_contract_test.dart' show auditFixture, auditPageFixture;

Future<void> showItem(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    220,
    scrollable: find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        .last,
  );
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    for (final font
        in jsonDecode(await rootBundle.loadString('FontManifest.json'))
            as List) {
      final loader = FontLoader(font['family']);
      for (final face in font['fonts']) {
        loader.addFont(rootBundle.load(face['asset']));
      }
      await loader.load();
    }
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppCacheService.instance.initialize(accountId: 'audit-fixture');
  });

  testWidgets(
    'recent Activity loads on first Last24 entry, refresh and preset changes with a microsecond clock',
    (tester) async {
      var now = DateTime.parse('2026-11-01T02:34:56.123456Z');
      final queries = <Map<String, String>>[];
      final repo = AdminActivityRepository(
        now: () => now,
        owner: () => 'admin',
        credential: () async => 'fixture',
        list: (_, query) async {
          queries.add(Map.of(query));
          // The API accepts timezone-qualified ISO instants with <=3 fraction digits.
          final from = query['from'];
          if (from != null &&
              !RegExp(
                r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$',
              ).hasMatch(from)) {
            throw const ApiException(
              statusCode: 400,
              message: 'Invalid from timestamp',
            );
          }
          return {
            ...auditPageFixture(),
            'activity': [
              {...auditFixture(), 'createdAt': '2026-11-01T02:30:00.000Z'},
            ],
          };
        },
      );
      Future<void> enter(String key) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: AdminSystemActivityScreen(
              key: ValueKey(key),
              repository: repo,
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await enter('first');
      expect(find.text('Account access updated'), findsOneWidget);
      expect(find.text('Last 24 Hours'), findsOneWidget);
      expect(queries.last, {'from': '2026-10-31T02:34:56.123Z'});
      now = now.add(const Duration(seconds: 12));
      await tester
          .widget<GhanaRefreshIndicator>(find.byType(GhanaRefreshIndicator))
          .onRefresh();
      await tester.pumpAndSettle();
      expect(queries.last, {'from': '2026-10-31T02:35:08.123Z'});
      expect(find.text('Account access updated'), findsOneWidget);
      final time = find.byKey(const ValueKey('activity-time-range'));
      final presetStarts = {
        'Last 7 Days': '2026-10-25T02:35:08.123Z',
        'Last 30 Days': '2026-10-02T02:35:08.123Z',
        'All Time': null,
        'Last 24 Hours': '2026-10-31T02:35:08.123Z',
      };
      for (final entry in presetStarts.entries) {
        await tester.tap(time);
        await tester.pumpAndSettle();
        await tester.tap(find.text(entry.key).last);
        await tester.pumpAndSettle();
        expect(find.text('Account access updated'), findsOneWidget);
        expect(queries.last, {if (entry.value != null) 'from': entry.value!});
      }
      expect(queries.last['from'], '2026-10-31T02:35:08.123Z');
      await tester.pumpWidget(const SizedBox());
      now = now.add(const Duration(hours: 1));
      await enter('reentry');
      expect(find.text('Last 24 Hours'), findsOneWidget);
      expect(find.text('Account access updated'), findsOneWidget);
      expect(queries.last, {'from': '2026-10-31T03:35:08.123Z'});
    },
  );

  testWidgets(
    'custom dates is a Time menu option and cancellation keeps the current query',
    (tester) async {
      final queries = <Map<String, String>>[];
      final repo = AdminActivityRepository(
        owner: () => 'admin',
        credential: () async => 'fixture',
        list: (_, query) async {
          queries.add(Map.of(query));
          return auditPageFixture();
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminSystemActivityScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Custom dates (UTC)'), findsNothing);
      final time = find.byKey(const ValueKey('activity-time-range'));
      expect(time, findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Refine activity')).dy -
            tester.getBottomLeft(time).dy,
        lessThan(35),
      );
      final initial = Map.of(queries.single);
      await tester.tap(time);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Custom dates (UTC)'));
      await tester.pumpAndSettle();
      expect(find.byType(DateRangePickerDialog), findsOneWidget);
      expect(queries.length, 1);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(queries.single, initial);
      expect(find.text('Last 24 Hours'), findsOneWidget);
      expect(find.text('Custom dates (UTC)'), findsNothing);
    },
  );

  testWidgets(
    'custom Time selection preserves inclusive UTC dates, supports editing and clears on presets',
    (tester) async {
      final queries = <Map<String, String>>[];
      final repo = AdminActivityRepository(
        owner: () => 'admin',
        credential: () async => 'fixture',
        list: (_, query) async {
          queries.add(Map.of(query));
          return auditPageFixture(cursor: 'next-page');
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminSystemActivityScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('System Updates'));
      await tester.pumpAndSettle();
      await showItem(tester, find.text('Next'));
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(queries.last['cursor'], 'next-page');
      final time = find.byKey(const ValueKey('activity-time-range'));
      tester
          .state<ScrollableState>(
            find
                .byWidgetPredicate(
                  (w) =>
                      w is Scrollable && w.axisDirection == AxisDirection.down,
                )
                .last,
          )
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      await tester.tap(time);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Custom dates (UTC)'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Switch to input'));
      await tester.pumpAndSettle();
      final fields = find.descendant(
        of: find.byType(DateRangePickerDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(fields.at(0), '05/02/2024');
      await tester.enterText(fields.at(1), '05/04/2024');
      await tester.tap(find.text('OK').last);
      await tester.pumpAndSettle();
      expect(queries.last['from'], '2024-05-02T00:00:00.000Z');
      expect(queries.last['to'], '2024-05-05T00:00:00.000Z');
      expect(queries.last['category'], 'SYSTEM_UPDATE');
      expect(queries.last.containsKey('cursor'), false);
      expect(
        find.widgetWithText(TextButton, 'Custom dates (UTC)'),
        findsNothing,
      );
      expect(find.text('Custom dates (UTC)'), findsOneWidget);
      await tester.tap(time);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Custom dates (UTC)').last);
      await tester.pumpAndSettle();
      final picker = tester.widget<DateRangePickerDialog>(
        find.byType(DateRangePickerDialog),
      );
      expect(
        picker.initialDateRange,
        DateTimeRange(start: DateTime(2024, 5, 2), end: DateTime(2024, 5, 4)),
      );
      final count = queries.length;
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(queries.length, count);
      expect(queries.last['to'], '2024-05-05T00:00:00.000Z');
      await tester.tap(time);
      await tester.pumpAndSettle();
      await tester.tap(find.text('All Time').last);
      await tester.pumpAndSettle();
      expect(queries.last.containsKey('from'), false);
      expect(queries.last.containsKey('to'), false);
      await tester.tap(time);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Last 7 Days').last);
      await tester.pumpAndSettle();
      expect(queries.last['from'], endsWith('Z'));
      expect(queries.last.containsKey('to'), false);
    },
  );

  for (final width in [320.0, 412.0]) {
    for (final dark in [false, true]) {
      testWidgets(
        'Time menu includes custom dates at $width dark=$dark and 2x text',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final repo = AdminActivityRepository(
            owner: () => 'admin',
            credential: () async => 'fixture',
            list: (_, _) async => auditPageFixture(),
          );
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: AdminSystemActivityScreen(repository: repo),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('activity-time-range')));
          await tester.pumpAndSettle();
          expect(find.text('Custom dates (UTC)'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'list uses server filters/counts, pages beyond 500, and returns to the same scroll',
    (tester) async {
      final queries = <Map<String, String>>[];
      var listCalls = 0;
      final repo = AdminActivityRepository(
        owner: () => 'admin',
        credential: () async => 'fixture',
        list: (_, query) async {
          listCalls++;
          queries.add(Map.of(query));
          return auditPageFixture(
            id: query.containsKey('cursor') ? 'second-page' : 'event-one',
            cursor: query.containsKey('cursor') ? null : 'next-page',
          );
        },
        read: (_, id) async => {'activity': auditFixture(id: id)},
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminSystemActivityScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();
      expect(queries.single['from'], endsWith('Z'));
      expect(find.text('501 events · 17 alert events'), findsOneWidget);
      expect(
        find.textContaining('Existing history remains available'),
        findsOneWidget,
      );
      await tester.tap(find.text('System Updates'));
      await tester.pumpAndSettle();
      expect(queries.last['category'], 'SYSTEM_UPDATE');
      await showItem(tester, find.text('Next'));
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(queries.last['cursor'], 'next-page');
      expect(queries.last['category'], 'SYSTEM_UPDATE');
      await showItem(tester, find.text('Account access updated'));
      final state = tester.state<ScrollableState>(
        find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .last,
      );
      final before = state.position.pixels;
      final calls = listCalls;
      await tester.tap(find.text('Account access updated'));
      await tester.pumpAndSettle();
      expect(find.text('Audit Event'), findsOneWidget);
      await tester.tap(find.byTooltip('Back to Activity'));
      await tester.pumpAndSettle();
      expect(find.text('Page 2'), findsOneWidget);
      expect(state.position.pixels, closeTo(before, 0.01));
      expect(listCalls, calls);
      final selected = tester.widget<CivicFilterChip>(
        find.widgetWithText(CivicFilterChip, 'System Updates'),
      );
      expect(selected.selected, true);
    },
  );

  testWidgets(
    'composed filters and search reset the cursor and preserve submitted query',
    (tester) async {
      final queries = <Map<String, String>>[];
      final repo = AdminActivityRepository(
        owner: () => 'admin',
        credential: () async => 'fixture',
        list: (_, query) async {
          queries.add(Map.of(query));
          return auditPageFixture(cursor: 'next-page');
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminSystemActivityScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();
      final header = tester.widget<SearchFilterHeader>(
        find.byType(SearchFilterHeader).first,
      );
      header.onQueryChanged!('Recorded & name');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Refine activity'));
      await tester.pumpAndSettle();
      final outcome = tester.widget<AppDropdownField<String>>(
        find.byType(AppDropdownField<String>).last,
      );
      outcome.onChanged!('UNKNOWN');
      await tester.pumpAndSettle();
      expect(queries.last['outcome'], 'UNKNOWN');
      expect(queries.last['q'], 'Recorded & name');
      final action = find.widgetWithText(TextField, 'Action');
      await tester.enterText(action, 'USER_UPDATED');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(queries.last['action'], 'USER_UPDATED');
      expect(queries.last.containsKey('cursor'), false);
      final count = queries.length;
      tester
          .widget<SearchFilterHeader>(find.byType(SearchFilterHeader).first)
          .onQueryChanged!('a' * 201);
      await tester.pumpAndSettle();
      expect(queries.length, count);
      expect(
        tester
            .widget<SearchFilterHeader>(find.byType(SearchFilterHeader).first)
            .query
            .length,
        201,
      );
      expect(find.textContaining('last valid search'), findsOneWidget);
      await showItem(tester, find.text('Reset filters'));
      await tester.tap(find.text('Reset filters'));
      await tester.pumpAndSettle();
      expect(queries.last.keys, ['from']);
      expect(find.textContaining('last valid search'), findsNothing);
    },
  );

  testWidgets(
    'focused search opens real detail and keyboard Enter restores list focus',
    (tester) async {
      final repo = AdminActivityRepository(
        owner: () => 'admin',
        credential: () async => 'fixture',
        list: (_, _) async => auditPageFixture(),
        read: (_, id) async => {'activity': auditFixture(id: id)},
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminSystemActivityScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();
      await showItem(tester, find.text('Account access updated'));
      final node = Focus.of(
        tester.element(find.text('Account access updated')),
      );
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Audit Event'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Audit history'), findsOneWidget);
      expect(node.hasFocus, true);
      final header = tester.widget<SearchFilterHeader>(
        find.byType(SearchFilterHeader).first,
      );
      final result = header.results('account').single;
      result.onSelected!();
      await tester.pumpAndSettle();
      expect(find.text('Audit Event'), findsOneWidget);
    },
  );

  testWidgets(
    'page refresh retains the rail/cards and failure never becomes confirmed empty',
    (tester) async {
      var calls = 0;
      final pending = Completer<Map<String, dynamic>>();
      final repo = AdminActivityRepository(
        owner: () => 'admin',
        credential: () async => 'fixture',
        list: (_, _) =>
            ++calls == 1 ? Future.value(auditPageFixture()) : pending.future,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: AdminSystemActivityScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();
      final rail = tester.element(find.byType(SearchFilterList));
      final card = tester.element(find.text('Account access updated'));
      final refresh = tester.widget<GhanaRefreshIndicator>(
        find.byType(GhanaRefreshIndicator),
      );
      final running = refresh.onRefresh();
      await tester.pump();
      expect(tester.element(find.byType(SearchFilterList)), same(rail));
      expect(tester.element(find.text('Account access updated')), same(card));
      expect(find.text('501 events · 17 alert events'), findsOneWidget);
      pending.completeError(
        const ApiException(statusCode: 503, message: 'private'),
      );
      await running;
      await tester.pumpAndSettle();
      expect(find.text('Account access updated'), findsOneWidget);
      expect(tester.element(find.text('Account access updated')), same(card));
      expect(find.textContaining('last authorized snapshot'), findsOneWidget);
      expect(
        find.text('No activity matches your search and filters.'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'direct detail Back replaces the entry and repeated Back creates no detail loop',
    (tester) async {
      final repo = AdminActivityRepository(
        owner: () => 'admin',
        credential: () async => 'fixture',
        read: (_, _) async => {'activity': auditFixture()},
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          routes: {
            AdminActivityDetailScreen.activityRouteName: (_) =>
                const Scaffold(body: Text('Activity fallback')),
          },
          home: AdminActivityDetailScreen(id: 'event-one', repository: repo),
        ),
      );
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Activity fallback'), findsOneWidget);
      expect(find.byType(AdminActivityDetailScreen), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Audit Event'), findsNothing);
      final parsed = AdminActivityDetailScreen.fromSettings(
        const RouteSettings(
          name: '/admin/activity-detail?eventId=event-one&tier=superAdmin',
        ),
      );
      expect(parsed.id, 'event-one');
      expect(parsed.fromActivity, false);
    },
  );

  testWidgets(
    'detail loading, scoped miss, denial and retry are distinct; no raw server message',
    (tester) async {
      var reply = Completer<Map<String, dynamic>>();
      final repo = AdminActivityRepository(
        owner: () => 'admin',
        credential: () async => 'fixture',
        read: (_, _) => reply.future,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminActivityDetailScreen(id: 'event-one', repository: repo),
        ),
      );
      await tester.pump();
      expect(find.byType(GhanaLoadingIndicator), findsOneWidget);
      reply.completeError(
        const ApiException(statusCode: 503, message: 'private server details'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Cannot reach CivicVoice'), findsOneWidget);
      expect(find.textContaining('private server'), findsNothing);
      reply = Completer();
      await tester.tap(find.text('Retry'));
      await tester.pump();
      reply.completeError(
        const ApiException(statusCode: 404, message: 'outside scope'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Event not found'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      final forbidden = AdminActivityRepository(
        owner: () => 'assembly-admin',
        credential: () async => 'fixture',
        read: (_, _) async =>
            throw const ApiException(statusCode: 403, message: 'private'),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminActivityDetailScreen(
            id: 'event-one',
            repository: forbidden,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Administrative access required'), findsOneWidget);
      expect(find.text('Event not found'), findsNothing);
    },
  );

  for (final missingHistory in [false, true]) {
    testWidgets(
      'detail separates actor identity from event locality missing=$missingHistory',
      (tester) async {
        final repo = AdminActivityRepository(
          owner: () => 'super-admin',
          credential: () async => 'fixture',
          read: (_, _) async => {
            'activity': {
              ...auditFixture(),
              if (missingHistory) ...{
                'actorName': null,
                'actorPublicId': null,
                'actorRole': null,
                'region': null,
                'assembly': null,
              },
            },
          },
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: AdminActivityDetailScreen(id: 'event-one', repository: repo),
          ),
        );
        await tester.pumpAndSettle();
        final actor = find.byWidgetPredicate(
          (widget) => widget is FormSectionCard && widget.title == 'Actor',
        );
        expect(actor, findsOneWidget);
        expect(
          find.descendant(of: actor, matching: find.text('Assembly')),
          findsNothing,
        );
        expect(
          find.descendant(of: actor, matching: find.text('Region')),
          findsNothing,
        );
        if (missingHistory) {
          expect(
            find.descendant(of: actor, matching: find.text('Not recorded')),
            findsNWidgets(3),
          );
        } else {
          expect(
            find.descendant(
              of: actor,
              matching: find.text('Recorded administrator'),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(of: actor, matching: find.text('CV-ADMIN-42')),
            findsOneWidget,
          );
        }
        final jurisdiction = find.byWidgetPredicate(
          (widget) =>
              widget is FormSectionCard && widget.title == 'Event jurisdiction',
        );
        await showItem(tester, jurisdiction);
        expect(
          find.descendant(
            of: jurisdiction,
            matching: find.text(missingHistory ? 'Not recorded' : 'Ga Central'),
          ),
          missingHistory ? findsNWidgets(2) : findsOneWidget,
        );
        expect(
          find.text(
            'This is the locality recorded for the event, not the actor’s own locality.',
          ),
          findsOneWidget,
        );
      },
    );
  }

  testWidgets(
    'session clear immediately removes a loaded detail from the visible route',
    (tester) async {
      final repo = AdminActivityRepository(
        owner: () => 'admin',
        credential: () async => 'fixture',
        read: (_, _) async => {'activity': auditFixture()},
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminActivityDetailScreen(id: 'event-one', repository: repo),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Account access updated'), findsOneWidget);
      AdminActivityRepository.invalidateSession();
      await tester.pumpAndSettle();
      expect(find.text('Account access updated'), findsNothing);
      expect(find.text('Administrative access required'), findsOneWidget);
    },
  );

  for (final width in [320.0, 412.0, 1440.0]) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 1.5, 2.0]) {
        testWidgets(
          'detail long content fits $width dark=$dark scale=$scale with actual fonts',
          (tester) async {
            tester.view.physicalSize = Size(width, 900);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final repo = AdminActivityRepository(
              owner: () => 'admin',
              credential: () async => 'fixture',
              read: (_, _) async => {
                'activity': {
                  ...auditFixture(),
                  'title':
                      'A long recorded account event title that must wrap without losing content',
                  'actorName': 'LongRecordedActorName' * 10,
                },
              },
            );
            await tester.pumpWidget(
              MaterialApp(
                theme: dark ? AppTheme.dark : AppTheme.light,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: AdminActivityDetailScreen(
                  id: 'event-one',
                  repository: repo,
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await showItem(
              tester,
              find.textContaining('The outcome was not established'),
            );
            expect(tester.takeException(), isNull);
            await showItem(tester, find.text('Recorded context'));
            expect(find.text('secret-password'), findsNothing);
            await showItem(
              tester,
              find.textContaining('Earlier values reflect'),
            );
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  for (final width in [320.0, 390.0, 412.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets('live list fits $width dark=$dark at 2x text', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = AdminActivityRepository(
          owner: () => 'admin',
          credential: () async => 'fixture',
          list: (_, _) async => {
            ...auditPageFixture(),
            'activity': [
              {
                ...auditFixture(),
                'title': 'Long account activity title ' * 4,
                'description': 'Recorded detail ' * 12,
              },
            ],
          },
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(2)),
              child: child!,
            ),
            home: AdminSystemActivityScreen(repository: repo),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await showItem(
          tester,
          find.textContaining('Long account activity title'),
        );
        expect(tester.takeException(), isNull);
        await showItem(tester, find.text('Next'));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
