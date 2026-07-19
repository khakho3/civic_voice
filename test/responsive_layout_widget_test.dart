import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/admin/screens/admin_dashboard_screen.dart';
import 'package:civic_voice/features/citizen/screens/citizen_dashboard_screen.dart';
import 'package:civic_voice/features/maintenance/screens/dashboard_screen.dart'
    as maintenance;
import 'package:civic_voice/features/ministry/screens/ministry_dashboard_screen.dart';
import 'package:civic_voice/features/municipal/screens/municipal_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final surfaces = <String, Widget>{
    'citizen': const CitizenDashboardScreen(),
    'admin': const AdminDashboardScreen(),
    'ministry': const MinistryDashboardScreen(),
    'municipal': const MunicipalDashboardScreen(),
    'maintenance': const maintenance.DashboardScreen(),
  };
  const sizes = <String, Size>{
    'small phone': Size(320, 720),
    'medium phone': Size(430, 932),
    'tablet': Size(1024, 1366),
  };

  for (final surface in surfaces.entries) {
    for (final viewport in sizes.entries) {
      testWidgets(
        '${surface.key} dashboard has no layout exception on ${viewport.key}',
        (tester) async {
          tester.view.physicalSize = viewport.value;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            MaterialApp(theme: AppTheme.light, home: surface.value),
          );
          await tester.pump();

          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
