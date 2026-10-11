import 'package:civic_voice/services/app_cache_service.dart';
import 'package:civic_voice/widgets/haptics_preference_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await AppCacheService.instance.initialize();
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
}
