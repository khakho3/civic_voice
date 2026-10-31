import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/core/widgets/ghana_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'page loading stays static and readable dark=$dark scale=$scale',
        (tester) async {
          tester.view.physicalSize = const Size(320, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final semantics = tester.ensureSemantics();
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: const Scaffold(
                  body: GhanaLoadingIndicator(label: 'Loading audit event'),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Loading audit event'), findsOneWidget);
          expect(find.bySemanticsLabel('Loading audit event'), findsOneWidget);
          expect(
            find.descendant(
              of: find.byType(GhanaLoadingIndicator),
              matching: find.byType(CustomPaint),
            ),
            findsNothing,
          );
          // A pending page status must not keep scheduling animation frames.
          await tester.pump(const Duration(seconds: 1));
          expect(tester.binding.hasScheduledFrame, isFalse);
          expect(tester.takeException(), isNull);
          semantics.dispose();
        },
      );
    }
  }
}
