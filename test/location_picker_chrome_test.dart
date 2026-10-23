import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/citizen/widgets/location_picker_chrome.dart';
import 'package:civic_voice/widgets/busy_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final dark in [false, true]) {
    for (final width in [320.0, 390.0, 412.0]) {
      testWidgets(
        'map search is compact, round and clearable at $width dark=$dark',
        (tester) async {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final controller = TextEditingController();
          addTearDown(controller.dispose);
          String? changed;
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              home: Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(16),
                  child: LocationPickerSearchField(
                    controller: controller,
                    onChanged: (v) => changed = v,
                  ),
                ),
              ),
            ),
          );
          expect(
            tester.getSize(find.byType(TextField)).height,
            inInclusiveRange(48, 50),
          );
          final field = tester.widget<TextField>(find.byType(TextField));
          expect(
            (field.decoration!.enabledBorder! as OutlineInputBorder)
                .borderRadius,
            AppRadius.allXl,
          );
          await tester.enterText(find.byType(TextField), 'Wusuta');
          await tester.pump();
          await tester.tap(find.byTooltip('Clear location search'));
          await tester.pump();
          expect(controller.text, isEmpty);
          expect(changed, '');
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'search and capture reuse the orb and capture message wraps with large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: MediaQuery(
            data: const MediaQueryData(
              disableAnimations: true,
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    LocationPickerSearchField(
                      controller: controller,
                      onChanged: (_) {},
                      searching: true,
                    ),
                    const LocationPickerBusyStatus(
                      message: 'Detecting your current location...',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BusyIndicator), findsNWidgets(2));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Detecting your current location...'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
