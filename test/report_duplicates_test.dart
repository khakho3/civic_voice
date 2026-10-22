import 'dart:async';

import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/citizen/models/report_draft.dart';
import 'package:civic_voice/features/citizen/screens/create_report_screen.dart';
import 'package:civic_voice/features/citizen/screens/photo_upload_screen.dart';
import 'package:civic_voice/features/citizen/services/report_duplicates_service.dart';
import 'package:civic_voice/features/citizen/widgets/report_duplicates_sheet.dart';
import 'package:civic_voice/services/api_client.dart';
import 'package:civic_voice/services/app_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> candidate({
  bool own = false,
  bool seconded = false,
  bool eligible = true,
  String status = 'SUBMITTED',
}) => {
  'id': 'report-1',
  'publicReference': 'CV-2026-000001',
  'title': 'Blocked drain',
  'category': 'Sanitation',
  'latitude': 5.8,
  'longitude': -0.1,
  'distanceMeters': 34,
  'status': status,
  'ownedByMe': own,
  'secondedByMe': seconded,
  'canSecond': eligible,
};
const draft = ReportDraft(
  title: 'Blocked drain',
  description: 'Overflowing drain',
  category: 'Sanitation',
  location: 'Issue pin away from my home',
  community: 'Test',
  latitude: 5.8,
  longitude: -0.1,
);

ReportDuplicatesService service(
  Future<List<Map<String, dynamic>>> Function(String, Map<String, dynamic>)
  request,
) => ReportDuplicatesService(
  account: () => 'alice',
  token: () async => 'token',
  request: request,
);

Future<void> continueToPhotos(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Continue to Photos'),
    260,
    scrollable: find.byType(Scrollable).first,
  );
  await Scrollable.ensureVisible(
    tester.element(find.text('Continue to Photos')),
    alignment: .5,
  );
  await tester.pump();
  await tester.tap(find.text('Continue to Photos'));
  await tester.pump();
}

void main() {
  test(
    'discovery sends only issue pin and context, never presence or private draft fields',
    () async {
      final rows = await service((token, issue) async {
        expect(token, 'token');
        expect(issue, {
          'title': draft.title,
          'description': draft.description,
          'category': draft.category,
          'latitude': 5.8,
          'longitude': -0.1,
        });
        return [candidate()];
      }).suggest(draft);
      expect(rows.single.canSecond, isTrue);
    },
  );
  test('late discovery after account switch is rejected', () async {
    String? owner = 'alice';
    final response = Completer<List<Map<String, dynamic>>>();
    final sent = Completer<void>();
    final subject = ReportDuplicatesService(
      account: () => owner,
      token: () async => 'token',
      request: (_, _) {
        sent.complete();
        return response.future;
      },
    );
    final result = subject.suggest(draft);
    await sent.future;
    owner = 'bob';
    response.complete([candidate()]);
    await expectLater(result, throwsA(isA<ApiException>()));
  });
  for (final mutation in <String, Object?>{
    'canSecond': 'yes',
    'latitude': double.nan,
    'distanceMeters': 101,
    'status': 'RESOLVED',
    'publicReference': '',
  }.entries) {
    test(
      'malformed ${mutation.key} candidate never becomes a confirmation option',
      () async {
        await expectLater(
          service(
            (_, _) async => [
              {...candidate(), mutation.key: mutation.value},
            ],
          ).suggest(draft),
          throwsA(anything),
        );
      },
    );
  }
  test(
    'own, already-seconded and work-started reports cannot claim eligibility',
    () {
      for (final raw in [
        candidate(own: true),
        candidate(seconded: true),
        candidate(status: 'IN_PROGRESS'),
      ]) {
        expect(
          () => ReportDuplicateCandidate.fromApi(raw),
          throwsFormatException,
        );
      }
    },
  );
  test('duplicated DTO identities are rejected', () async {
    await expectLater(
      service((_, _) async => [candidate(), candidate()]).suggest(draft),
      throwsFormatException,
    );
  });

  for (final lookupFails in [false, true]) {
    testWidgets(
      'no-match/failure ($lookupFails) continues once to Photos with the saved pin',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        await AppCacheService.instance.initialize(accountId: 'alice');
        await AppCacheService.instance.saveReportDraft(draft);
        var calls = 0;
        final response = Completer<List<Map<String, dynamic>>>();
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: CreateReportScreen(
              duplicates: service((_, _) {
                calls++;
                return response.future;
              }),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await continueToPhotos(tester);
        // Tapping the disabled action again cannot run another advisory request.
        await tester.tap(find.bySemanticsLabel('Checking similar reports'));
        await tester.pump();
        expect(calls, 1);
        if (lookupFails) {
          response.completeError(StateError('offline'));
        } else {
          response.complete([]);
        }
        await tester.pumpAndSettle();
        expect(find.byType(PhotoUploadScreen), findsOneWidget);
        expect(
          tester
              .widget<PhotoUploadScreen>(find.byType(PhotoUploadScreen))
              .reportLatitude,
          5.8,
        );
        expect(AppCacheService.instance.reportDraft!.title, draft.title);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'editing during discovery discards stale matches instead of advancing',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await AppCacheService.instance.initialize(accountId: 'alice');
      await AppCacheService.instance.saveReportDraft(draft);
      final response = Completer<List<Map<String, dynamic>>>();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: CreateReportScreen(
            duplicates: service((_, _) => response.future),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await continueToPhotos(tester);
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await tester.pump();
      await tester.enterText(find.byType(TextField).first, 'Another issue');
      response.complete([candidate()]);
      await tester.pumpAndSettle();
      expect(find.byType(PhotoUploadScreen), findsNothing);
      expect(find.byType(ReportDuplicatesSheet), findsNothing);
      expect(find.text('Another issue'), findsOneWidget);
      expect(
        find.text(
          'Report details changed. Continue again to check the updated issue.',
        ),
        findsOneWidget,
      );
    },
  );

  for (final second in [false, true]) {
    testWidgets(
      'Create match decision second=$second preserves the correct draft lifecycle',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        await AppCacheService.instance.initialize(accountId: 'alice');
        await AppCacheService.instance.saveReportDraft(draft);
        var confirms = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: CreateReportScreen(
              duplicates: service((_, _) async => [candidate()]),
              confirmDuplicate: (_) async {
                confirms++;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        await continueToPhotos(tester);
        await tester.pumpAndSettle();
        expect(find.byType(ReportDuplicatesSheet), findsOneWidget);
        expect(find.byType(PhotoUploadScreen), findsNothing);
        if (second) {
          await tester.tap(find.text('This is the same issue'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          await tester.tap(find.text('Confirm existing issue'));
        } else {
          await tester.tap(find.text('Report a different issue'));
        }
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 500));
        expect(confirms, second ? 1 : 0);
        expect(
          find.byType(PhotoUploadScreen),
          second ? findsNothing : findsOneWidget,
        );
        expect(
          AppCacheService.instance.reportDraft?.title,
          second ? isNull : draft.title,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  Future<void> openSheet(
    WidgetTester tester,
    List<Map<String, dynamic>> rows,
    Future<void> Function() confirm, {
    ValueChanged<DuplicateDecision?>? result,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final decision = await showModalBottomSheet<DuplicateDecision>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => ReportDuplicatesSheet(
                    candidates: rows
                        .map(ReportDuplicateCandidate.fromApi)
                        .toList(),
                    confirm: (_) => confirm(),
                  ),
                );
                result?.call(decision);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'ineligible cards explain why; distinct choice needs no confirmation request',
    (tester) async {
      DuplicateDecision? result;
      await openSheet(
        tester,
        [candidate(seconded: true, eligible: false)],
        () async => fail('must not confirm'),
        result: (value) => result = value,
      );
      expect(
        find.text('You have already confirmed this report.'),
        findsOneWidget,
      );
      expect(find.text('This is the same issue'), findsNothing);
      await tester.tap(find.text('Report a different issue'));
      await tester.pumpAndSettle();
      expect(result!.choice, DuplicateChoice.different);
    },
  );
  testWidgets(
    'explicit confirmation is single-flight and returns seconded, not a new report',
    (tester) async {
      var calls = 0;
      DuplicateDecision? result;
      final response = Completer<void>();
      await openSheet(tester, [candidate()], () {
        calls++;
        return response.future;
      }, result: (value) => result = value);
      await tester.tap(find.text('This is the same issue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(calls, 0);
      await tester.tap(find.text('Confirm existing issue'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(calls, 1);
      expect(result, isNull);
      expect(
        tester
            .widget<OutlinedButton>(
              find.ancestor(
                of: find.text('This is the same issue'),
                matching: find.byType(OutlinedButton),
              ),
            )
            .onPressed,
        isNull,
      );
      response.complete();
      await tester.pumpAndSettle();
      expect(result!.choice, DuplicateChoice.seconded);
      expect(result!.candidate!.report.id, 'report-1');
    },
  );
  testWidgets(
    'uncertain confirmation offers no blind repeat and keeps the draft route',
    (tester) async {
      await openSheet(tester, [
        candidate(),
      ], () async => throw StateError('connection lost'));
      await tester.tap(find.text('This is the same issue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Confirm existing issue'));
      await tester.pumpAndSettle();
      expect(find.textContaining('could not verify whether'), findsOneWidget);
      expect(
        tester
            .widget<OutlinedButton>(
              find.ancestor(
                of: find.text('This is the same issue'),
                matching: find.byType(OutlinedButton),
              ),
            )
            .onPressed,
        isNull,
      );
      await tester.scrollUntilVisible(
        find.text('Back to my draft'),
        120,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Back to my draft'), findsOneWidget);
    },
  );
}
