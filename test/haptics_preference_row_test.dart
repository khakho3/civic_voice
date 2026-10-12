import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/services/app_cache_service.dart';
import 'package:civic_voice/services/app_haptics.dart';
import 'package:civic_voice/widgets/confirm_dialog.dart';
import 'package:civic_voice/widgets/glass_dialog_backdrop.dart';
import 'package:civic_voice/widgets/haptics_preference_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records haptic platform calls; [fail] makes the platform throw.
class _HapticChannel {
  int calls = 0;
  bool fail = false;

  void install(WidgetTester tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method != 'HapticFeedback.vibrate') return null;
        calls++;
        if (fail) throw PlatformException(code: 'no_vibrator');
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await AppCacheService.instance.initialize();
    AppHaptics.resetForTest();
  });

  testWidgets('persists the haptic feedback opt-out', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HapticsPreferenceRow())),
    );

    expect(find.text('Haptic feedback'), findsOneWidget);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(AppCacheService.instance.hapticFeedbackEnabled, isFalse);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
  });

  testWidgets('device guidance sits behind an info button, not a caption', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: HapticsPreferenceRow()),
      ),
    );

    expect(
      find.text('Your device settings can still turn vibration off.'),
      findsNothing,
    );
    final info = find.byTooltip('About Haptic feedback');
    expect(info, findsOneWidget);
    expect(tester.getSize(info).height, greaterThanOrEqualTo(48));

    await tester.tap(info);
    await tester.pumpAndSettle();

    expect(find.byType(GlassDialogBackdrop), findsOneWidget);
    expect(
      find.text(
        'Gentle vibration for supported actions. Your phone must support '
        'haptics, and device settings may silence it.',
      ),
      findsOneWidget,
    );
    // Opening help did not toggle the preference.
    expect(AppCacheService.instance.hapticFeedbackEnabled, isTrue);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );
  });

  testWidgets('opt-out silences pulses and survives a restart', (tester) async {
    final channel = _HapticChannel()..install(tester);

    AppHaptics.activate();
    await tester.pump();
    expect(channel.calls, 1);

    await AppCacheService.instance.setHapticFeedbackEnabled(false);
    AppHaptics.resetForTest();
    AppHaptics.activate();
    await tester.pump();
    expect(channel.calls, 1);

    // A fresh start reads the stored opt-out.
    await AppCacheService.instance.initialize();
    expect(AppHaptics.enabled, isFalse);
    AppHaptics.activate();
    await tester.pump();
    expect(channel.calls, 1);
  });

  testWidgets('rapid activations collapse into one pulse', (tester) async {
    final channel = _HapticChannel()..install(tester);

    AppHaptics.activate();
    AppHaptics.activate();
    AppHaptics.activate();
    await tester.pump();
    expect(channel.calls, 1);

    AppHaptics.resetForTest();
    AppHaptics.activate();
    await tester.pump();
    expect(channel.calls, 2);
  });

  testWidgets('a failing vibrator never blocks the action', (tester) async {
    final channel = _HapticChannel()
      ..fail = true
      ..install(tester);
    bool? confirmed;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                confirmed = await showConfirmDialog(
                  context,
                  title: 'Log out?',
                  message: 'Message',
                  confirmLabel: 'Log Out',
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
    await tester.tap(find.text('Log Out'));
    await tester.pumpAndSettle();

    expect(channel.calls, 1);
    expect(confirmed, isTrue);
    expect(tester.takeException(), isNull);
  });
}
