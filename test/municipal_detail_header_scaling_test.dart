import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/municipal/widgets/municipal_detail_header.dart';
import 'package:civic_voice/models/report_status.dart';
import 'package:civic_voice/widgets/status_badge.dart';
import 'package:civic_voice/widgets/kebab_menu_button.dart';

void main() {
  for (final width in [320.0, 390.0, 412.0, 1440.0]) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 1.5, 2.0]) {
        testWidgets(
          'municipal detail header and body share scaled inset $width dark=$dark scale=$scale',
          (tester) async {
            tester.view.physicalSize = Size(width, 700);
            tester.view.devicePixelRatio = 1;
            tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            addTearDown(tester.view.resetPadding);
            for (final title in [
              'Report Review',
              'Verify Report',
              'Assign Team',
              'Report Progress',
              'Resolution Details',
              'Profile',
            ]) {
              await tester.pumpWidget(const SizedBox());
              var backs = 0;
              String? selected;
              final prefix = title == 'Profile' ? 'ID ' : '#';
              const reference = 'CV-LONG-REFERENCE-2026-000001';
              final theme = dark ? AppTheme.dark : AppTheme.light;
              await tester.pumpWidget(
                MaterialApp(
                  theme: theme,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(scale),
                      disableAnimations: true,
                    ),
                    child: child!,
                  ),
                  home: Builder(
                    builder: (context) => Scaffold(
                      body: Stack(
                        children: [
                          Positioned.fill(
                            child: ListView(
                              padding: EdgeInsets.zero,
                              children: [
                                SizedBox(
                                  height: MunicipalDetailHeader.topInset(
                                    context,
                                  ),
                                ),
                                const SizedBox(
                                  key: ValueKey('first-body-card'),
                                  height: 180,
                                  child: Text('First card'),
                                ),
                              ],
                            ),
                          ),
                          Align(
                            alignment: Alignment.topCenter,
                            child: MunicipalDetailHeader(
                              title: title,
                              referenceId: reference,
                              subtitlePrefix: prefix,
                              onBack: () => backs++,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Expanded(
                                    child: ReportStatusBadge(
                                      status: ReportStatus.pendingApproval,
                                    ),
                                  ),
                                  KebabMenuButton<String>(
                                    tooltip: 'Report options',
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(
                                        value: 'share',
                                        child: Text('Share'),
                                      ),
                                    ],
                                    onSelected: (value) => selected = value,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();
              final header = tester.getRect(find.byType(MunicipalDetailHeader));
              expect(
                tester
                    .getRect(find.byKey(const ValueKey('first-body-card')))
                    .top,
                closeTo(header.bottom, 0.01),
              );
              expect(
                tester.getRect(find.text(title)).bottom,
                lessThanOrEqualTo(
                  tester.getRect(find.text('$prefix$reference')).top + 0.01,
                ),
              );
              expect(
                tester.getRect(find.text('$prefix$reference')).bottom,
                lessThanOrEqualTo(header.bottom),
              );
              if (scale == 1) {
                expect(header.height, AppDimensions.headerHeight + 24);
              }
              expect(
                tester.widget<Text>(find.text(title)).style!.fontSize,
                theme.textTheme.titleMedium!.fontSize,
              );
              await tester.tap(find.byIcon(AppIcons.back));
              expect(backs, 1);
              final menu = find.byTooltip('Report options');
              await tester.tap(menu);
              await tester.pumpAndSettle();
              await tester.tap(find.text('Share'));
              await tester.pumpAndSettle();
              expect(selected, 'share');
              expect(tester.takeException(), isNull, reason: title);
            }
            await tester.pumpWidget(const SizedBox());
          },
        );
      }
    }
  }
}
