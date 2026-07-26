import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/admin/screens/admin_profile_screen.dart';
import 'package:civic_voice/features/authentication/screens/about_screen.dart';
import 'package:civic_voice/features/citizen/screens/citizen_profile_screen.dart';
import 'package:civic_voice/features/citizen/screens/citizen_tab_routes.dart';
import 'package:civic_voice/features/maintenance/screens/profile_screen.dart'
    as maintenance;
import 'package:civic_voice/features/ministry/screens/ministry_profile_screen.dart';
import 'package:civic_voice/features/municipal/screens/municipal_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  PackageInfo loadPackageInfo() => PackageInfo(
    appName: 'CivicVoice',
    packageName: 'com.eraaxis.civic_voice',
    version: '1.2.3',
    buildNumber: '45',
  );

  testWidgets('About screen shows the approved copy and live version', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(428, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AboutScreen(packageInfoLoader: () async => loadPackageInfo()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    expect(
      find.text(
        'A direct line between citizens and the assemblies that serve them.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        "CivicVoice is a civic-issue reporting platform for Ghana's District Municipal, and Metropolitan Assemblies. It gives citizens a fast, transparent way to report public infrastructure problems — potholes, broken streetlights, damaged facilities — and follow them through review, assignment, and resolution.",
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        "The platform is built to stay free of political interference: every report is judged on verifiable evidence, not opinion, and every citizen's voice carries the same weight. Municipal Officers, Maintenance Teams, and Ministry oversight all work from the same transparent record, so accountability isn't just promised — it's visible.",
      ),
      findsOneWidget,
    );
    expect(find.text('Built By'), findsOneWidget);
    expect(find.text('Connect with the team:'), findsOneWidget);
    for (final name in const [
      'Kingsley Anorful',
      'Amoako Kingsben Ofosu',
      'Abdul Aziz Hassan',
      'Abdul Latif Osmani Sani',
      'Francis Kekeli Afun',
    ]) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.text('Acknowledgments'), findsOneWidget);
    expect(find.text('Mark Kofi Amoani Mensah'), findsOneWidget);
    expect(find.text('eraaxis.com'), findsOneWidget);
    expect(find.text('Version 1.2.3 (45)'), findsOneWidget);
    expect(find.textContaining('https://'), findsNothing);
  });

  testWidgets('About links launch their clean public URLs', (tester) async {
    tester.view.physicalSize = const Size(428, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final launched = <Uri>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AboutScreen(
          packageInfoLoader: () async => loadPackageInfo(),
          linkLauncher: (uri) async {
            launched.add(uri);
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kingsley Anorful'));
    await tester.tap(find.text('Mark Kofi Amoani Mensah'));
    await tester.tap(find.text('eraaxis.com'));
    await tester.pump();

    expect(launched, [
      Uri.parse('https://www.linkedin.com/in/kingsley-anorful-9070a3350'),
      Uri.parse('https://www.linkedin.com/in/mark-kofi-amoani-mensah-7a7072b1'),
      Uri.parse('https://eraaxis.com'),
    ]);
    expect(launched.every((uri) => !uri.hasQuery), isTrue);
  });

  testWidgets('About header back arrow invokes its callback', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AboutScreen(
          onBack: () => tapped = true,
          packageInfoLoader: () async => loadPackageInfo(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(AppIcons.back));

    expect(tapped, isTrue);
  });

  group('role profiles expose About CivicVoice', () {
    Future<void> expectAboutAction(
      WidgetTester tester,
      Widget Function(VoidCallback onAbout) buildScreen,
    ) async {
      tester.view.physicalSize = const Size(428, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: buildScreen(() => tapped = true),
        ),
      );
      await tester.pumpAndSettle();

      final action = find.text('About CivicVoice');
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pump();

      expect(find.text('About'), findsOneWidget);
      expect(tapped, isTrue);
    }

    testWidgets('Admin', (tester) async {
      await expectAboutAction(
        tester,
        (onAbout) => AdminProfileScreen(onAbout: onAbout),
      );
    });

    testWidgets('Municipal', (tester) async {
      await expectAboutAction(
        tester,
        (onAbout) => MunicipalProfileScreen(onAbout: onAbout),
      );
    });

    testWidgets('Ministry', (tester) async {
      await expectAboutAction(
        tester,
        (onAbout) => MinistryProfileScreen(onAbout: onAbout),
      );
    });

    testWidgets('Maintenance', (tester) async {
      await expectAboutAction(
        tester,
        (onAbout) => maintenance.ProfileScreen(onAbout: onAbout),
      );
    });

    testWidgets('Citizen', (tester) async {
      await expectAboutAction(
        tester,
        (onAbout) => CitizenProfileScreen(onAbout: onAbout),
      );
    });
  });

  testWidgets('Citizen bottom-tab profile opens About CivicVoice', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(428, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        routes: {
          '/about': (_) =>
              AboutScreen(packageInfoLoader: () async => loadPackageInfo()),
        },
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () =>
                  Navigator.of(context).push(citizenProfileTabRoute(context)),
              child: const Text('Open Profile'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Profile'));
    await tester.pumpAndSettle();

    final aboutAction = find.text('About CivicVoice');
    await tester.ensureVisible(aboutAction);
    await tester.tap(aboutAction);
    await tester.pumpAndSettle();

    expect(find.byType(AboutScreen), findsOneWidget);
    expect(
      find.text(
        'A direct line between citizens and the assemblies that serve them.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
