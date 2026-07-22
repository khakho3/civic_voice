import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/citizen/models/report_draft.dart';
import 'package:civic_voice/features/citizen/screens/create_report_screen.dart';
import 'package:civic_voice/models/region.dart';
import 'package:civic_voice/services/app_cache_service.dart';
import 'package:civic_voice/services/idle_session_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await AppCacheService.instance.initialize();
  });

  test('persists onboarding completion on the device', () async {
    expect(AppCacheService.instance.onboardingComplete, isFalse);

    await AppCacheService.instance.markOnboardingComplete();
    await AppCacheService.instance.initialize();

    expect(AppCacheService.instance.onboardingComplete, isTrue);
  });

  test('persists the keep-signed-in preference on the device', () async {
    expect(AppCacheService.instance.keepSignedIn, isFalse);

    await AppCacheService.instance.setKeepSignedIn(true);
    await AppCacheService.instance.initialize();
    expect(AppCacheService.instance.keepSignedIn, isTrue);

    await AppCacheService.instance.setKeepSignedIn(false);
    expect(AppCacheService.instance.keepSignedIn, isFalse);
  });

  test(
    'persists nearby-confirmation preference with a default of on',
    () async {
      expect(AppCacheService.instance.nearbySecondingEnabled, isTrue);

      await AppCacheService.instance.setNearbySecondingEnabled(false);
      await AppCacheService.instance.initialize();
      expect(AppCacheService.instance.nearbySecondingEnabled, isFalse);

      await AppCacheService.instance.setNearbySecondingEnabled(true);
      expect(AppCacheService.instance.nearbySecondingEnabled, isTrue);
    },
  );

  test('persists report ids already seen for nearby confirmation', () async {
    expect(AppCacheService.instance.secondingSeenIds, isEmpty);

    await AppCacheService.instance.markSecondingSeen('report-b');
    await AppCacheService.instance.markSecondingSeen('report-a');
    await AppCacheService.instance.markSecondingSeen('report-a');
    await AppCacheService.instance.initialize();

    expect(AppCacheService.instance.secondingSeenIds, {'report-a', 'report-b'});
  });

  testWidgets('keep signed in prevents the idle timer from expiring', (
    tester,
  ) async {
    var expired = false;
    IdleSessionTimer.instance.onExpire = () => expired = true;
    addTearDown(() {
      IdleSessionTimer.instance.onExpire = null;
      IdleSessionTimer.instance.cancel();
    });

    await AppCacheService.instance.setKeepSignedIn(true);
    IdleSessionTimer.instance.registerActivity();
    await tester.pump(const Duration(hours: 1));

    expect(expired, isFalse);
  });

  test('restores an in-progress report draft after reinitialization', () async {
    const draft = ReportDraft(
      title: 'Broken drain',
      description: 'Flooding the roadside',
      category: 'Sanitation',
      location: 'Osu, Accra',
      community: 'Osu',
      latitude: 5.556,
      longitude: -0.182,
      region: Region.greaterAccra,
      assembly: 'Accra',
    );

    await AppCacheService.instance.saveReportDraft(draft);
    await AppCacheService.instance.initialize();

    final restored = AppCacheService.instance.reportDraft;
    expect(restored?.title, 'Broken drain');
    expect(restored?.description, 'Flooding the roadside');
    expect(restored?.latitude, 5.556);
    expect(restored?.region, Region.greaterAccra);
    expect(restored?.assembly, 'Accra');
  });

  test(
    'report draft preserves photo-source order and defaults legacy entries',
    () {
      final current = ReportDraft.fromMap({
        'title': 'Drain',
        'description': '',
        'category': 'Sanitation',
        'location': 'Accra',
        'community': 'Accra',
        'photoPaths': ['camera.jpg', 'gallery.jpg'],
        'photoIsFromCamera': [true, false],
      });
      final legacy = ReportDraft.fromMap({
        'photoPaths': ['legacy-a.jpg', 'legacy-b.jpg'],
      });

      expect(current.photoIsFromCamera, [true, false]);
      expect(current.toMap()['photoIsFromCamera'], [true, false]);
      expect(legacy.photoIsFromCamera, [false, false]);
    },
  );

  test('clears a submitted report draft', () async {
    await AppCacheService.instance.saveReportDraft(
      const ReportDraft(
        title: 'Pothole',
        description: '',
        category: 'Roads',
        location: 'Accra',
        community: 'Accra',
      ),
    );

    await AppCacheService.instance.clearReportDraft();
    await AppCacheService.instance.initialize();

    expect(AppCacheService.instance.reportDraft, isNull);
  });

  testWidgets('create report restores the cached form after navigation', (
    tester,
  ) async {
    await AppCacheService.instance.saveReportDraft(
      const ReportDraft(
        title: 'Broken traffic light',
        description: 'The junction is unsafe at night.',
        category: 'Roads & Transport',
        location: 'Independence Avenue, Accra',
        community: 'Accra',
        latitude: 5.56,
        longitude: -0.2,
        region: Region.greaterAccra,
        assembly: 'Accra',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const CreateReportScreen()),
    );
    await tester.pump();

    final values = tester
        .widgetList<TextField>(find.byType(TextField))
        .map((field) => field.controller?.text)
        .toList();
    expect(values, contains('Broken traffic light'));
    expect(values, contains('The junction is unsafe at night.'));
    expect(find.text('Independence Avenue, Accra'), findsWidgets);
  });
}
