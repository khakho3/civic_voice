import 'admin_overview.dart' show adminId, adminCount;
import 'admin_system_activity_data.dart';

const auditCategories = <String, String>{
  '': 'All Events',
  'SYSTEM_UPDATE': 'System Updates',
  'USER_MODIFICATION': 'User Modifications',
  'SECURITY': 'Security',
  'REPORT_WORKFLOW': 'Report Workflow',
};

String auditTimestamp(DateTime value) {
  final utc = value.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${utc.year}-${two(utc.month)}-${two(utc.day)} '
      '${two(utc.hour)}:${two(utc.minute)}:${two(utc.second)} UTC';
}

DateTime _instant(Object? value) {
  final time =
      value is String &&
          RegExp(
            r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,3})?(Z|[+-]\d{2}:\d{2})$',
          ).hasMatch(value)
      ? DateTime.tryParse(value)
      : null;
  if (time == null) throw const FormatException('Invalid audit timestamp');
  final text = value as String;
  final year = int.parse(text.substring(0, 4));
  final month = int.parse(text.substring(5, 7));
  final day = int.parse(text.substring(8, 10));
  final date = DateTime.utc(year, month, day);
  if (date.year != year ||
      date.month != month ||
      date.day != day ||
      int.parse(text.substring(11, 13)) > 23 ||
      int.parse(text.substring(14, 16)) > 59 ||
      int.parse(text.substring(17, 19)) > 59) {
    throw const FormatException('Invalid audit timestamp');
  }
  return time.toUtc();
}

String? _text(Object? value, {int max = 10000}) {
  if (value == null) return null;
  if (value is! String || value.length > max) {
    throw const FormatException('Invalid audit field');
  }
  return value;
}

/// Mirrors the API's event-specific scalar projection. Unknown producers have
/// no client context until their public contract is explicitly supported.
Map<String, Object?> safeAuditContext(String action, Object? source) {
  if (source is! Map) return const {};
  var fields = <String, String>{};
  if (RegExp(r'^USER_(CREATED|UPDATED|DELETED)$').hasMatch(action)) {
    fields = {'role': 'string', 'active': 'boolean'};
  }
  if (action == 'USER_UPDATED') {
    fields.addAll({
      'previousObservedRole': 'string',
      'previousObservedActive': 'boolean',
      'previousObservedAdminTier': 'string',
      'adminTier': 'string',
      'previousObservedRegion': 'string',
      'region': 'string',
      'previousObservedAssembly': 'string',
      'assembly': 'string',
      'previousObservedTeamId': 'string',
      'teamId': 'string',
    });
  }
  if (RegExp(r'^TEAM_(CREATED|UPDATED)$').hasMatch(action)) {
    fields = {'members': 'number'};
  }
  if (action == 'TEAM_UPDATED') {
    fields.addAll({
      'previousObservedMembers': 'number',
      'previousObservedLeadId': 'string',
      'leadId': 'string',
      'previousObservedRegion': 'string',
      'region': 'string',
      'previousObservedAssembly': 'string',
      'assembly': 'string',
    });
  }
  if (action == 'SETTINGS_UPDATED') {
    fields = {
      'sessionTimeout': 'string',
      'auditLogging': 'boolean',
      'previousAuditLogging': 'boolean',
      'allowNewAccountCreation': 'boolean',
    };
  }
  if (action == 'REPORT_SUBMITTED') {
    fields = {
      'category': 'string',
      'routingSource': 'string',
      'routingState': 'string',
    };
  } else if (action.startsWith('REPORT_')) {
    fields = {
      'status': 'string',
      'assignedTeamName': 'string',
      'progressPercent': 'number',
      'previousObservedStatus': 'string',
      'previousObservedProgressPercent': 'number',
      'previousObservedTeamId': 'string',
      'teamId': 'string',
      'seconderCount': 'number',
    };
  }
  if (action == 'REPORT_VERIFICATION_SAVED') {
    fields = {
      'verificationRevision': 'number',
      'requiredChecksComplete': 'boolean',
    };
  }
  if (action == 'REPORT_LOCALITY_RESOLVED') {
    fields = {
      'previousRegion': 'string',
      'previousAssembly': 'string',
      'region': 'string',
      'assembly': 'string',
      'reason': 'string',
    };
  }
  if (action == 'ALERT_REVIEW_UPDATED') {
    fields = {'previousState': 'string', 'state': 'string', 'note': 'string'};
  }
  if (action == 'PASSWORD_ACTIVITY_SPIKE') {
    fields = {
      'count': 'number',
      'windowMinutes': 'number',
      'threshold': 'number',
    };
  }
  if (['AUTH_PASSWORD_REJECTED', 'AUTH_PASSWORD_VERIFIED'].contains(action)) {
    fields = {'source': 'string'};
  }
  if (action == 'AUTH_FAILURE_SPIKE') {
    fields = {
      'source': 'string',
      'count': 'number',
      'windowMinutes': 'number',
      'threshold': 'number',
      'from': 'string',
      'to': 'string',
      'truncated': 'boolean',
    };
  }
  if (['API_HEALTH_DEGRADED', 'API_HEALTH_RECOVERED'].contains(action)) {
    fields = {
      'source': 'string',
      'incidentId': 'string',
      'observedAt': 'string',
      'failedSince': 'string',
      'threshold': 'number',
    };
  }
  if (action == 'PROFILE_UPDATED') {
    fields = {'previousObservedName': 'string', 'name': 'string'};
  }
  if (RegExp(
    r'^(PASSWORD_RESET|PASSWORD_CHANGE|PROFILE_UPDATE|ADMIN_USER_UPDATE|ADMIN_USER_DELETE|TEAM_UPDATE)_FAILED$',
  ).hasMatch(action)) {
    fields = {'operation': 'string', 'reason': 'string', 'source': 'string'};
  }
  if (action == 'MAINTENANCE_TEAM_UNREADY') fields = {'reportId': 'string'};
  if ([
    'AUTH_LOGIN_SUCCESS',
    'AUTH_SESSION_OBSERVED',
    'CLIENT_SIGN_OUT_REPORTED',
  ].contains(action)) {
    fields = {
      'authenticatedAt': 'string',
      'provider': 'string',
      'source': 'string',
    };
  }
  return Map.unmodifiable({
    for (final entry in fields.entries)
      if (source.containsKey(entry.key) &&
          (source[entry.key] == null ||
              entry.value == 'string' &&
                  source[entry.key] is String &&
                  (source[entry.key] as String).length <= 200 ||
              entry.value == 'boolean' && source[entry.key] is bool ||
              entry.value == 'number' &&
                  source[entry.key] is num &&
                  (source[entry.key] as num).isFinite))
        entry.key: source[entry.key] as Object?,
  });
}

class AuditEvent {
  AuditEvent._(
    this.item,
    this.action,
    this.outcome,
    this.category,
    this.fields,
    this.context,
  );
  final ActivityItem item;
  final String action, outcome, category;
  final Map<String, String?> fields;
  final Map<String, Object?> context;
  String get id => item.id!;
  factory AuditEvent.parse(Object? value) {
    if (value is! Map<String, dynamic> ||
        value['schemaVersion'] != 1 ||
        !adminId(value['id']) ||
        !adminId(value['action']) ||
        !auditCategories.containsKey(value['category']) ||
        value['category'] == '' ||
        ![
          'INFO',
          'STANDARD',
          'ALERT',
          'CRITICAL',
        ].contains(value['severity']) ||
        _text(value['title'])?.trim().isNotEmpty != true) {
      throw const FormatException('Unverified audit event');
    }
    final time = _instant(value['createdAt']);
    final outcome = value['outcome'] ?? 'UNKNOWN';
    if (!['SUCCESS', 'FAILED', 'DENIED', 'UNKNOWN'].contains(outcome)) {
      throw const FormatException('Invalid audit outcome');
    }
    final fields = <String, String?>{
      for (final key in [
        'actorName',
        'actorId',
        'actorPublicId',
        'actorRole',
        'region',
        'assembly',
        'subjectType',
        'subjectId',
      ])
        key: _text(value[key]),
    };
    _text(value['description']);
    _text(value['tag']);
    return AuditEvent._(
      ActivityItem.fromApi({...value, 'createdAt': time.toIso8601String()}),
      value['action'] as String,
      outcome as String,
      value['category'] as String,
      Map.unmodifiable(fields),
      safeAuditContext(value['action'] as String, value['metadata']),
    );
  }
}

class AuditPage {
  const AuditPage(
    this.events,
    this.total,
    this.alertCount,
    this.collectionEnabled,
    this.nextCursor,
  );
  final List<AuditEvent> events;
  final int total, alertCount;
  final bool collectionEnabled;
  final String? nextCursor;
  factory AuditPage.parse(Map<String, dynamic> raw) {
    final info = raw['pageInfo'];
    if (raw['activity'] is! List ||
        !adminCount(raw['total']) ||
        !adminCount(raw['alertCount']) ||
        raw['alertCount'] > raw['total'] ||
        raw['collectionEnabled'] is! bool ||
        info is! Map ||
        info['limit'] != 50 ||
        info['hasMore'] is! bool) {
      throw const FormatException('Unverified audit page');
    }
    final events = (raw['activity'] as List).map(AuditEvent.parse).toList();
    final cursor = info['nextCursor'];
    if (events.length > 50 ||
        events.length > raw['total'] ||
        events.map((e) => e.id).toSet().length != events.length ||
        (info['hasMore'] == true &&
            (events.isEmpty ||
                cursor is! String ||
                !RegExp(r'^[A-Za-z0-9_-]{1,512}$').hasMatch(cursor))) ||
        (info['hasMore'] == false && cursor != null)) {
      throw const FormatException('Invalid audit pagination');
    }
    return AuditPage(
      List.unmodifiable(events),
      raw['total'] as int,
      raw['alertCount'] as int,
      raw['collectionEnabled'] as bool,
      cursor as String?,
    );
  }
}

class AuditDetail {
  const AuditDetail(this.event);
  final AuditEvent? event;
}
