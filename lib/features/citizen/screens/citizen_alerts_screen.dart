import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/notification_directory.dart';
import '../../../widgets/notification_list_view.dart';
import '../services/report_crud_service.dart';
import '../widgets/civic_app_chrome.dart';
import 'citizen_profile_screen.dart';
import 'citizen_reports_screen.dart';
import 'create_report_screen.dart';
import 'report_tracking_screen.dart';

class CitizenAlertsScreen extends StatelessWidget {
  const CitizenAlertsScreen({super.key});

  static const String routeName = '/citizen/alerts';

  void _openDashboard(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _openReports(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      CitizenReportsScreen.routeName,
      (route) => route.isFirst,
    );
  }

  void _openCreateReport(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      CreateReportScreen.routeName,
      (route) => route.isFirst,
    );
  }

  void _openProfile(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      CitizenProfileScreen.routeName,
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      // See create_report_screen.dart's build() for why this is false and
      // paired with the keyboardVisible-guarded nav below.
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                ReportCrudService.instance.reports,
                NotificationDirectory.instance.readIds,
                NotificationDirectory.instance.dismissedIds,
              ]),
              builder: (context, _) {
                final notifications = NotificationDirectory.instance
                    .forCitizen();
                final chromeInset = civicContentPadding(context);

                return NotificationListView(
                  notifications: notifications,
                  emptyTitle: 'No notifications yet',
                  emptyMessage:
                      'Report updates will appear here after you submit a '
                      'report.',
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    chromeInset.top + AppSpacing.lg,
                    AppSpacing.md,
                    chromeInset.bottom + AppSpacing.lg,
                  ),
                  onTap: (notification) {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ReportTrackingScreen(
                          reportId: notification.referenceId ?? '',
                        ),
                      ),
                    );
                  },
                  onClearAll: () => NotificationDirectory.instance.clearAll(
                    notifications.map((n) => n.id),
                  ),
                  onRefresh: ReportCrudService.instance.refresh,
                  topOffset: chromeInset.top,
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            // No onBack — this is a bottom-nav destination (index 3), not a
            // drill-down, matching every other primary tab in the module.
            child: const CivicTopBar(
              title: 'Notifications',
              showNotifications: false,
            ),
          ),
          if (!keyboardVisible)
            Align(
              alignment: Alignment.bottomCenter,
              child: CivicBottomNav(
                selectedIndex: 3,
                onDestinationSelected: (index) {
                  if (index == 0) {
                    _openDashboard(context);
                  } else if (index == 1) {
                    _openReports(context);
                  } else if (index == 2) {
                    _openCreateReport(context);
                  } else if (index == 4) {
                    _openProfile(context);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}
