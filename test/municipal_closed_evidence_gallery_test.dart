import 'package:civic_voice/features/municipal/models/incoming_report.dart';
import 'package:civic_voice/features/municipal/services/municipal_report_directory.dart';
import 'package:civic_voice/features/municipal/screens/municipal_report_progress_screen.dart';
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/municipal/models/resolved_report.dart';
import 'package:civic_voice/features/municipal/screens/municipal_resolution_details_screen.dart';
import 'package:civic_voice/models/report_status.dart';
import 'package:civic_voice/widgets/evidence_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final rejected in [false, true]) {
    for (final dark in [false, true]) {
      testWidgets(
        'municipal closed evidence opens at selected photo and swipes rejected=$rejected dark=$dark',
        (tester) async {
          tester.view.physicalSize = const Size(390, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final data = ResolvedReportItem(
            referenceId: 'CV-TEST',
            title: 'Drain repair',
            locationLabel: 'Test location',
            resolvedDate: DateTime(2026, 10, 23),
            resolvedTimeLabel: '12:00',
            durationDays: 1,
            slaPercent: 100,
            evidencePhotoCount: 3,
            resolutionNote: 'Recorded outcome.',
            status: rejected ? ReportStatus.rejected : ReportStatus.resolved,
            evidencePhotoUrls: const [
              'https://example.invalid/a.jpg',
              'https://example.invalid/b.jpg',
              'https://example.invalid/c.jpg',
            ],
          );
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              home: MunicipalResolutionDetailsScreen(
                data: data,
                referenceId: data.referenceId,
              ),
            ),
          );
          await tester.pumpAndSettle();
          final selected = find.byKey(
            const ValueKey('municipal-resolution-evidence-1'),
          );
          await tester.ensureVisible(selected);
          if (rejected) expect(find.text('VERIFIED'), findsNothing);
          await tester.tap(selected);
          await tester.pumpAndSettle();
          expect(find.byType(EvidenceImageViewer), findsOneWidget);
          expect(find.text('2 / 3'), findsOneWidget);
          await tester.drag(find.byType(PageView), const Offset(-500, 0));
          await tester.pumpAndSettle();
          expect(find.text('3 / 3'), findsOneWidget);
          await tester.tap(find.byTooltip('Close'));
          await tester.pumpAndSettle();
          expect(find.byType(EvidenceImageViewer), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'municipal approved outcome shares the full gallery at tapped index',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final directory = MunicipalReportDirectory.instance;
      final original = directory.reports.value;
      addTearDown(() => directory.reports.value = original);
      directory.reports.value = [
        IncomingReportItem.fromApi({
          'id': 'record-id',
          'publicReference': 'CV-TEST',
          'title': 'Drain repair',
          'status': 'RESOLVED',
          'progressPercent': 100,
          'resolutionNotes': 'Work completed.',
          'resolutionPhotoUrls': [
            'https://example.invalid/a.jpg',
            'https://example.invalid/b.jpg',
            'https://example.invalid/c.jpg',
          ],
        }),
      ];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MunicipalReportProgressScreen(
            referenceId: 'CV-TEST',
            initialState: MunicipalReportProgressViewState.success,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final selected = find.byKey(
        const ValueKey('municipal-outcome-evidence-1'),
      );
      await tester.ensureVisible(selected);
      await tester.tap(selected);
      await tester.pumpAndSettle();
      expect(find.text('2 / 3'), findsOneWidget);
      await tester.drag(find.byType(PageView), const Offset(500, 0));
      await tester.pumpAndSettle();
      expect(find.text('1 / 3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
