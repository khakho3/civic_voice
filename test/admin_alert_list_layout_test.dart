import 'dart:async';
import 'dart:convert';
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/core/widgets/ghana_refresh_indicator.dart';
import 'package:civic_voice/features/admin/models/admin_overview.dart';
import 'package:civic_voice/features/admin/screens/admin_alerts_screen.dart';
import 'package:civic_voice/features/admin/services/admin_resource.dart';
import 'package:civic_voice/services/app_cache_service.dart';
import 'package:civic_voice/widgets/busy_indicator.dart';
import 'package:civic_voice/widgets/civic_filter_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_live_overview_test.dart' show alertFixture;

const longTitle =
    'A long recorded alert title with enough detail to wrap safely';
Map<String, dynamic> verifiedPage() => {
  'alerts': [
    {
      ...alertFixture(),
      'title': longTitle,
      'description': 'Long recorded context. ' * 12,
    },
  ],
  'total': 12345678,
  'nextCursor': null,
};

void expectSummaryFits(WidgetTester tester, String label) {
  final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
  final painter = TextPainter(
    text: paragraph.text,
    textDirection: paragraph.textDirection,
    textScaler: paragraph.textScaler,
  )..layout(maxWidth: paragraph.size.width);
  expect(paragraph.size.height, greaterThanOrEqualTo(painter.height - 0.01));
  painter.dispose();
}

Future<void> tapRefresh(WidgetTester tester) async {
  final refresh = find.text('Refresh alerts');
  await tester.scrollUntilVisible(
    refresh,
    200,
    scrollable: find
        .byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              axisDirectionToAxis(widget.axisDirection) == Axis.vertical,
        )
        .last,
  );
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(tester.element(refresh), alignment: 0.5);
  await tester.pumpAndSettle();
  await tester.tap(refresh);
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
    await AppCacheService.instance.initialize(accountId: 'alert-layout');
  });
  for (final width in [320.0, 390.0, 412.0, 1440.0]) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 1.5, 2.0]) {
        testWidgets('alert list states $width dark=$dark scale=$scale', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          var pending = Completer<Map<String, dynamic>>();
          final theme = dark ? AppTheme.dark : AppTheme.light;
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: AdminAlertsScreen(
                resourceFactory: (_, _, _) {
                  final response = pending.future;
                  return AdminResource<AdminAlertPage>(
                    owner: () => 'fixture-admin',
                    credential: () async => 'fixture',
                    fetch: (_) => response,
                    parse: AdminAlertPage.parse,
                  );
                },
              ),
            ),
          );
          await tester.pump();
          expect(find.byType(BusyIndicator), findsNothing);
          expect(find.byType(GhanaLoadingIndicator), findsOneWidget);
          expect(find.text('No alerts match these filters.'), findsNothing);
          pending.complete(verifiedPage());
          await tester.pumpAndSettle();
          expectSummaryFits(tester, '12345678 matching alerts');
          final card = tester.widget<Card>(find.byType(Card).first);
          expect(card.color, theme.colorScheme.surface);
          expect(card.elevation, 0);
          final filter = find.widgetWithText(CivicFilterChip, 'Open').first;
          await tester.ensureVisible(filter);
          await tester.pumpAndSettle();
          final before = tester.getTopLeft(find.text(longTitle));
          pending = Completer<Map<String, dynamic>>();
          await tester.tap(filter);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 80));
          expectSummaryFits(tester, 'Updating alerts…');
          expect(tester.getTopLeft(find.text(longTitle)), before);
          expect(find.byType(BusyIndicator), findsNothing);
          expect(find.text('12345678 matching alerts'), findsNothing);
          expect(find.text('No alerts match these filters.'), findsNothing);
          pending.complete({'alerts': [], 'total': 0, 'nextCursor': null});
          await tester.pumpAndSettle();
          final emptyCard = find.ancestor(
            of: find.text('No alerts match these filters.'),
            matching: find.byType(Card),
          );
          expect(emptyCard, findsOneWidget);
          expect(
            tester.widget<Card>(emptyCard).color,
            theme.colorScheme.surface,
          );
          expectSummaryFits(tester, '0 matching alerts');
          if (scale == 1) {
            expect(tester.getSize(find.text('0 matching alerts')).height, 24);
          }
          pending = Completer<Map<String, dynamic>>();
          await tapRefresh(tester);
          await tester.pump();
          pending.completeError(StateError('fixture request failed'));
          await tester.pumpAndSettle();
          expect(find.textContaining('could not be verified'), findsOneWidget);
          expect(find.text('No alerts match these filters.'), findsNothing);
          expect(find.text('0 matching alerts'), findsNothing);
          pending = Completer<Map<String, dynamic>>();
          await tapRefresh(tester);
          await tester.pump();
          pending.complete(verifiedPage());
          await tester.pumpAndSettle();
          expect(find.text(longTitle), findsOneWidget);
          expectSummaryFits(tester, '12345678 matching alerts');
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  }
}
