import 'dart:ui' show Tristate;

import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/widgets/civic_filter_chip.dart';
import 'package:civic_voice/widgets/text_filter_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child, {bool dark = false, bool reduced = false}) =>
    MaterialApp(
      theme: dark ? AppTheme.dark : AppTheme.light,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: Scaffold(body: Center(child: child)),
      ),
    );

void main() {
  for (final width in [320.0, 390.0, 412.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets('scrollable long pills at $width dark=$dark', (tester) async {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: Scaffold(
              body: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(2)),
                child: TextFilterChips<int>(
                  options: const [
                    TextFilterOption(value: 0, label: 'Open and acknowledged'),
                    TextFilterOption(value: 1, label: 'Awaiting confirmation'),
                    TextFilterOption(value: 2, label: 'All alerts'),
                  ],
                  selected: 0,
                  onSelected: (_) {},
                ),
              ),
            ),
          ),
        );
        final scroll = find.byType(ListView);
        await tester.drag(scroll, const Offset(-1000, 0));
        await tester.pumpAndSettle();
        expect(find.text('All alerts').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
  for (final dark in [false, true]) {
    testWidgets('controlled choice, native motion and semantics dark=$dark', (
      tester,
    ) async {
      var selected = false;
      var changes = 0;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (_, update) => CivicFilterChip(
              label: 'Under review',
              selected: selected,
              onTap: () => update(() {
                selected = !selected;
                changes++;
              }),
            ),
          ),
          dark: dark,
        ),
      );
      final chip = find.byType(ChoiceChip);
      final idleWidth = tester.getSize(chip).width;
      expect(tester.getSize(chip).height, greaterThanOrEqualTo(48));
      await tester.tap(chip);
      await tester.pump();
      expect(selected, isTrue);
      expect(
        tester.getSemantics(chip).flagsCollection.isSelected == Tristate.isTrue,
        isTrue,
      );
      await tester.pump(const Duration(milliseconds: 75));
      final middleWidth = tester.getSize(chip).width;
      await tester.pumpAndSettle();
      expect(middleWidth, greaterThan(idleWidth));
      expect(middleWidth, lessThan(tester.getSize(chip).width));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(selected, isFalse);
      expect(changes, 2);
    });

    testWidgets('busy choice and picker cannot activate dark=$dark', (
      tester,
    ) async {
      var calls = 0;
      for (final picker in [false, true]) {
        await tester.pumpWidget(
          host(
            CivicFilterChip(label: 'Disabled', selected: true, picker: picker),
            dark: dark,
          ),
        );
        final chip = find.byType(RawChip);
        expect(
          tester.getSemantics(chip).flagsCollection.isEnabled ==
              Tristate.isTrue,
          isFalse,
        );
        await tester.tap(chip);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        expect(calls, 0);
      }
      await tester.pumpWidget(
        host(
          CivicFilterChip(
            label: 'Region',
            selected: true,
            picker: true,
            onTap: () => calls++,
          ),
          dark: dark,
        ),
      );
      await tester.tap(find.text('Region'));
      expect(calls, 1);
    });

    testWidgets('reduced motion settles selection immediately dark=$dark', (
      tester,
    ) async {
      Widget choice(bool selected) => host(
        CivicFilterChip(label: 'Open', selected: selected, onTap: () {}),
        dark: dark,
        reduced: true,
      );
      await tester.pumpWidget(choice(false));
      await tester.pumpWidget(choice(true));
      await tester.pump();
      final size = tester.getSize(find.byType(ChoiceChip));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.getSize(find.byType(ChoiceChip)), size);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  }

  testWidgets('nullable filters keep no-op, selection and disabled rules', (
    tester,
  ) async {
    final values = <int?>[];
    Widget row(bool enabled) => host(
      TextFilterChips<int?>(
        options: const [
          TextFilterOption(value: null, label: 'All'),
          TextFilterOption(value: 1, label: 'Assigned'),
        ],
        selected: null,
        enabled: enabled,
        onSelected: values.add,
      ),
    );
    await tester.pumpWidget(row(true));
    await tester.tap(find.text('All'));
    expect(values, isEmpty);
    await tester.tap(find.text('Assigned'));
    expect(values, [1]);
    await tester.pumpWidget(row(false));
    await tester.tap(find.text('Assigned'), warnIfMissed: false);
    expect(values, [1]);
  });
}
