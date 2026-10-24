import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/api_client.dart';
import '../models/admin_report_routing.dart';
import '../models/admin_overview.dart' show adminId;
import 'admin_resource.dart';

String? routingOwner() => verifiedSuperAdmin ? adminRequestKey() : null;

/// Only the verified Super Admin owner can dispatch these resources. Injected
/// transports/owners support offline fixtures without creating real records.
class AdminRoutingRepository {
  AdminRoutingRepository({
    String? Function()? owner,
    Future<String?> Function()? credential,
    Future<Map<String, dynamic>> Function(String, String, String?)? list,
    Future<Map<String, dynamic>> Function(String, String)? read,
    Future<Map<String, dynamic>> Function(String, String, Map<String, dynamic>)?
    write,
  }) : owner = owner ?? routingOwner,
       credential =
           credential ??
           (() async => FirebaseAuth.instance.currentUser?.getIdToken()),
       list =
           list ??
           ((token, query, cursor) => ApiClient.instance.adminRoutingQueue(
             idToken: token,
             query: query,
             cursor: cursor,
           )),
       read =
           read ??
           ((token, id) =>
               ApiClient.instance.adminRoutingReport(id, idToken: token)),
       write =
           write ??
           ((token, id, body) => ApiClient.instance.routeAdminReport(
             id,
             idToken: token,
             body: body,
           ));
  final String? Function() owner;
  final Future<String?> Function() credential;
  final Future<Map<String, dynamic>> Function(String, String, String?) list;
  final Future<Map<String, dynamic>> Function(String, String) read;
  final Future<Map<String, dynamic>> Function(
    String,
    String,
    Map<String, dynamic>,
  )
  write;

  AdminResource<RoutingPage> queue(String query, String? cursor) =>
      AdminResource(
        owner: owner,
        credential: credential,
        fetch: (token) => list(token, query, cursor),
        parse: RoutingPage.parse,
      );

  AdminResource<RoutingReport> report(String id) => AdminResource(
    owner: owner,
    credential: credential,
    fetch: (token) async {
      if (!adminId(id)) throw const FormatException('Invalid report ID');
      final raw = await read(token, id);
      final report = RoutingReport.parse(raw['report']);
      if (report.id != id) throw const FormatException('Unrelated report');
      return raw;
    },
    parse: (raw) => RoutingReport.parse(raw['report']),
  );

  Future<RoutingAcknowledgment> save(
    String token,
    RoutingReport previous,
    RoutingChange change,
  ) async {
    final key = owner();
    if (key == null) throw StateError('Super Admin access required');
    final raw = await write(token, previous.id, change.body(previous));
    if (owner() != key) throw StateError('Session changed');
    return RoutingAcknowledgment.parse(raw, previous, change);
  }
}
