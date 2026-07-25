import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/citizen/models/civic_report.dart';
import 'package:civic_voice/features/citizen/screens/citizen_dashboard_screen.dart';
import 'package:civic_voice/features/citizen/screens/photo_upload_screen.dart';
import 'package:civic_voice/features/citizen/screens/report_tracking_screen.dart';
import 'package:civic_voice/features/citizen/screens/review_report_screen.dart';
import 'package:civic_voice/features/citizen/services/location_service.dart';
import 'package:civic_voice/features/citizen/services/report_crud_service.dart';
import 'package:civic_voice/features/citizen/widgets/nearby_seconding_card.dart';
import 'package:civic_voice/features/citizen/widgets/nearby_seconding_preference_row.dart';
import 'package:civic_voice/main.dart' as app;
import 'package:civic_voice/services/app_cache_service.dart';
import 'package:civic_voice/utils/time_greeting.dart';
import 'package:civic_voice/widgets/evidence_image_viewer.dart';
import 'package:civic_voice/widgets/glass_dialog_backdrop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLocationService extends LocationService {
  const _FakeLocationService(this.result);

  final LocationAccessResult result;

  @override
  Future<LocationAccessResult> requestCurrentPosition() async => result;

  @override
  Future<LocationAccessStatus> checkAccessStatus({
    required bool requestPermission,
  }) async => result.status;
}

Position _position(double latitude, double longitude) => Position(
  longitude: longitude,
  latitude: latitude,
  timestamp: DateTime.utc(2026, 7, 22),
  accuracy: 5,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

const _nearbyReports = [
  NearbySecondingReport(
    id: 'nearby-1',
    reference: 'CV-2026-000001',
    title: 'Broken streetlight',
    category: 'Street Lighting',
    distanceMeters: 84.4,
    seconderCount: 1,
  ),
  NearbySecondingReport(
    id: 'nearby-2',
    reference: 'CV-2026-000002',
    title: 'Blocked drain',
    category: 'Sanitation',
    distanceMeters: 110,
    seconderCount: 0,
  ),
];

void main() {
  testWidgets('Nearby Reports preference stays compact and explains on help', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await AppCacheService.instance.initialize();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: NearbySecondingPreferenceRow()),
      ),
    );
    await tester.pump();

    expect(find.text('Nearby Reports'), findsOneWidget);
    expect(
      find.text(
        "Show a card when you're near an unconfirmed report you could help verify",
      ),
      findsNothing,
    );

    await tester.tap(find.byTooltip('About Nearby Reports'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Shows one nearby report you can help confirm when you open the dashboard. Your location is not tracked in the background.',
      ),
      findsOneWidget,
    );
    expect(find.byType(GlassDialogBackdrop), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
  });

  testWidgets(
    'nearby confirmation shows one card and never resurfaces a dismissed report',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await AppCacheService.instance.initialize();
      tester.view.physicalSize = const Size(428, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final location = _FakeLocationService(
        LocationAccessResult(
          status: LocationAccessStatus.ready,
          position: _position(5.6, -0.2),
        ),
      );
      Future<List<NearbySecondingReport>> load(_, _) async => _nearbyReports;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: CitizenDashboardScreen(
            locationService: location,
            nearbySecondingLoader: load,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(NearbySecondingCard), findsOneWidget);
      expect(find.text('Broken streetlight'), findsOneWidget);
      expect(find.text('Blocked drain'), findsNothing);

      await tester.tap(find.text('Not sure'));
      await tester.pump();
      expect(find.byType(NearbySecondingCard), findsNothing);
      expect(AppCacheService.instance.secondingSeenIds, contains('nearby-1'));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: CitizenDashboardScreen(
            key: const ValueKey('reopened-dashboard'),
            locationService: location,
            nearbySecondingLoader: load,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(NearbySecondingCard), findsOneWidget);
      expect(find.text('Broken streetlight'), findsNothing);
      expect(find.text('Blocked drain'), findsOneWidget);
    },
  );

  testWidgets('confirm seconds the report once and remembers it locally', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await AppCacheService.instance.initialize();
    tester.view.physicalSize = const Size(428, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final confirmed = <String>[];
    Future<List<NearbySecondingReport>> load(_, _) async => _nearbyReports;
    Future<void> confirm(String id) async => confirmed.add(id);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: CitizenDashboardScreen(
          locationService: _FakeLocationService(
            LocationAccessResult(
              status: LocationAccessStatus.ready,
              position: _position(5.6, -0.2),
            ),
          ),
          nearbySecondingLoader: load,
          nearbySecondingConfirmer: confirm,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text("Confirm it's still there"));
    await tester.pump();
    await tester.pump();

    expect(confirmed, ['nearby-1']);
    expect(AppCacheService.instance.secondingSeenIds, contains('nearby-1'));
    expect(find.byType(NearbySecondingCard), findsNothing);
    expect(find.text('Thanks for confirming this report.'), findsOneWidget);
  });

  testWidgets(
    'photo source flags stay aligned when the first photo is removed',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: PhotoUploadScreen(
            initialPhotos: [XFile('a.jpg'), XFile('b.jpg'), XFile('c.jpg')],
            initialPhotoIsFromCamera: const [true, false, true],
          ),
        ),
      );
      await tester.pump();

      final firstPhoto = find.byKey(const ValueKey('photo-a.jpg-camera'));
      expect(firstPhoto, findsOneWidget);
      expect(find.byKey(const ValueKey('photo-b.jpg-gallery')), findsOneWidget);
      expect(find.byKey(const ValueKey('photo-c.jpg-camera')), findsOneWidget);

      await tester.tap(
        find.descendant(of: firstPhoto, matching: find.byIcon(AppIcons.close)),
      );
      await tester.pump();

      expect(firstPhoto, findsNothing);
      expect(find.byKey(const ValueKey('photo-b.jpg-gallery')), findsOneWidget);
      expect(find.byKey(const ValueKey('photo-c.jpg-camera')), findsOneWidget);
      expect(find.text('2 / 5 photos'), findsOneWidget);
    },
  );

  testWidgets('review warns when live submission GPS is over 300m from pin', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ReviewReportScreen(
          reportLatitude: 5.6,
          reportLongitude: -0.2,
          locationService: _FakeLocationService(
            LocationAccessResult(
              status: LocationAccessStatus.ready,
              position: _position(5.604, -0.2),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('from the pinned issue'), findsOneWidget);
    expect(find.text('Submit Report'), findsOneWidget);
  });

  testWidgets('review omits discrepancy warning within 300m of pin', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ReviewReportScreen(
          reportLatitude: 5.6,
          reportLongitude: -0.2,
          locationService: _FakeLocationService(
            LocationAccessResult(
              status: LocationAccessStatus.ready,
              position: _position(5.6001, -0.2),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('from the pinned issue'), findsNothing);
    expect(find.text('Submit Report'), findsOneWidget);
  });

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

      expect(find.text('${timeBasedGreeting()}, Citizen'), findsOneWidget);
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

      expect(find.text('${timeBasedGreeting()}, Citizen'), findsOneWidget);

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
      expect(find.text('Review Estimate'), findsNothing);
      expect(find.text('Within 24-48 hours'), findsNothing);
      expect(find.textContaining('Estimated:'), findsNothing);
      expect(find.text('Pending initial validation'), findsOneWidget);

      await pumpRoute(
        '${app.AppRoutes.citizenReportTracking}?reportId=missing',
      );

      expect(find.text('Track Report'), findsOneWidget);
      expect(find.text('Report not found'), findsOneWidget);

      await pumpRoute(app.AppRoutes.citizenAlerts);

      expect(find.text('Alerts'), findsOneWidget);

      await pumpRoute(app.AppRoutes.citizenProfile);

      expect(find.text('Profile'), findsWidgets);
      expect(find.text('Citizen'), findsWidgets);
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

      final evidenceTile = find.byKey(
        const ValueKey('evidence-photo-fake/streetlight.jpg'),
      );
      for (var i = 0; i < 8 && evidenceTile.evaluate().isEmpty; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pump();
      }
      await tester.tap(evidenceTile);
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
