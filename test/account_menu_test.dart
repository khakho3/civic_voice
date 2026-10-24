import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/widgets/account_menu_button.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'account popup preserves native placement and confirmed logout dark=$dark',
      (tester) async {
        var profiles = 0, logouts = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: Scaffold(
              appBar: AppBar(
                actions: [
                  AccountMenuButton(
                    onProfile: () => profiles++,
                    onSignOut: (_) async {
                      logouts++;
                    },
                  ),
                ],
              ),
            ),
          ),
        );
        final trigger = find.byTooltip('Account options');
        await tester.tap(trigger);
        await tester.pumpAndSettle();
        final profile = find.widgetWithText(PopupMenuItem<String>, 'Profile');
        expect(
          tester.getTopLeft(profile).dy,
          greaterThan(tester.getTopLeft(trigger).dy),
        );
        await tester.tap(profile);
        await tester.pumpAndSettle();
        expect(profiles, 1);
        expect(logouts, 0);
        await tester.tap(trigger);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Log Out'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(logouts, 0);
        await tester.tap(trigger);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Log Out'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Log Out'));
        await tester.pumpAndSettle();
        expect(logouts, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
