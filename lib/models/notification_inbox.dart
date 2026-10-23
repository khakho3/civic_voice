import 'app_role.dart';

bool inboxId(Object? value) =>
    value is String && RegExp(r'^[A-Za-z0-9_-]{1,100}$').hasMatch(value);
String inboxRole(AppRole role) => switch (role) {
  AppRole.citizen => 'CITIZEN',
  AppRole.systemAdministrator => 'ADMIN',
  AppRole.municipalOfficer => 'MUNICIPAL',
  AppRole.maintenanceTeam => 'MAINTENANCE',
  AppRole.ministrySupervisor => 'MINISTRY',
};

/// Only server-approved, role-specific internal destinations are accepted.
bool inboxDestination(String path, AppRole role) {
  final pattern = switch (role) {
    AppRole.citizen => r'^/app/reports(?:\?report=[A-Za-z0-9_-]{1,100})?$',
    AppRole.systemAdministrator => r'^/app/admin/activity$',
    AppRole.ministrySupervisor => r'^/app/ministry/reports$',
    AppRole.maintenanceTeam =>
      r'^/app/maintenance/(?:tasks|task-details/[A-Za-z0-9_-]{1,100})$',
    AppRole.municipalOfficer =>
      r'^/app/municipal/(?:inbox|(?:report-review|report-progress|resolution-details)\?reportId=[A-Za-z0-9_-]{1,100})$',
  };
  return RegExp(pattern).hasMatch(path);
}

class InboxNotification {
  const InboxNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.read,
    required this.destination,
  });
  final String id, title, body, destination;
  final DateTime createdAt;
  final bool read;
  String? get reportId {
    final uri = Uri.parse(destination);
    return uri.queryParameters['report'] ??
        uri.queryParameters['reportId'] ??
        (uri.path.startsWith('/app/maintenance/task-details/')
            ? uri.pathSegments.last
            : null);
  }

  factory InboxNotification.parse(Object? value, AppRole role) {
    if (value is! Map<String, dynamic> ||
        !inboxId(value['id']) ||
        value['title'] is! String ||
        value['body'] is! String ||
        value['createdAt'] is! String ||
        DateTime.tryParse(value['createdAt']) == null ||
        !(value['readAt'] == null ||
            value['readAt'] is String &&
                DateTime.tryParse(value['readAt']) != null) ||
        value['destination'] is! String ||
        !inboxDestination(value['destination'], role)) {
      throw const FormatException('Unverified notification');
    }
    return InboxNotification(
      id: value['id'],
      title: value['title'],
      body: value['body'],
      createdAt: DateTime.parse(value['createdAt']),
      read: value['readAt'] != null,
      destination: value['destination'],
    );
  }
}

class InboxPage {
  const InboxPage({
    required this.rows,
    required this.unreadCount,
    required this.nextCursor,
  });
  final List<InboxNotification> rows;
  final int unreadCount;
  final String? nextCursor;
  factory InboxPage.parse(Map<String, dynamic> value, AppRole role) {
    if (value['notifications'] is! List ||
        (value['notifications'] as List).length > 50 ||
        value['unreadCount'] is! int ||
        value['unreadCount'] < 0 ||
        !(value['nextCursor'] == null || inboxId(value['nextCursor']))) {
      throw const FormatException('Unverified inbox');
    }
    final rows = (value['notifications'] as List)
        .map((row) => InboxNotification.parse(row, role))
        .toList();
    if (rows.map((row) => row.id).toSet().length != rows.length) {
      throw const FormatException('Duplicate inbox records');
    }
    return InboxPage(
      rows: List.unmodifiable(rows),
      unreadCount: value['unreadCount'],
      nextCursor: value['nextCursor'],
    );
  }
}
