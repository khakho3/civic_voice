import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/admin/widgets/admin_scaffold.dart';
import 'package:civic_voice/features/ministry/widgets/ministry_scaffold.dart';
import 'package:civic_voice/features/municipal/widgets/municipal_scaffold.dart';
import 'package:civic_voice/features/maintenance/widgets/maintenance_scaffold.dart';
import 'package:civic_voice/services/app_cache_service.dart';
import 'package:civic_voice/services/app_haptics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final shells = <String, Widget Function(VoidCallback)>{
    'Admin': (tap) => AdminScaffold(
      body: const SizedBox(),
      selectedTab: AdminTab.dashboard,
      onTabSelected: (_) => tap(),
    ),
    'Ministry': (tap) => MinistryScaffold(
      body: const SizedBox(),
      selectedTab: MinistryTab.dashboard,
      onTabSelected: (_) => tap(),
    ),
    'Municipal': (tap) => MunicipalScaffold(
      body: const SizedBox(),
      selectedTab: MunicipalTab.dashboard,
      onTabSelected: (_) => tap(),
    ),
    'Maintenance': (tap) => MaintenanceScaffold(
      body: const SizedBox(),
      selectedTab: MaintenanceTab.dashboard,
      onTabSelected: (_) => tap(),
    ),
  };
  for (final shell in shells.entries) {
    testWidgets(
      '${shell.key} navigation follows live haptics preference without data reset',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        await AppCacheService.instance.initialize();
        AppHaptics.resetForTest();
        var pulses = 0;
        var navigations = 0;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'HapticFeedback.vibrate') pulses++;
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: shell.value(() => navigations++),
          ),
        );
        await tester.tap(find.text('Home').last);
        await tester.pump();
        expect(pulses, 1);
        expect(navigations, 1);
        await AppCacheService.instance.setHapticFeedbackEnabled(false);
        await tester.tap(find.text('Home').last);
        await tester.pump();
        expect(pulses, 1);
        expect(navigations, 2);
        await AppCacheService.instance.setHapticFeedbackEnabled(true);
        AppHaptics.resetForTest();
        await tester.tap(find.text('Home').last);
        await tester.pump();
        expect(pulses, 2);
        expect(navigations, 3);
      },
    );
  }
}
