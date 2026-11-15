import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/municipal/models/dashboard_data.dart';
import 'package:civic_voice/features/municipal/models/incoming_report.dart';
import 'package:civic_voice/features/municipal/screens/municipal_active_reports_screen.dart';
import 'package:civic_voice/features/municipal/screens/municipal_dashboard_screen.dart';
import 'package:civic_voice/features/municipal/screens/municipal_inbox_screen.dart';
import 'package:civic_voice/features/municipal/screens/municipal_report_progress_screen.dart';
import 'package:civic_voice/features/municipal/screens/municipal_resolved_reports_screen.dart';
import 'package:civic_voice/features/municipal/services/municipal_report_directory.dart';
import 'package:civic_voice/features/municipal/widgets/municipal_detail_header.dart';
import 'package:civic_voice/models/report_status.dart';
import 'package:civic_voice/widgets/glass_card.dart';
import 'package:civic_voice/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

IncomingReportItem fixture(ReportStatus status) => IncomingReportItem.fromApi({
  'id': 'fixture-record',
  'publicReference': 'CV-CARD-FIXTURE',
  'title': 'Street drain near market',
  'description': 'A recorded drainage issue.',
  'location': 'Market Road',
  'category': 'Sanitation',
  'status': status.apiValue,
  'createdAt': '2026-11-01T10:00:00Z',
  'updatedAt': '2026-11-14T10:00:00Z',
  'approvedAt': status == ReportStatus.resolved ? '2026-11-14T10:00:00Z' : null,
  'rejectedAt': status == ReportStatus.rejected ? '2026-11-14T10:00:00Z' : null,
  'assignedTeamId': 'TEAM-FIXTURE',
  'assignedTeamName': 'Fixture crew',
  'progressPercent': 37,
});

MunicipalDashboardData dashboard(IncomingReportItem report) =>
    MunicipalDashboardData(
      officerName: 'Fixture Officer',
      municipalityName: 'Fixture Municipal Assembly',
      stats: const MunicipalDashboardStats(
        newReports: 11,
        underReview: 22,
        assigned: 33,
        resolved: 44,
      ),
      recentReports: [report],
      assignmentSummary: const [],
    );

void main() {
  setUpAll(() async {
    final fonts = FontLoader(AppTypography.fontFamily);
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      fonts.addFont(rootBundle.load('assets/fonts/Inter-$weight.ttf'));
    }
    await fonts.load();
  });
  setUp(() {
    final directory = MunicipalReportDirectory.instance;
    final previous = directory.reports.value;
    final live = directory.hasLiveSnapshot;
    addTearDown(() {
      directory.reports.value = previous;
      directory.hasLiveSnapshot = live;
    });
    directory.hasLiveSnapshot = true;
  });

  Future<void> show(
    WidgetTester tester,
    Widget screen,
    double width,
    double scale,
    bool dark,
    TextDirection direction,
  ) async {
    tester.view.physicalSize = Size(width, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: dark ? AppTheme.dark : AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: Directionality(textDirection: direction, child: child!),
        ),
        home: screen,
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final dark in [false, true]) {
    for (final (width, scale) in [(320.0, 2.0), (390.0, 1.0), (428.0, 2.0)]) {
      testWidgets(
        'Municipal metrics use the shared value-before-label hierarchy $width/$scale dark=$dark',
        (tester) async {
          final report = fixture(ReportStatus.inProgress);
          MunicipalReportDirectory.instance.reports.value = [report];
          await show(
            tester,
            MunicipalDashboardScreen(data: dashboard(report)),
            width,
            scale,
            dark,
            TextDirection.ltr,
          );
          final value = find.text('11');
          final label = find.text('New Reports');
          await tester.ensureVisible(value);
          expect(
            tester.getTopLeft(value).dy,
            lessThan(tester.getTopLeft(label).dy),
          );
          expect(tester.takeException(), isNull);
        },
      );

      for (final direction in TextDirection.values) {
        for (final (name, status) in [
          ('home', ReportStatus.inProgress),
          ('inbox', ReportStatus.underReview),
          ('active', ReportStatus.pendingApproval),
          ('closed', ReportStatus.resolved),
          ('rejected', ReportStatus.rejected),
        ]) {
          testWidgets(
            '$name card retains readable title/status and correct padding navigation $width/$scale $direction dark=$dark',
            (tester) async {
              final report = fixture(status);
              MunicipalReportDirectory.instance.reports.value = [report];
              String? opened;
              final screen = switch (name) {
                'home' => MunicipalDashboardScreen(
                  data: dashboard(report),
                  onReportTap: (r) => opened = r.referenceId,
                ),
                'inbox' => MunicipalInboxScreen(
                  onReportTap: (r) => opened = r.referenceId,
                ),
                'active' => MunicipalActiveReportsScreen(
                  onReportTap: (r) => opened = r.referenceId,
                ),
                _ => MunicipalResolvedReportsScreen(
                  onReportTap: (r) => opened = r.referenceId,
                ),
              };
              await show(tester, screen, width, scale, dark, direction);
              final title = find.text(report.title);
              await tester.scrollUntilVisible(
                title,
                350,
                scrollable: find.byType(Scrollable).first,
              );
              final card = find
                  .ancestor(of: title, matching: find.byType(GlassCard))
                  .first;
              await Scrollable.ensureVisible(
                tester.element(card),
                alignment: 0.5,
              );
              await tester.pumpAndSettle();
              final statusText = find
                  .descendant(of: card, matching: find.text(status.label))
                  .first;
              final paragraph = tester.renderObject<RenderParagraph>(
                statusText,
              );
              expect(
                find.descendant(
                  of: card,
                  matching: find.text(report.referenceId),
                ),
                findsOneWidget,
              );
              if (name == 'active') {
                expect(
                  find.descendant(
                    of: card,
                    matching: find.text('Fixture crew'),
                  ),
                  findsOneWidget,
                );
                expect(
                  find.descendant(of: card, matching: find.text('37%')),
                  findsOneWidget,
                );
                expect(
                  find.descendant(
                    of: card,
                    matching: find.text('View Details'),
                  ),
                  findsOneWidget,
                );
              }
              if (name == 'inbox') {
                expect(
                  find.descendant(
                    of: card,
                    matching: find.text(report.description),
                  ),
                  findsOneWidget,
                );
                expect(
                  find.descendant(
                    of: card,
                    matching: find.text('View Location'),
                  ),
                  findsOneWidget,
                );
              }
              expect(
                paragraph.didExceedMaxLines,
                isFalse,
                reason: 'The actual lifecycle label must stay readable',
              );
              final titleParagraph = tester.renderObject<RenderParagraph>(
                title,
              );
              expect(titleParagraph.didExceedMaxLines, isFalse);
              final pill = find
                  .ancestor(of: statusText, matching: find.byType(Container))
                  .first;
              final pillRect = tester.getRect(pill);
              final cardRect = tester.getRect(card);
              if (direction == TextDirection.ltr) {
                expect(
                  pillRect.right,
                  closeTo(cardRect.right - AppSpacing.md, 1),
                );
              } else {
                expect(
                  pillRect.left,
                  closeTo(cardRect.left + AppSpacing.md, 1),
                );
              }
              expect(
                pillRect.top,
                lessThanOrEqualTo(tester.getRect(title).top + 1),
              );
              await tester.tapAt(
                Offset(cardRect.center.dx, cardRect.bottom - AppSpacing.sm),
              );
              await tester.pumpAndSettle();
              expect(opened, report.referenceId);
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
    for (final status in [
      ReportStatus.inProgress,
      ReportStatus.pendingApproval,
    ]) {
      for (final (width, scale) in [(448.0, 1.0), (320.0, 2.0)]) {
        testWidgets(
          'Progress header shows the complete intrinsic status $status $width/$scale dark=$dark',
          (tester) async {
            final report = fixture(status);
            MunicipalReportDirectory.instance.reports.value = [report];
            var backs = 0;
            await show(
              tester,
              MunicipalReportProgressScreen(
                referenceId: report.referenceId,
                status: status,
                onBack: () => backs++,
              ),
              width,
              scale,
              dark,
              TextDirection.ltr,
            );
            final header = find.byType(MunicipalDetailHeader);
            final badge = find.descendant(
              of: header,
              matching: find.byType(ReportStatusBadge),
            );
            final text = find.descendant(
              of: badge,
              matching: find.text(status.label),
            );
            final paragraph = tester.renderObject<RenderParagraph>(text);
            expect(paragraph.didExceedMaxLines, isFalse);
            expect(
              tester.getSize(badge).width,
              lessThanOrEqualTo(
                paragraph.getMaxIntrinsicWidth(double.infinity) + 21,
              ),
            );
            final firstCard = find.byType(GlassCard).first;
            expect(
              tester.getRect(firstCard).top,
              greaterThanOrEqualTo(tester.getRect(header).bottom),
            );
            await tester.tap(find.byTooltip('Show menu'));
            await tester.pumpAndSettle();
            expect(find.text('Share Summary'), findsOneWidget);
            await tester.tapAt(const Offset(0, 1000));
            await tester.pumpAndSettle();
            await tester.tap(find.byIcon(AppIcons.back));
            expect(backs, 1);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
