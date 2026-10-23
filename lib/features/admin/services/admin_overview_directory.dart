import '../../../services/api_client.dart';
import '../models/admin_overview.dart';
import 'admin_resource.dart';

abstract final class AdminOverviewDirectory {
  static final instance = AdminResource<AdminOverview>(
    fetch: (token) => ApiClient.instance.adminOverview(idToken: token),
    parse: AdminOverview.parse,
  );
}
