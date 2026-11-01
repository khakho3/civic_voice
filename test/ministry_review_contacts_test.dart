import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/ministry/models/municipal_performance_data.dart';
import 'package:civic_voice/features/ministry/screens/ministry_municipality_detail_screen.dart';
import 'package:civic_voice/models/region.dart';
import 'ministry_review_fixtures.dart';

class FixtureLauncher extends UrlLauncherPlatform {
  FixtureLauncher(this.failWithException);
  final bool failWithException;
  String? launched;
  @override
  LinkDelegate? get linkDelegate => null;
  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched = url;
    if (failWithException) throw PlatformException(code: 'denied');
    return false;
  }
}

void main() {
  for (final action in ['Call', 'Message']) {
    for (final throws in [false, true]) {
      testWidgets('$action reports device failure throws=$throws', (
        tester,
      ) async {
        final old = UrlLauncherPlatform.instance;
        final launcher = FixtureLauncher(throws);
        UrlLauncherPlatform.instance = launcher;
        addTearDown(() => UrlLauncherPlatform.instance = old);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: const MinistryMunicipalityDetailScreen(
              municipality: reviewMunicipality,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(action));
        await tester.pumpAndSettle();
        await tester.tap(find.text(action));
        await tester.pumpAndSettle();
        final scheme = action == 'Call' ? 'tel' : 'sms';
        expect(launcher.launched, '$scheme:+233000000000');
        expect(
          find.text('Could not open $scheme on this device.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('recorded officer without phone has no enabled contact action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MinistryMunicipalityDetailScreen(
          municipality: RegionalLeaderItem(
            name: 'Fixture municipality',
            region: Region.ashanti,
            resolvedPercent: 0,
            responseTimeLabel: 'No reports',
            officerName: '',
            officerPhone: '',
            officers: [
              MinistryOfficerContact(
                publicId: 'FIXTURE',
                name: 'Fixture officer',
                phone: '   ',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Phone unavailable'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Message'),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Call'))
          .onPressed,
      isNull,
    );
  });
}
