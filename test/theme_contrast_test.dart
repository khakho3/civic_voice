import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/citizen/widgets/civic_app_chrome.dart';
import 'package:civic_voice/widgets/confirm_dialog.dart';
import 'package:civic_voice/widgets/status_badge.dart';
import 'package:civic_voice/models/report_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG contrast checks on the colour pairs the themes and shared widgets
/// actually render, in both themes. Normal text needs 4.5:1; essential
/// non-text controls and focus need 3:1.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// [top] composited over the opaque [bottom].
Color _over(Color top, Color bottom) => Color.alphaBlend(top, bottom);

const _text = 4.5;
const _control = 3.0;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final themes = <String, ThemeData>{
    'light': AppTheme.light,
    'dark': AppTheme.dark,
  };

  for (final entry in themes.entries) {
    final name = entry.key;
    final theme = entry.value;
    final scheme = theme.colorScheme;
    final semantic = theme.extension<AppSemanticColors>()!;
    final surfaces = <String, Color>{
      'canvas': theme.scaffoldBackgroundColor,
      'surface': scheme.surface,
      'secondary surface': scheme.surfaceContainerLow,
    };

    group('$name theme', () {
      test('filled and elevated actions: ink on fill', () {
        for (final style in [
          theme.filledButtonTheme.style!,
          theme.elevatedButtonTheme.style!,
        ]) {
          final fg = style.foregroundColor!.resolve({})!;
          final bg = style.backgroundColor!.resolve({})!;
          expect(_contrast(fg, bg), greaterThanOrEqualTo(_text));
        }
        expect(
          _contrast(semantic.onAction, semantic.actionFill),
          greaterThanOrEqualTo(_text),
        );
      });

      test('destructive fills use their own readable ink', () {
        expect(
          _contrast(semantic.onError, semantic.error),
          greaterThanOrEqualTo(_text),
        );
        expect(semantic.onFillFor(semantic.error), semantic.onError);
        expect(semantic.onFillFor(semantic.actionFill), semantic.onAction);
        // The brand ink on red is the regression this guards against.
        expect(_contrast(semantic.onAction, semantic.error), lessThan(_text));
      });

      test('text and outlined actions read on every surface', () {
        final textFg = theme.textButtonTheme.style!.foregroundColor!.resolve(
          {},
        )!;
        final outlined = theme.outlinedButtonTheme.style!;
        final outlinedFg = outlined.foregroundColor!.resolve({})!;
        final outlinedSide = outlined.side!.resolve({})!.color;
        for (final surface in surfaces.entries) {
          expect(
            _contrast(textFg, surface.value),
            greaterThanOrEqualTo(_text),
            reason: 'text button on ${surface.key}',
          );
          expect(
            _contrast(outlinedFg, surface.value),
            greaterThanOrEqualTo(_text),
            reason: 'outlined label on ${surface.key}',
          );
          expect(
            _contrast(outlinedSide, surface.value),
            greaterThanOrEqualTo(_control),
            reason: 'outlined border on ${surface.key}',
          );
        }
      });

      test('brand accent, focus and semantic text inks on surfaces', () {
        final inks = <String, Color>{
          'action text': semantic.actionText,
          'error text': semantic.errorText,
          'success text': semantic.successText,
          'warning text': semantic.warningText,
          'info text': semantic.infoText,
        };
        for (final surface in surfaces.entries) {
          for (final ink in inks.entries) {
            expect(
              _contrast(ink.value, surface.value),
              greaterThanOrEqualTo(_text),
              reason: '${ink.key} on ${surface.key}',
            );
          }
          expect(
            _contrast(semantic.focus, surface.value),
            greaterThanOrEqualTo(_control),
            reason: 'focus on ${surface.key}',
          );
        }
      });

      test(
        'every hue maps to a readable foreground, including on its tint',
        () {
          final hues = <Color>[
            AppColors.primary,
            AppColors.primaryDark,
            semantic.success,
            semantic.warning,
            semantic.error,
            semantic.info,
            semantic.statusSubmitted,
            semantic.statusUnderReview,
            semantic.statusAssigned,
            semantic.statusInProgress,
            semantic.statusPendingApproval,
            semantic.statusResolved,
            semantic.statusRejected,
          ];
          for (final hue in hues) {
            final ink = semantic.foregroundFor(hue);
            // TintedBadge: 12% hue over the surface.
            final badge = _over(hue.withValues(alpha: 0.12), scheme.surface);
            expect(
              _contrast(ink, badge),
              greaterThanOrEqualTo(_text),
              reason: 'ink for $hue on its badge tint',
            );
            expect(
              _contrast(ink, theme.scaffoldBackgroundColor),
              greaterThanOrEqualTo(_text),
              reason: 'ink for $hue on canvas',
            );
          }
        },
      );

      test('snackbar and tooltip on their inverse surfaces', () {
        final snack = theme.snackBarTheme;
        final bg = snack.backgroundColor!;
        expect(
          _contrast(snack.actionTextColor!, bg),
          greaterThanOrEqualTo(_text),
        );
        expect(
          _contrast(snack.contentTextStyle!.color!, bg),
          greaterThanOrEqualTo(_text),
        );
        final tooltip = theme.tooltipTheme;
        expect(
          _contrast(
            tooltip.textStyle!.color!,
            (tooltip.decoration! as BoxDecoration).color!,
          ),
          greaterThanOrEqualTo(_text),
        );
      });

      test('input labels, hints, errors and indicators', () {
        final input = theme.inputDecorationTheme;
        final fill = input.fillColor!;
        expect(
          _contrast(input.errorStyle!.color!, fill),
          greaterThanOrEqualTo(_text),
        );
        expect(
          _contrast(input.hintStyle!.color!, fill),
          greaterThanOrEqualTo(_text),
        );
        final focusedLabel = WidgetStateProperty.resolveAs<TextStyle?>(
          input.floatingLabelStyle,
          {WidgetState.focused},
        )!;
        expect(
          _contrast(focusedLabel.color!, fill),
          greaterThanOrEqualTo(_text),
        );
        final spinner = theme.progressIndicatorTheme.color!;
        expect(
          _contrast(spinner, scheme.surface),
          greaterThanOrEqualTo(_control),
        );
        final radio = theme.radioTheme.fillColor!.resolve({
          WidgetState.selected,
        })!;
        expect(
          _contrast(radio, scheme.surface),
          greaterThanOrEqualTo(_control),
        );
        expect(
          _contrast(theme.checkboxTheme.side!.color, scheme.surface),
          greaterThanOrEqualTo(_control),
        );
      });

      test('navigation selected and unselected labels', () {
        final nav = theme.navigationBarTheme;
        final bg = nav.backgroundColor!;
        for (final states in [
          {WidgetState.selected},
          <WidgetState>{},
        ]) {
          final label = nav.labelTextStyle!.resolve(states)!;
          expect(
            _contrast(label.color!, bg),
            greaterThanOrEqualTo(_text),
            reason: 'nav label $states',
          );
        }
      });

      testWidgets('Citizen Create FAB and selected nav item', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: CivicBottomNav(
                  selectedIndex: 0,
                  onDestinationSelected: (_) {},
                ),
              ),
            ),
          ),
        );
        final plus = tester.widget<Icon>(find.byIcon(AppIcons.add));
        final disc = tester.widget<Material>(
          find
              .ancestor(
                of: find.byIcon(AppIcons.add),
                matching: find.byType(Material),
              )
              .first,
        );
        expect(
          _contrast(plus.color!, disc.color!),
          greaterThanOrEqualTo(_control),
        );
        expect(
          _contrast(plus.color!, disc.color!),
          greaterThanOrEqualTo(_text),
        );
        final home = tester.widget<Text>(find.text('Home'));
        // The nav sits on glass over the canvas; check against both.
        for (final background in [
          theme.scaffoldBackgroundColor,
          semantic.glassNavSurface.withValues(alpha: 1),
        ]) {
          expect(
            _contrast(home.style!.color!, background),
            greaterThanOrEqualTo(_text),
          );
        }
      });

      testWidgets('confirm dialog actions, destructive and standard', (
        tester,
      ) async {
        for (final destructive in [true, false]) {
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => showConfirmDialog(
                      context,
                      title: 'Log out?',
                      message: 'Message',
                      confirmLabel: 'Log Out',
                      destructive: destructive,
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();

          final confirm = tester.widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Log Out'),
          );
          final style = confirm.style ?? theme.filledButtonTheme.style!;
          final fg =
              (style.foregroundColor ??
                      theme.filledButtonTheme.style!.foregroundColor)!
                  .resolve({})!;
          final bg =
              (style.backgroundColor ??
                      theme.filledButtonTheme.style!.backgroundColor)!
                  .resolve({})!;
          expect(
            _contrast(fg, bg),
            greaterThanOrEqualTo(_text),
            reason: 'destructive=$destructive',
          );
          if (destructive) expect(bg, semantic.error);

          final dialogSize = tester.getSize(find.byType(AlertDialog));
          final button = tester.getSize(
            find.widgetWithText(FilledButton, 'Log Out'),
          );
          // Compact trailing action, 48px tall, not a full-width CTA.
          expect(button.height, greaterThanOrEqualTo(48));
          expect(button.width, lessThan(dialogSize.width / 2));

          await tester.tap(find.text('Cancel'));
          await tester.pumpAndSettle();
        }
      });

      testWidgets('status badges use readable ink', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Column(
                children: [
                  for (final status in ReportStatus.values)
                    ReportStatusBadge(status: status),
                ],
              ),
            ),
          ),
        );
        for (final status in ReportStatus.values) {
          final label = tester.widget<Text>(find.text(status.label));
          final badge = _over(
            status.color.withValues(alpha: 0.12),
            scheme.surface,
          );
          expect(
            _contrast(label.style!.color!, badge),
            greaterThanOrEqualTo(_text),
            reason: status.name,
          );
        }
      });
    });
  }
}
