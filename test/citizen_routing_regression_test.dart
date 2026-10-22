import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:civic_voice/features/citizen/services/places_service.dart';
import 'package:civic_voice/features/citizen/screens/report_tracking_screen.dart';
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/citizen/models/civic_report.dart';
import 'package:civic_voice/features/citizen/services/report_crud_service.dart';
import 'package:civic_voice/features/citizen/services/report_jurisdiction.dart';
import 'package:civic_voice/models/region.dart';
import 'package:civic_voice/services/notification_directory.dart';
import 'package:civic_voice/widgets/pending_coverage_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('explicit district survives suffix and case variations', () {
    expect(
      reportAssemblyFor(Region.greaterAccra, ['Ga West Municipal']),
      'Ga West',
    );
    expect(
      reportAssemblyFor(Region.greaterAccra, ['GA CENTRAL DISTRICT ASSEMBLY']),
      'Ga Central',
    );
    expect(
      reportAssemblyFor(Region.ashanti, ['Kumasi Metropolitan']),
      'Kumasi',
    );
  });
  test('community and region do not guess an assembly', () {
    expect(
      reportAssemblyFor(Region.greaterAccra, [
        'Greater Accra Region',
        'Nii Okaiman East',
      ]),
      isNull,
    );
    expect(
      reportAssemblyFor(Region.greaterAccra, ['Ga West', 'Ga Central']),
      isNull,
    );
    expect(reportAssemblyFor(null, ['Ga West']), isNull);
    expect(reportAssemblyFor(Region.ashanti, ['Ga West']), isNull);
    expect(
      reportAssemblyFor(Region.greaterAccra, ['Municipal Assembly', '']),
      isNull,
    );
  });
  test(
    'Citizen notifications identify the exact public report at every status',
    () {
      final directory = ReportCrudService.instance;
      final previous = directory.reports.value;
      addTearDown(() => directory.reports.value = previous);
      for (final status in ReportStatus.values) {
        directory.reports.value = [
          CivicReport(
            id: 'internal-id',
            referenceNumber: 'CV-2026-TEST',
            title: 'Blocked gutter',
            location: 'Test location',
            timeLabel: 'Just now',
            status: status,
          ),
        ];
        final notice = NotificationDirectory.instance.forCitizen().first;
        expect(notice.message, contains('CV-2026-TEST: Blocked gutter'));
        expect(notice.message, isNot(contains('internal-id')));
      }
    },
  );
  test(
    'place selection retains district separately from the community',
    () async {
      const channel = MethodChannel('civic_voice/config');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (_) async => {'apiKey': 'test-key'},
          );
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      final places = PlacesService(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'id': 'test-place',
              'formattedAddress': 'Test address',
              'location': {'latitude': 5.6, 'longitude': -0.3},
              'addressComponents': [
                {
                  'longText': 'Nii Okaiman East',
                  'types': ['locality'],
                },
                {
                  'longText': 'Ga West Municipal',
                  'types': ['administrative_area_level_2'],
                },
                {
                  'longText': 'Greater Accra Region',
                  'types': ['administrative_area_level_1'],
                },
                {
                  'longText': 'Ghana',
                  'types': ['country'],
                },
              ],
            }),
            200,
          ),
        ),
      );
      addTearDown(places.dispose);
      final selected = await places.fetchPlace('test-place');
      expect(selected.locality, 'Nii Okaiman East');
      expect(selected.assembly, 'Ga West');
    },
  );
  testWidgets('real unresolved report shows coverage notice in tracking', (
    tester,
  ) async {
    final directory = ReportCrudService.instance;
    final previous = directory.reports.value;
    addTearDown(() => directory.reports.value = previous);
    directory.reports.value = [
      const CivicReport(
        id: 'unresolved',
        referenceNumber: 'CV-TEST',
        title: 'Test gutter',
        location: 'Test street',
        timeLabel: 'Just now',
        status: ReportStatus.submitted,
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const ReportTrackingScreen(reportId: 'unresolved'),
      ),
    );
    expect(find.byType(PendingCoverageNotice), findsOneWidget);
    expect(
      find.textContaining('coverage could not be confirmed'),
      findsOneWidget,
    );
  });
  for (final dark in [false, true]) {
    testWidgets('coverage unknown is distinct from no officer, dark=$dark', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          home: const Scaffold(
            body: PendingCoverageNotice(coverageUnknown: true),
          ),
        ),
      );
      expect(
        find.textContaining('coverage could not be confirmed'),
        findsOneWidget,
      );
      expect(find.textContaining('No municipal officer'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          home: const Scaffold(body: PendingCoverageNotice()),
        ),
      );
      expect(
        find.textContaining('No municipal officer is set up'),
        findsOneWidget,
      );
    });
  }
}
