import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/citizen/models/civic_report.dart';
import 'package:civic_voice/features/citizen/models/dashboard_view_state.dart';
import 'package:civic_voice/features/citizen/screens/citizen_dashboard_screen.dart';
import 'package:civic_voice/features/citizen/screens/citizen_profile_screen.dart';
import 'package:civic_voice/features/citizen/services/profile_crud_service.dart';
import 'package:civic_voice/features/citizen/services/report_crud_service.dart';
import 'package:civic_voice/services/api_client.dart';
import 'package:civic_voice/services/app_cache_service.dart';
import 'package:civic_voice/widgets/trust_standing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'trust_standing_data_test.dart' show standingPayload, standingUser;

const limitCopy =
    "While your standing is this low, confirming other people's nearby reports is paused. Submitting reports that are accepted will restore it.";

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppCacheService.instance.initialize(accountId: 'standing-ui');
    await AppCacheService.instance.setNearbySecondingEnabled(false);
    ProfileCrudService.instance.clearSession();
    final previous = ReportCrudService.instance.reports.value;
    ReportCrudService.instance.reports.value = [];
    addTearDown(() {
      ProfileCrudService.instance.clearSession();
      ReportCrudService.instance.reports.value = previous;
    });
  });
  for (final dark in [false, true]) {
    for (final populated in [false, true]) {
      testWidgets(
        'live standing goes from Home to Profile dark=$dark reports=$populated',
        (tester) async {
          tester.view.physicalSize = const Size(412, 1800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final profile = ProfileCrudService.instance;
          profile.loadSignedInUser(
            SyncedUser.fromJson(
              standingUser(rating: standingPayload(stars: 3.7, low: true)),
            ),
          );
          if (populated) {
            ReportCrudService.instance.reports.value = const [
              CivicReport(
                id: 'fixture-report',
                title: 'Fixture report',
                location: 'Test street',
                timeLabel: 'Today',
                status: ReportStatus.submitted,
              ),
            ];
          }
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              home: CitizenDashboardScreen(
                initialState: populated
                    ? DashboardViewState.content
                    : DashboardViewState.empty,
              ),
            ),
          );
          await tester.pumpAndSettle();
          final compact = find.byType(TrustStanding);
          expect(compact, findsOneWidget);
          expect(
            tester.widget<FractionalStars>(find.byType(FractionalStars)).value,
            3.7,
          );
          expect(
            find.text('7 more resolved reports to reach 4.5 stars.'),
            findsOneWidget,
          );
          expect(find.text(limitCopy), findsNothing);
          final semantics = tester.ensureSemantics();
          await tester.pump();
          expect(
            tester.getSemantics(compact),
            matchesSemantics(
              label:
                  'Your reporting standing: 3.7 out of 5 stars — Server standing. View details.',
              isButton: true,
              hasTapAction: true,
            ),
          );
          semantics.dispose();
          await Scrollable.ensureVisible(
            tester.element(compact),
            alignment: 0.5,
          );
          await tester.pumpAndSettle();
          await tester.tap(compact);
          await tester.pumpAndSettle();
          expect(find.byType(CitizenProfileScreen), findsOneWidget);
          expect(
            tester
                .widget<TrustStanding>(find.byType(TrustStanding).last)
                .variant,
            TrustStandingVariant.detailed,
          );
          expect(find.text('Your reporting standing'), findsOneWidget);
          expect(find.text(limitCopy), findsOneWidget);
          profile.loadSignedInUser(
            SyncedUser.fromJson(
              standingUser(rating: standingPayload(stars: 5)),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.text('You have reached the highest standing.'),
            findsOneWidget,
          );
          expect(find.text(limitCopy), findsNothing);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(
            tester.widget<FractionalStars>(find.byType(FractionalStars)).value,
            5,
          );
          final missing = standingUser()..remove('trustRating');
          profile.loadSignedInUser(SyncedUser.fromJson(missing));
          await tester.pumpAndSettle();
          expect(find.byType(TrustStanding), findsNothing);
          expect(
            find.text('You have reached the highest standing.'),
            findsNothing,
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
    testWidgets(
      'guest and malformed standing stay hidden on Home and Profile dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(412, 1800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        for (final guest in [true, false]) {
          final raw = standingUser(guest: guest);
          if (!guest) raw['trustRating'] = {'stars': 5};
          ProfileCrudService.instance.loadSignedInUser(
            SyncedUser.fromJson(raw),
          );
          for (final screen in <Widget>[
            const CitizenDashboardScreen(),
            const CitizenProfileScreen(),
          ]) {
            await tester.pumpWidget(const SizedBox());
            await tester.pumpWidget(
              MaterialApp(
                theme: dark ? AppTheme.dark : AppTheme.light,
                home: screen,
              ),
            );
            await tester.pumpAndSettle();
            expect(find.byType(TrustStanding), findsNothing);
            expect(find.text('Your reporting standing'), findsNothing);
          }
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
