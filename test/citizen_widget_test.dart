import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/citizen/models/civic_report.dart';
import 'package:civic_voice/features/citizen/screens/citizen_dashboard_screen.dart';
import 'package:civic_voice/features/citizen/screens/report_tracking_screen.dart';
import 'package:civic_voice/features/citizen/services/report_crud_service.dart';
import 'package:civic_voice/main.dart' as app;
import 'package:civic_voice/widgets/evidence_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Citizen Dashboard shows the signed-in citizen and quick actions',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const CitizenDashboardScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Good Morning, Amina Mensah'), findsOneWidget);
      expect(find.text('Report a Community Issue'), findsOneWidget);
      expect(find.text('Report Now'), findsOneWidget);
    },
  );

  testWidgets(
    'Citizen routes connect dashboard, reports, create, photos, review, '
    'submitted, tracking, alerts, and profile',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Future<void> pumpRoute(String routeName) async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await tester.pumpWidget(app.CivicVoiceApp(initialRoute: routeName));
        await tester.pumpAndSettle();
      }

      await tester.pumpWidget(
        const app.CivicVoiceApp(initialRoute: app.AppRoutes.citizenDashboard),
      );
      await tester.pump();

      expect(find.text('Good Morning, Amina Mensah'), findsOneWidget);

      await tester.tap(find.text('View My Reports').first);
      await tester.pumpAndSettle();

      expect(find.text('My Reports'), findsWidgets);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        const app.CivicVoiceApp(initialRoute: app.AppRoutes.citizenDashboard),
      );
      await tester.pump();

      await tester.tap(find.text('Report Now').first);
      await tester.pumpAndSettle();

      expect(find.text('Create Report'), findsOneWidget);
      expect(find.text('Continue to Photos'), findsOneWidget);

      await pumpRoute(app.AppRoutes.citizenPhotoUpload);

      expect(find.text('Upload Photos'), findsOneWidget);
      expect(
        find.text('At least 2 photos required as evidence — 2 more needed.'),
        findsOneWidget,
      );

      await pumpRoute(app.AppRoutes.citizenReviewReport);

      expect(find.text('Review Report'), findsOneWidget);
      expect(find.text('Submit Report'), findsOneWidget);

      await pumpRoute(app.AppRoutes.citizenReportSubmitted);

      expect(find.text('Submitted'), findsWidgets);
      expect(find.text('Track My Report'), findsOneWidget);

      await pumpRoute(
        '${app.AppRoutes.citizenReportTracking}?reportId=missing',
      );

      expect(find.text('Track Report'), findsOneWidget);
      expect(find.text('Report not found'), findsOneWidget);

      await pumpRoute(app.AppRoutes.citizenAlerts);

      expect(find.text('Alerts'), findsOneWidget);

      await pumpRoute(app.AppRoutes.citizenProfile);

      expect(find.text('Profile'), findsWidgets);
      expect(find.text('Amina Mensah'), findsWidgets);
    },
  );

  testWidgets(
    'Report Tracking: tapping an evidence photo opens the full-screen '
    'viewer with a working Share button',
    (WidgetTester tester) async {
      const report = CivicReport(
        id: 'evidence-test-report',
        title: 'Broken streetlight',
        location: '12 Independence Ave',
        timeLabel: '2h ago',
        status: ReportStatus.submitted,
        photoPaths: ['fake/streetlight.jpg'],
      );
      ReportCrudService.instance.reports.value = [report];
      addTearDown(() => ReportCrudService.instance.reports.value = []);

      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const ReportTrackingScreen(reportId: 'evidence-test-report'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EvidenceImageViewer), findsNothing);

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      expect(find.byType(EvidenceImageViewer), findsOneWidget);
      expect(find.byTooltip('Close'), findsOneWidget);
      expect(find.byTooltip('Share'), findsOneWidget);

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      expect(find.byType(EvidenceImageViewer), findsNothing);
    },
  );
}
