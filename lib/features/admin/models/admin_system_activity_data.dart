import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Filter chips above the activity feed — [all]'s the default, the other
/// two split by [ActivityItem.category].
enum ActivityFilter {
  all('All Events'),
  systemUpdates('System Updates'),
  userModifications('User Modifications');

  const ActivityFilter(this.label);

  final String label;

  bool matches(ActivityItem item) => switch (this) {
    ActivityFilter.all => true,
    ActivityFilter.systemUpdates =>
      item.category == ActivityCategory.systemUpdate,
    ActivityFilter.userModifications =>
      item.category == ActivityCategory.userModification,
  };
}

/// Which [ActivityFilter] chip (other than [ActivityFilter.all]) an event
/// belongs to — distinct from [ActivitySeverity] (how urgent it is) and the
/// free-text [ActivityItem.tag] (a more specific descriptive label, e.g.
/// "Security"/"Infrastructure").
enum ActivityCategory { systemUpdate, userModification }

/// The time window the "Last 24 Hours" dropdown filters by.
enum ActivityTimeRange {
  last24Hours('Last 24 Hours', Duration(hours: 24)),
  last7Days('Last 7 Days', Duration(days: 7)),
  last30Days('Last 30 Days', Duration(days: 30)),
  allTime('All Time', null);

  const ActivityTimeRange(this.label, this.window);

  final String label;

  /// Null for [allTime] — nothing is excluded by age.
  final Duration? window;

  bool includes(DateTime timestamp) {
    final window = this.window;
    if (window == null) return true;
    return DateTime.now().difference(timestamp) <= window;
  }
}

/// How urgent an event is — also drives its icon and tint, the same
/// "one enum, several derived visuals" shape as [AdminUserStatus].
enum ActivitySeverity {
  critical('Critical', AppColors.error, AppIcons.shieldAlert),
  standard('Standard', AppColors.statusResolved, AppIcons.filter),
  info('Info', AppColors.primary, AppIcons.cloud),
  alert('Alert', AppColors.warning, AppIcons.password);

  const ActivitySeverity(this.label, this.color, this.icon);

  final String label;
  final Color color;
  final IconData icon;
}

/// One row in the "Recent Activity" audit feed.
class ActivityItem {
  const ActivityItem({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.severity,
    required this.category,
    required this.tag,
  });

  final String title;
  final String description;
  final DateTime timestamp;
  final ActivitySeverity severity;
  final ActivityCategory category;

  /// A more specific descriptive label than [category] — e.g. "Security",
  /// "Infrastructure", "Maintenance", "Access Management". Not filtered on
  /// (only [category] drives the [ActivityFilter] chips); purely
  /// informational, matching the approved frame's second tag pill.
  final String tag;

  bool matchesTimeRange(ActivityTimeRange range) => range.includes(timestamp);
}

/// The four summary stat cards at the top of the screen.
class SystemActivityStats {
  const SystemActivityStats({
    required this.totalEvents,
    required this.totalEventsChangePercent,
    required this.loginEvents,
    required this.loginEventsChangePercent,
    required this.adminActions,
    required this.adminActionsChangePercent,
    required this.securityAlerts,
    required this.securityAlertsBadge,
  });

  final int totalEvents;
  final num totalEventsChangePercent;
  final int loginEvents;
  final num loginEventsChangePercent;
  final int adminActions;

  /// Negative — Admin Actions is the one stat trending down in the
  /// approved frame.
  final num adminActionsChangePercent;
  final int securityAlerts;

  /// A period label ("Today"), not a percentage delta — the approved
  /// frame renders Security Alerts differently from the other three stats.
  final String securityAlertsBadge;
}

/// Placeholder content matching the approved ADM-006 design, used until a
/// real audit-log service is wired up.
SystemActivityStats mockSystemActivityStats() {
  return const SystemActivityStats(
    totalEvents: 2400,
    totalEventsChangePercent: 12,
    loginEvents: 1200,
    loginEventsChangePercent: 5,
    adminActions: 850,
    adminActionsChangePercent: -2,
    securityAlerts: 42,
    securityAlertsBadge: 'Today',
  );
}

List<ActivityItem> mockActivityItems() {
  final now = DateTime.now();
  return [
    ActivityItem(
      title: 'Unauthorized Login Attempt',
      description:
          'Multiple failed authentication rounds were blocked by system '
          'policy.',
      timestamp: now.subtract(const Duration(hours: 2)),
      severity: ActivitySeverity.critical,
      category: ActivityCategory.userModification,
      tag: 'Security',
    ),
    ActivityItem(
      title: 'System Policy Update',
      description:
          'Approved access-control policy changes were published to the '
          'production environment.',
      timestamp: now.subtract(const Duration(hours: 3, minutes: 25)),
      severity: ActivitySeverity.standard,
      category: ActivityCategory.systemUpdate,
      tag: 'Infrastructure',
    ),
    ActivityItem(
      title: 'Automated Backup Complete',
      description:
          'Scheduled platform snapshot completed successfully. Audit '
          'record retained.',
      timestamp: now.subtract(const Duration(hours: 6, minutes: 40)),
      severity: ActivitySeverity.info,
      category: ActivityCategory.systemUpdate,
      tag: 'Maintenance',
    ),
    ActivityItem(
      title: 'Administrative Credential Issued',
      description:
          'An administrator credential was issued following the approved '
          'governance workflow.',
      timestamp: now.subtract(const Duration(days: 1, hours: 4)),
      severity: ActivitySeverity.alert,
      category: ActivityCategory.userModification,
      tag: 'Access Management',
    ),
  ];
}
