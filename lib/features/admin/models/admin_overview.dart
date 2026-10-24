import 'admin_system_activity_data.dart';

bool adminId(Object? value) =>
    value is String && RegExp(r'^[A-Za-z0-9_-]{1,100}$').hasMatch(value);
bool adminCount(Object? value) => value is int && value >= 0;
DateTime adminInstant(Object? value) {
  final time = value is String ? DateTime.tryParse(value) : null;
  if (time == null) throw const FormatException('Invalid server timestamp');
  return time;
}

class AdminOverview {
  const AdminOverview({
    required this.totalUsers,
    required this.activeRoles,
    required this.auditEvents24h,
    required this.openAlerts,
    required this.collectionEnabled,
    required this.checkedAt,
    required this.recent,
  });
  final int totalUsers, activeRoles, auditEvents24h, openAlerts;
  final bool collectionEnabled;
  final DateTime checkedAt;
  final List<ActivityItem> recent;
  factory AdminOverview.parse(Map<String, dynamic> raw) {
    if (![
          'totalUsers',
          'activeRoles',
          'auditEvents24h',
          'alertEvents',
          'openAlertEvents',
          'acknowledgedAlertEvents',
        ].every((key) => adminCount(raw[key])) ||
        raw['collectionEnabled'] is! bool ||
        raw['recentActivity'] is! List ||
        (raw['recentActivity'] as List).length > 3 ||
        raw['window'] is! Map ||
        raw['activeRoles'] > 5 ||
        raw['activeRoles'] > raw['totalUsers'] ||
        raw['openAlertEvents'] > raw['alertEvents'] ||
        raw['acknowledgedAlertEvents'] > raw['openAlertEvents']) {
      throw const FormatException('Unverified dashboard');
    }
    final checkedAt = adminInstant(raw['checkedAt']),
        from = adminInstant(raw['window']['from']),
        to = adminInstant(raw['window']['to']);
    if (to.difference(from) != const Duration(hours: 24) || to != checkedAt) {
      throw const FormatException('Invalid dashboard window');
    }
    final recent = (raw['recentActivity'] as List).map((item) {
      if (item is! Map<String, dynamic> ||
          !adminId(item['id']) ||
          item['title'] is! String ||
          ![
            'INFO',
            'STANDARD',
            'ALERT',
            'CRITICAL',
          ].contains(item['severity'])) {
        throw const FormatException('Invalid activity preview');
      }
      return ActivityItem.fromApi(item);
    }).toList();
    return AdminOverview(
      totalUsers: raw['totalUsers'],
      activeRoles: raw['activeRoles'],
      auditEvents24h: raw['auditEvents24h'],
      openAlerts: raw['openAlertEvents'],
      collectionEnabled: raw['collectionEnabled'],
      checkedAt: checkedAt,
      recent: List.unmodifiable(recent),
    );
  }
}

class AdminAlert {
  const AdminAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.createdAt,
    required this.state,
    required this.revision,
    this.region,
    this.assembly,
    this.actorName,
    this.actorPublicId,
    this.action,
    this.outcome,
  });
  final String? region, assembly, actorName, actorPublicId, action, outcome;
  final String id, title, description, severity, state;
  final DateTime createdAt;
  final int revision;
  factory AdminAlert.parse(Object? value) {
    if (value is! Map<String, dynamic> ||
        !adminId(value['id']) ||
        value['title'] is! String ||
        value['description'] is! String ||
        !['ALERT', 'CRITICAL'].contains(value['severity']) ||
        value['review'] is! Map) {
      throw const FormatException('Unverified alert');
    }
    for (final key in [
      'region',
      'assembly',
      'actorName',
      'actorPublicId',
      'action',
      'outcome',
    ]) {
      if (value[key] != null && value[key] is! String) {
        throw const FormatException('Invalid event field');
      }
    }
    final review = value['review'];
    if (!adminCount(review['revision']) ||
        !['OPEN', 'ACKNOWLEDGED', 'RESOLVED'].contains(review['state']) ||
        (review['revision'] == 0 &&
            (review['state'] != 'OPEN' || review['updatedAt'] != null))) {
      throw const FormatException('Unverified alert review');
    }
    if (review['revision'] > 0) adminInstant(review['updatedAt']);
    return AdminAlert(
      id: value['id'],
      title: value['title'],
      description: value['description'],
      severity: value['severity'],
      createdAt: adminInstant(value['createdAt']),
      state: review['state'],
      revision: review['revision'],
      region: value['region'],
      assembly: value['assembly'],
      actorName: value['actorName'],
      actorPublicId: value['actorPublicId'],
      action: value['action'],
      outcome: value['outcome'],
    );
  }
}

class AdminAlertPage {
  const AdminAlertPage(this.alerts, this.total, this.nextCursor);
  final List<AdminAlert> alerts;
  final int total;
  final String? nextCursor;
  factory AdminAlertPage.parse(Map<String, dynamic> raw) {
    if (raw['alerts'] is! List ||
        (raw['alerts'] as List).length > 50 ||
        !adminCount(raw['total']) ||
        !(raw['nextCursor'] == null ||
            raw['nextCursor'] is String &&
                RegExp(
                  r'^[A-Za-z0-9_-]{1,512}$',
                ).hasMatch(raw['nextCursor']))) {
      throw const FormatException('Unverified alert page');
    }
    final alerts = (raw['alerts'] as List).map(AdminAlert.parse).toList();
    if (raw['total'] < alerts.length ||
        alerts.map((e) => e.id).toSet().length != alerts.length) {
      throw const FormatException('Invalid alert count');
    }
    return AdminAlertPage(
      List.unmodifiable(alerts),
      raw['total'],
      raw['nextCursor'],
    );
  }
}

class AdminAlertDetail {
  const AdminAlertDetail(this.alert, this.actions, this.actionCount);
  final AdminAlert alert;
  final List<Map<String, dynamic>> actions;
  final int actionCount;
  factory AdminAlertDetail.parse(Map<String, dynamic> raw) {
    final alert = AdminAlert.parse(raw['alert']);
    if (raw['actions'] is! List ||
        (raw['actions'] as List).length > 20 ||
        !adminCount(raw['actionCount']) ||
        raw['actionCount'] < (raw['actions'] as List).length) {
      throw const FormatException('Unverified review history');
    }
    final actions = (raw['actions'] as List).map((item) {
      if (item is! Map<String, dynamic> ||
          !adminId(item['id']) ||
          !['OPEN', 'ACKNOWLEDGED', 'RESOLVED'].contains(item['state']) ||
          !adminCount(item['revision']) ||
          item['revision'] < 1 ||
          ![
            'note',
            'actorName',
            'actorPublicId',
          ].every((key) => item[key] is String)) {
        throw const FormatException('Invalid review history');
      }
      adminInstant(item['createdAt']);
      return Map<String, dynamic>.unmodifiable(item);
    }).toList();
    return AdminAlertDetail(
      alert,
      List.unmodifiable(actions),
      raw['actionCount'],
    );
  }
}
