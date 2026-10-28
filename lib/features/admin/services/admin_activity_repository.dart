import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../services/api_client.dart';
import '../models/admin_audit.dart';
import '../models/admin_overview.dart' show adminId;
import 'admin_resource.dart';

class AdminActivityRepository {
  AdminActivityRepository({
    String? Function()? owner,
    Future<String?> Function()? credential,
    Future<Map<String, dynamic>> Function(String, Map<String, String>)? list,
    Future<Map<String, dynamic>> Function(String, String)? read,
  }) : _owner = owner ?? adminRequestKey,
       credential =
           credential ??
           (() async => FirebaseAuth.instance.currentUser?.getIdToken()),
       list =
           list ??
           ((token, query) => ApiClient.instance.adminActivityPage(
             idToken: token,
             query: query,
           )),
       read =
           read ??
           ((token, id) =>
               ApiClient.instance.adminActivityDetail(id, idToken: token));

  static final sessionChanges = ValueNotifier<int>(0);
  static void invalidateSession() => sessionChanges.value++;
  final String? Function() _owner;
  final Future<String?> Function() credential;
  final Future<Map<String, dynamic>> Function(String, Map<String, String>) list;
  final Future<Map<String, dynamic>> Function(String, String) read;
  String? owner() {
    final key = _owner();
    return key == null ? null : '$key|${sessionChanges.value}';
  }

  Future<String?> _token() async {
    final value = await credential();
    return value?.trim().isNotEmpty == true ? value : null;
  }

  AdminResource<AuditPage> page(Map<String, String> query) {
    final frozen = Map<String, String>.unmodifiable(query);
    return AdminResource(
      owner: owner,
      credential: _token,
      fetch: (token) => list(token, frozen),
      parse: AuditPage.parse,
    );
  }

  AdminResource<AuditDetail> detail(String id) => AdminResource(
    owner: owner,
    credential: _token,
    fetch: (token) async {
      if (!adminId(id)) return {'missing': true};
      try {
        return await read(token, id);
      } on ApiException catch (error) {
        if (error.statusCode == 404) return {'missing': true};
        rethrow;
      }
    },
    parse: (raw) {
      if (raw['missing'] == true) return const AuditDetail(null);
      final event = AuditEvent.parse(raw['activity']);
      if (event.id != id) throw const FormatException('Unrelated audit event');
      return AuditDetail(event);
    },
  );
}
