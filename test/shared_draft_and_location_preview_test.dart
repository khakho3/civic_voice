import 'package:civic_voice/features/municipal/models/incoming_report.dart';
import 'package:civic_voice/features/municipal/models/report_progress_data.dart';
import 'package:civic_voice/features/municipal/models/resolved_report.dart';
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/core/theme/app_map_style.dart';
import 'package:civic_voice/features/citizen/screens/photo_upload_screen.dart';
import 'package:civic_voice/features/citizen/screens/review_report_screen.dart';
import 'package:civic_voice/features/citizen/services/location_service.dart';
import 'package:civic_voice/services/app_cache_service.dart';
import 'package:civic_voice/widgets/evidence_image_viewer.dart';
import 'package:civic_voice/widgets/report_location_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoLocation extends LocationService {
  const _NoLocation();
  @override
  Future<LocationAccessResult> requestCurrentPosition() async =>
      const LocationAccessResult(status: LocationAccessStatus.unavailable);
}

void main() {
  test('municipal active and closed projections retain the report pin', () {
    final report = IncomingReportItem.fromApi({
      'id': 'saved',
      'publicReference': 'CV-PIN',
      'title': 'Issue',
      'status': 'RESOLVED',
      'latitude': 5.65,
      'longitude': -0.27,
    });
    final active = ReportProgressData.fromReport(report);
    final closed = ResolvedReportItem.fromReport(report);
    expect(active.latitude, 5.65);
    expect(active.longitude, -0.27);
    expect(closed.latitude, 5.65);
    expect(closed.longitude, -0.27);
    final missing = IncomingReportItem.fromApi({
      'id': 'no-pin',
      'status': 'RESOLVED',
    });
    expect(ResolvedReportItem.fromReport(missing).latitude, isNull);
    expect(ReportProgressData.fromReport(missing).longitude, isNull);
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppCacheService.instance.initialize(accountId: 'preview-test');
  });
  for (final dark in [false, true]) {
    testWidgets(
      'saved map opens exact report pin read-only and returns dark=$dark',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: const Scaffold(
              body: ReportLocationPreviewAction(
                latitude: 5.65,
                longitude: -0.27,
                label: 'Issue pin',
              ),
            ),
          ),
        );
        await tester.tap(find.text('View Map'));
        await tester.pumpAndSettle();
        expect(find.text('Read only'), findsOneWidget);
        final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
        expect(map.initialCameraPosition.target, const LatLng(5.65, -0.27));
        expect(map.markers.single.position, const LatLng(5.65, -0.27));
        expect(map.markers.single.draggable, isFalse);
        expect(map.onTap, isNull);
        expect(map.myLocationEnabled, isFalse);
        expect(map.style, dark ? AppMapStyle.dark : null);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byType(ReportLocationMapScreen), findsNothing);
      },
    );
    for (final review in [false, true]) {
      testWidgets(
        'draft preview opens tapped photo and swipes without deleting review=$review dark=$dark',
        (tester) async {
          tester.view.physicalSize = const Size(428, 2600);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final photos = [
            XFile('one.jpg'),
            XFile('two.jpg'),
            XFile('three.jpg'),
          ];
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              home: review
                  ? ReviewReportScreen(
                      photos: photos,
                      locationService: const _NoLocation(),
                    )
                  : PhotoUploadScreen(
                      initialPhotos: photos,
                      initialPhotoIsFromCamera: const [true, false, true],
                    ),
            ),
          );
          await tester.pumpAndSettle();
          final selected = find.byKey(
            ValueKey(review ? 'review-draft-photo-1' : 'photo-two.jpg-gallery'),
          );
          await tester.ensureVisible(selected);
          await tester.tap(selected);
          await tester.pumpAndSettle();
          expect(find.byType(EvidenceImageViewer), findsOneWidget);
          expect(find.text('2 / 3'), findsOneWidget);
          await tester.drag(find.byType(PageView), const Offset(-500, 0));
          await tester.pumpAndSettle();
          expect(find.text('3 / 3'), findsOneWidget);
          await tester.tap(find.byTooltip('Close'));
          await tester.pumpAndSettle();
          expect(selected, findsOneWidget);
          expect(photos.map((p) => p.path), [
            'one.jpg',
            'two.jpg',
            'three.jpg',
          ]);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'missing and invalid report coordinates never open a fallback map',
    (tester) async {
      for (final latitude in <double?>[null, double.nan, double.infinity, 91]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ReportLocationPreviewAction(
                latitude: latitude,
                longitude: 0,
                label: 'Missing pin',
              ),
            ),
          ),
        );
        expect(
          tester.widget<TextButton>(find.byType(TextButton)).onPressed,
          isNull,
        );
        expect(find.byType(GoogleMap), findsNothing);
      }
    },
  );
}
