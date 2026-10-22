import 'dart:async';
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/citizen/widgets/nearby_reports_sheet.dart';
import 'package:civic_voice/features/citizen/widgets/nearby_seconding_card.dart';
import 'package:civic_voice/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const report = NearbySecondingReport(
  id: 'foreign',
  reference: 'CV-1',
  title: 'Blocked drain',
  category: 'Sanitation',
  distanceMeters: 30,
  seconderCount: 0,
);
Widget host(NearbyReportsSheet sheet) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: sheet),
);

void main() {
  for (final width in [320.0, 390.0, 412.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets('nearby summary and confirmation fit $width dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: Scaffold(
              body: NearbyReportsSheet(
                load: () async => [report],
                confirm: (_) async {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Blocked drain'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text("Confirm it's still there"));
        expect(tester.takeException(), isNull);
        expect(find.text("Confirm it's still there"), findsOneWidget);
      });
    }
  }
  testWidgets(
    'API summaries require explicit selection and confirmation; duplicate taps ignored',
    (tester) async {
      var confirmations = 0;
      final pending = Completer<void>();
      await tester.pumpWidget(
        host(
          NearbyReportsSheet(
            load: () async => [report],
            confirm: (selected) {
              expect(selected.id, 'foreign');
              confirmations++;
              return pending.future;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("Confirm it's still there"), findsNothing);
      await tester.tap(find.text('Blocked drain'));
      await tester.pumpAndSettle();
      expect(confirmations, 0);
      await tester.ensureVisible(find.text("Confirm it's still there"));
      await tester.tap(find.text("Confirm it's still there"));
      await tester.pump();
      expect(confirmations, 1);
      final button = find.byType(FilledButton);
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      pending.complete();
      await tester.pumpAndSettle();
      expect(find.text('Thanks for confirming this report.'), findsOneWidget);
      expect(find.text('Blocked drain'), findsNothing);
    },
  );
  testWidgets('Not sure removes only this visit without any confirmation', (
    tester,
  ) async {
    var confirmations = 0;
    await tester.pumpWidget(
      host(
        NearbyReportsSheet(
          load: () async => [report],
          confirm: (_) async {
            confirmations++;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blocked drain'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Not sure'));
    await tester.tap(find.text('Not sure'));
    await tester.pumpAndSettle();
    expect(confirmations, 0);
    expect(find.text('Blocked drain'), findsNothing);
    await tester.ensureVisible(find.text('Refresh nearby'));
    await tester.tap(find.text('Refresh nearby'));
    await tester.pumpAndSettle();
    expect(find.text('Blocked drain'), findsOneWidget);
  });
  testWidgets('failed discovery is not an empty nearby result and can retry', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      host(
        NearbyReportsSheet(
          load: () async {
            calls++;
            if (calls == 1) {
              throw const ApiException(
                statusCode: 400,
                message: 'Allow location',
              );
            }
            return [];
          },
          confirm: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Allow location'), findsOneWidget);
    expect(
      find.text('No reports need confirmation nearby right now.'),
      findsNothing,
    );
    await tester.tap(find.text('Retry nearby'));
    await tester.pumpAndSettle();
    expect(
      find.text('No reports need confirmation nearby right now.'),
      findsOneWidget,
    );
  });
  testWidgets('uncertain save never claims success or permits blind repeat', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      host(
        NearbyReportsSheet(
          load: () async => [report],
          confirm: (_) async {
            calls++;
            throw const ApiException(statusCode: 408, message: 'timeout');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blocked drain'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text("Confirm it's still there"));
    await tester.tap(find.text("Confirm it's still there"));
    await tester.pumpAndSettle();
    expect(find.text('Thanks for confirming this report.'), findsNothing);
    expect(find.text("Confirm it's still there"), findsNothing);
    expect(find.textContaining('We could not verify whether'), findsOneWidget);
    expect(calls, 1);
  });
  testWidgets('late discovery after closing has no UI writes', (tester) async {
    final pending = Completer<List<NearbySecondingReport>>();
    await tester.pumpWidget(
      host(
        NearbyReportsSheet(load: () => pending.future, confirm: (_) async {}),
      ),
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    pending.complete([report]);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
