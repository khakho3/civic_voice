import 'package:civic_voice/features/admin/screens/admin_overview_screen.dart';
import 'package:civic_voice/features/admin/services/admin_resource.dart';
import 'package:civic_voice/features/admin/models/admin_overview.dart';
import 'admin_live_overview_test.dart' show overviewFixture;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/widgets/civic_filter_chip.dart';

Future<Uint8List> pixels(WidgetTester tester, GlobalKey key) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return data!.buffer.asUint8List();
  }))!;
}

int greatestChange(Uint8List a, Uint8List b) {
  var result = 0;
  for (var i = 0; i < a.length; i++) {
    final change = (a[i] - b[i]).abs();
    if (change > result) result = change;
  }
  return result;
}

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'tap surfaces stay quiet while held and activate only on release dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(280, 150);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final key = GlobalKey();
        var calls = 0;
        void activate() => calls++;
        final controls = <String, Widget>{
          'filled auth action': FilledButton(
            onPressed: activate,
            child: const Text('Tap target'),
          ),
          'outlined action': OutlinedButton(
            onPressed: activate,
            child: const Text('Tap target'),
          ),
          'text action': TextButton(
            onPressed: activate,
            child: const Text('Tap target'),
          ),
          'icon action': IconButton(
            onPressed: activate,
            icon: const Text('Tap target'),
          ),
          'dashboard-style card': Material(
            color: (dark ? AppTheme.dark : AppTheme.light).colorScheme.surface,
            child: InkWell(
              onTap: activate,
              child: const SizedBox(
                width: 220,
                height: 80,
                child: Center(child: Text('Tap target')),
              ),
            ),
          ),
          'choice pill': CivicFilterChip(
            label: 'Tap target',
            selected: false,
            onTap: activate,
          ),
          'picker pill': CivicFilterChip(
            label: 'Tap target',
            selected: false,
            picker: true,
            onTap: activate,
          ),
        };
        for (final entry in controls.entries) {
          await tester.pumpWidget(
            RepaintBoundary(
              key: key,
              child: MaterialApp(
                theme: dark ? AppTheme.dark : AppTheme.light,
                home: Scaffold(body: Center(child: entry.value)),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final idle = await pixels(tester, key);
          final before = calls;
          final gesture = await tester.startGesture(
            tester.getCenter(find.text('Tap target')),
          );
          for (final milliseconds in [80, 100, 150]) {
            await tester.pump(Duration(milliseconds: milliseconds));
            final held = await pixels(tester, key);
            expect(
              greatestChange(idle, held),
              lessThanOrEqualTo(12),
              reason: '${entry.key} should not flash/sparkle while held',
            );
            expect(calls, before);
          }
          await gesture.up();
          await tester.pumpAndSettle();
          expect(calls, before + 1);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        }
      },
    );
    testWidgets(
      'real Admin Users metric stays quiet and navigates once dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(412, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final key = GlobalKey();
        final resource = AdminResource<AdminOverview>(
          owner: () => 'fixture',
          credential: () async => 'fixture',
          fetch: (_) async => overviewFixture(),
          parse: AdminOverview.parse,
        );
        addTearDown(resource.dispose);
        var users = 0;
        void nothing() {}
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              home: AdminOverviewScreen(
                directory: resource,
                superAdmin: true,
                onUsers: () => users++,
                onTeams: nothing,
                onActivity: nothing,
                onAlerts: nothing,
                onRoles: nothing,
                onSettings: nothing,
                onProfile: nothing,
                onNotifications: nothing,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(
          () => precacheImage(
            const AssetImage(AppAssets.logoApp),
            key.currentContext!,
          ),
        );
        await tester.pumpAndSettle();
        final idle = await pixels(tester, key);
        final stats = find.byKey(const ValueKey('admin-overview-stats'));
        final rectangle = tester.getRect(stats);
        final gesture = await tester.startGesture(
          tester.getCenter(find.text('Total users').first),
        );
        await tester.pump(const Duration(milliseconds: 200));
        expect(
          greatestChange(idle, await pixels(tester, key)),
          lessThanOrEqualTo(12),
        );
        expect(tester.getRect(stats), rectangle);
        expect(users, 0);
        await gesture.up();
        await tester.pumpAndSettle();
        expect(users, 1);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'keyboard focus stays visible and disabled buttons stay inert dark=$dark',
      (tester) async {
        final key = GlobalKey();
        final focus = FocusNode();
        addTearDown(focus.dispose);
        var calls = 0;
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              home: Scaffold(
                body: Center(
                  child: FilledButton(
                    focusNode: focus,
                    onPressed: () => calls++,
                    child: const Text('Keyboard action'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final idle = await pixels(tester, key);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        expect(focus.hasFocus, isTrue);
        expect(greatestChange(idle, await pixels(tester, key)), greaterThan(0));
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(calls, 1);
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: const Scaffold(
              body: FilledButton(
                onPressed: null,
                child: Text('Disabled action'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Disabled action'));
        await tester.pumpAndSettle();
        expect(calls, 1);
      },
    );
  }
}
