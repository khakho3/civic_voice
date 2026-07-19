import 'package:flutter/widgets.dart';

/// What kind of event a [NotificationItem] represents — drives filtering
/// (e.g. Municipal's Inbox tab dot only cares about
/// [municipalNewIncomingReport]) without needing a second parallel
/// "seen" tracking mechanism per surface.
enum NotificationType {
  citizenReportSubmitted,
  citizenReportUnderReview,
  citizenReportAssigned,
  citizenReportInProgress,
  citizenReportResolved,
  citizenReportRejected,
  municipalNewIncomingReport,
  maintenanceTaskAssigned,
  ministryReportResolvedNational,
  adminUserCreated,
  adminUserDeactivated,
}

/// A single notification, shared by every module. Never persisted or
/// independently created — always computed fresh from whichever real
/// directory the event actually happened in (see
/// `NotificationDirectory`'s own doc comment), so it can never disagree
/// with the record it's about.
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.category,
    required this.timeLabel,
    required this.icon,
    required this.color,
    required this.read,
    this.referenceId,
  });

  /// Stable, derived from the source record (e.g.
  /// `'municipal-report-REQ-8421'`) — never a random/regenerated id, so
  /// read state keyed on it survives the underlying list being rebuilt.
  final String id;
  final NotificationType type;
  final String title;
  final String message;

  /// Short grouping tag shown as a small pill (e.g. "Report", "New") —
  /// distinct from [title], which names the specific event.
  final String category;
  final String timeLabel;
  final IconData icon;
  final Color color;

  /// Resolved against `NotificationDirectory.readIds` at construction
  /// time — not an independent, settable field.
  final bool read;

  /// The report/task id this notification is about, for a "View" deep
  /// link — null when there's nothing to navigate to.
  final String? referenceId;
}
