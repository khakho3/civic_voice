import 'dart:math' as math;
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/widgets/busy_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double contrast(Color a, Color b) =>
    (math.max(a.computeLuminance(), b.computeLuminance()) + 0.05) /
    (math.min(a.computeLuminance(), b.computeLuminance()) + 0.05);

void main() {
  for (final dark in [false, true]) {
    for (final kind in [
      'filled',
      'elevated',
      'outlined',
      'text',
      'gold',
      'red',
    ]) {
      testWidgets('busy $kind remains visible and stable, dark=$dark', (
        tester,
      ) async {
        final theme = dark ? AppTheme.dark : AppTheme.light;
        var busy = false;
        late StateSetter change;
        Widget button() {
          final label = BusyLabel(
            busy: busy,
            busyLabel: 'Saving changes',
            child: const Text('Save Changes'),
          );
          final action = busy ? null : () {};
          return switch (kind) {
            'elevated' => ElevatedButton(onPressed: action, child: label),
            'outlined' => OutlinedButton(onPressed: action, child: label),
            'text' => TextButton(onPressed: action, child: label),
            _ => FilledButton(
              onPressed: action,
              style: kind == 'gold' || kind == 'red'
                  ? ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        kind == 'gold'
                            ? const Color(0xFFFCD116)
                            : const Color(0xFFBA1A1A),
                      ),
                    )
                  : null,
              child: label,
            ),
          };
        }

        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Center(
                child: StatefulBuilder(
                  builder: (_, update) {
                    change = update;
                    return button();
                  },
                ),
              ),
            ),
          ),
        );
        final label = find.byType(BusyLabel);
        final before = tester.getSize(label);
        change(() => busy = true);
        await tester.pump(const Duration(milliseconds: 300));
        final orb = find.byType(BusyIndicator);
        expect(orb, findsOneWidget);
        expect(tester.getSize(label), before);
        final paint = tester.widget<CustomPaint>(
          find.descendant(of: orb, matching: find.byType(CustomPaint)),
        );
        final dynamic painter = paint.painter;
        final ink = painter.ink as Color;
        final material = find
            .ancestor(of: orb, matching: find.byType(Material))
            .first;
        final fill =
            tester.widget<Material>(material).color ?? Colors.transparent;
        final background = Color.alphaBlend(fill, theme.colorScheme.surface);
        expect(contrast(ink, background), greaterThanOrEqualTo(4.5));
        final track = Color.alphaBlend(
          ink.withValues(alpha: painter.trackOpacity as double),
          background,
        );
        expect(contrast(track, background), greaterThanOrEqualTo(3));
        expect(
          tester.widget<BusyIndicator>(orb).semanticsLabel,
          'Saving changes',
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
