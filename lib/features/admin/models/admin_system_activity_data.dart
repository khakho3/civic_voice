import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/assembly.dart';
import '../../../models/ghana_assemblies_data.dart';
import '../../../models/region.dart';

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
    this.assembly,
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

  /// Null for platform-wide events (a policy update, a scheduled backup —
  /// nothing tied to any one jurisdiction). Set for events that happened
  /// within a specific assembly's jurisdiction — an account provisioned
  /// there, a citizen registering from there — which is what
  /// [AdminSession.visibleActivity] scopes an assembly Admin's feed down
  /// to: their own [assembly], never the platform-wide events a null
  /// value represents (those stay Super Admin-only, same as the health
  /// stats above the feed).
  final Assembly? assembly;

  bool matchesTimeRange(ActivityTimeRange range) => range.includes(timestamp);
}

/// Live system-health readings at the top of the screen — API reachability,
/// database latency, uptime. Distinct from the audit feed below it: these
/// are infrastructure signals a Super Admin checks at a glance, not
/// counts derived from [ActivityItem]s. Moved here from ADM-001 Admin
/// Dashboard (which dropped its own "API Status" badge entirely) — a
/// national-scope health readout belongs on the system-level screen, not
/// the general overview every admin (including assembly-scoped ones) sees.
class SystemHealthStats {
  const SystemHealthStats({
    required this.apiOnline,
    required this.dbLatencyMs,
    required this.uptimePercent,
  });

  final bool apiOnline;
  final int dbLatencyMs;
  final double uptimePercent;
}

/// Placeholder content, used until a real health-check service is wired up.
SystemHealthStats mockSystemHealthStats() {
  return const SystemHealthStats(
    apiOnline: true,
    dbLatencyMs: 42,
    uptimePercent: 99.98,
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
      assembly: assemblyNamed(Region.ashanti, 'Kumasi'),
    ),
    ActivityItem(
      title: 'Citizen Account Registered',
      description:
          'A new citizen account self-registered from Kumasi, Ashanti '
          'Region.',
      timestamp: now.subtract(const Duration(hours: 5, minutes: 10)),
      severity: ActivitySeverity.info,
      category: ActivityCategory.userModification,
      tag: 'Citizen Registration',
      assembly: assemblyNamed(Region.ashanti, 'Kumasi'),
    ),
    ActivityItem(
      title: 'Citizen Account Registered',
      description:
          'A new citizen account self-registered from Accra, Greater Accra '
          'Region.',
      timestamp: now.subtract(const Duration(hours: 9, minutes: 45)),
      severity: ActivitySeverity.info,
      category: ActivityCategory.userModification,
      tag: 'Citizen Registration',
      assembly: assemblyNamed(Region.greaterAccra, 'Accra'),
    ),
  ];
}
