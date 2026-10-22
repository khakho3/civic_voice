import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/widgets/civic_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [320.0, 390.0, 412.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets('shared sheet selection and backdrop fit $width dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        int? selected;
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    selected = await showCivicBottomSheet<int>(
                      context: context,
                      builder: (context) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              title: const Text('Choice seven'),
                              onTap: () => Navigator.pop(context, 7),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.byType(CivicSheetSurface), findsOneWidget);
        expect(find.byType(BackdropFilter), findsNWidgets(2));
        final surface = tester.getRect(find.byType(CivicSheetSurface));
        expect(surface.bottom, lessThanOrEqualTo(900));
        expect(surface.width, lessThanOrEqualTo(width));
        await tester.tap(find.text('Choice seven'));
        await tester.pumpAndSettle();
        expect(selected, 7);
        expect(find.byType(CivicSheetSurface), findsNothing);
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await tester.tapAt(const Offset(5, 5));
        await tester.pumpAndSettle();
        expect(selected, isNull);
        expect(find.byType(CivicSheetSurface), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
  for (final reduced in [false, true]) {
    testWidgets('native motion and drag dismissal reduced=$reduced', (
      tester,
    ) async {
      ModalBottomSheetRoute<dynamic>? route;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Padding(
              padding: EdgeInsets.zero,
              child: Scaffold(
                body: TextButton(
                  onPressed: () => showCivicBottomSheet<void>(
                    context: context,
                    builder: (context) {
                      route =
                          ModalRoute.of(context)!
                              as ModalBottomSheetRoute<dynamic>;
                      return const SizedBox(
                        height: 200,
                        child: Text('Sheet content'),
                      );
                    },
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(
        route!.sheetAnimationStyle!.duration,
        reduced ? Duration.zero : AppMotionDuration.standard,
      );
      expect(
        route!.sheetAnimationStyle!.reverseDuration,
        reduced ? Duration.zero : AppMotionDuration.fast,
      );
      final surface = tester.getRect(find.byType(CivicSheetSurface));
      await tester.dragFrom(
        Offset(surface.center.dx, surface.top + 20),
        const Offset(0, 240),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CivicSheetSurface), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'form sheets use an opaque surface and explicit close without a drag escape',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showCivicBottomSheet<void>(
                  context: context,
                  form: true,
                  enableDrag: false,
                  builder: (_) =>
                      const SizedBox(height: 100, child: Text('Form')),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final surface = find.byType(CivicSheetSurface);
      final background = tester
          .widgetList<Material>(
            find.descendant(of: surface, matching: find.byType(Material)),
          )
          .first;
      expect(background.color!.a, 1);
      expect(find.byTooltip('Close'), findsOneWidget);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(surface, findsNothing);
    },
  );
}
