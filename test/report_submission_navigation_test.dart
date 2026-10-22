import 'dart:async';
import 'dart:convert';

import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/citizen/models/civic_report.dart';
import 'package:civic_voice/features/citizen/models/report_draft.dart';
import 'package:civic_voice/features/citizen/screens/create_report_screen.dart';
import 'package:civic_voice/features/citizen/screens/review_report_screen.dart';
import 'package:civic_voice/features/citizen/screens/report_submitted_screen.dart';
import 'package:civic_voice/features/citizen/services/location_service.dart';
import 'package:civic_voice/services/app_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoLocation extends LocationService {
  const _NoLocation();
  @override
  Future<LocationAccessResult> requestCurrentPosition() async =>
      const LocationAccessResult(status: LocationAccessStatus.unavailable);
}

void main() {
  testWidgets(
    'reopening Create recovers frozen content without authoring or a new key',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await AppCacheService.instance.initialize(accountId: 'alice');
      const saved = ReportDraft(
        title: 'Frozen report title',
        description: 'Frozen description',
        category: 'Sanitation',
        location: 'Frozen selected pin',
        community: 'Test',
        submissionKey: 'saved_submission_12345',
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'report_submission_v1_alice',
        jsonEncode(saved.toMap()),
      );
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const CreateReportScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ReviewReportScreen), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Frozen report title'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Check submission again'),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Back to Photos'), findsNothing);
      expect(find.text('Submit Report'), findsNothing);
      expect(
        tester
            .widget<PopScope>(
              find.byWidgetPredicate((w) => w is PopScope).first,
            )
            .canPop,
        isFalse,
      );
      expect(
        jsonDecode(
          prefs.getString('report_submission_v1_alice')!,
        )['submissionKey'],
        saved.submissionKey,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'late success after same-account reactivation cannot navigate or clear new draft',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await AppCacheService.instance.initialize(accountId: 'alice');
      final response = Completer<CivicReport>();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ReviewReportScreen(
            reportTitle: 'Original',
            locationService: const _NoLocation(),
            submitReport: (_, {submissionLatitude, submissionLongitude}) =>
                response.future,
          ),
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Submit Report'),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(
        tester.element(find.text('Submit Report')),
        alignment: 0.5,
      );
      await tester.pump();
      await tester.tap(find.text('Submit Report'));
      await tester.pump();
      await AppCacheService.instance.activateAccount('alice');
      const newDraft = ReportDraft(
        title: 'New session draft',
        description: '',
        category: '',
        location: '',
        community: '',
      );
      await AppCacheService.instance.saveReportDraft(newDraft);
      response.complete(
        const CivicReport(
          id: 'r',
          referenceNumber: 'CV-1',
          title: 'Original',
          location: '',
          timeLabel: '',
          status: ReportStatus.submitted,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ReportSubmittedScreen), findsNothing);
      expect(AppCacheService.instance.reportDraft!.title, newDraft.title);
      expect(tester.takeException(), isNull);
    },
  );
}
