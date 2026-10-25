import 'dart:ui' as ui;
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/citizen/models/civic_report.dart';
import 'package:civic_voice/features/citizen/screens/citizen_reports_screen.dart';
import 'package:civic_voice/features/citizen/services/report_crud_service.dart';
import 'package:civic_voice/services/app_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppCacheService.instance.initialize(accountId: 'report-card-surface');
    final previous = ReportCrudService.instance.reports.value;
    addTearDown(() => ReportCrudService.instance.reports.value = previous);
    ReportCrudService.instance.reports.value = const [
      CivicReport(
        id: 'surface-fixture',
        referenceNumber: 'CV-SURFACE',
        title: 'Streetlight report',
        location: 'Test street',
        timeLabel: 'Today',
        status: ReportStatus.submitted,
      ),
    ];
  });
  for (final dark in [false, true]) {
    testWidgets(
      'report card paints the web primary surface and border dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(412, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final theme = dark ? AppTheme.dark : AppTheme.light;
        final boundaryKey = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundaryKey,
            child: MaterialApp(
              theme: theme,
              home: const CitizenReportsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final card = find.byKey(
          const ValueKey('report-history-card-surface-fixture'),
        );
        await Scrollable.ensureVisible(tester.element(card), alignment: 0.5);
        await tester.pumpAndSettle();
        final rect = tester.getRect(card);
        final boundary =
            boundaryKey.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          final data = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          Color sample(double x, double y) {
            final offset = (y.floor() * image.width + x.floor()) * 4;
            return Color.fromARGB(
              data!.getUint8(offset + 3),
              data.getUint8(offset),
              data.getUint8(offset + 1),
              data.getUint8(offset + 2),
            );
          }

          expect(
            sample(rect.left + 8, rect.top + 40),
            theme.colorScheme.surface,
            reason:
                'Web report history uses the opaque primary surface, not the tinted secondary fill.',
          );
          expect(
            sample(rect.left, rect.top + 40),
            theme.colorScheme.outlineVariant,
            reason:
                'Web report history uses the normal border, not a faded glass hairline.',
          );
          image.dispose();
        });
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
