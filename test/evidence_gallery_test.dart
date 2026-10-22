import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/widgets/evidence_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const paths = [
  '/not-a-real-photo/one.jpg',
  '/not-a-real-photo/two.jpg',
  '/not-a-real-photo/three.jpg',
];
Widget host({bool reduceMotion = false, int index = 0}) => MaterialApp(
  theme: AppTheme.light,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: EvidenceImageViewer(
      imagePath: paths[index],
      imagePaths: paths,
      initialIndex: index,
    ),
  ),
);

void main() {
  testWidgets('Share follows the selected photo after swiping', (tester) async {
    MethodCall? shared;
    const channel = MethodChannel('dev.fluttercommunity.plus/share');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      shared = call;
      return 'chosen-target';
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    const urls = [
      'https://example.invalid/one.jpg',
      'https://example.invalid/two.jpg',
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: EvidenceImageViewer(imagePath: urls.first, imagePaths: urls),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Share'));
    await tester.pumpAndSettle();
    expect(shared?.method, 'share');
    expect(shared?.arguments['text'], urls[1]);
  });
  testWidgets('gallery starts at tapped evidence and swipes both ways', (
    tester,
  ) async {
    await tester.pumpWidget(host(index: 1));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('3 / 3'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.byTooltip('Share'), findsOneWidget);
    expect(find.byTooltip('Close'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final reduced in [false, true]) {
    testWidgets(
      'accessible gallery controls and limits work reduced=$reduced',
      (tester) async {
        await tester.pumpWidget(host(reduceMotion: reduced));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<IconButton>(
                find.widgetWithIcon(IconButton, Icons.chevron_left),
              )
              .onPressed,
          isNull,
        );
        await tester.tap(find.byTooltip('Next photo'));
        await tester.pumpAndSettle();
        expect(find.text('2 / 3'), findsOneWidget);
        await tester.tap(find.byTooltip('Next photo'));
        await tester.pumpAndSettle();
        expect(find.text('3 / 3'), findsOneWidget);
        expect(
          tester
              .widget<IconButton>(
                find.widgetWithIcon(IconButton, Icons.chevron_right),
              )
              .onPressed,
          isNull,
        );
        await tester.tap(find.byTooltip('Previous photo'));
        await tester.pumpAndSettle();
        expect(find.text('2 / 3'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('single image remains supported without unused paging controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: EvidenceImageViewer(imagePath: paths.first)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byTooltip('Next photo'), findsNothing);
    expect(find.byTooltip('Share'), findsOneWidget);
  });
}
