import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/report_status.dart';
import '../../../services/api_client.dart';
import '../models/report_draft.dart';
import '../widgets/nearby_seconding_card.dart';

class ReportDuplicateCandidate {
  ReportDuplicateCandidate.fromApi(Map<String, dynamic> raw)
    : report = NearbySecondingReport.fromApi(raw),
      status = ReportStatus.fromApi(raw['status'] as String?),
      ownedByMe = raw['ownedByMe'] == true,
      secondedByMe = raw['secondedByMe'] == true,
      canSecond = raw['canSecond'] == true {
    final lat = report.latitude, lng = report.longitude;
    if (report.id.trim().isEmpty ||
        report.reference.trim().isEmpty ||
        report.title.trim().isEmpty ||
        raw['category'] is! String ||
        lat == null ||
        !lat.isFinite ||
        lat.abs() > 90 ||
        lng == null ||
        !lng.isFinite ||
        lng.abs() > 180 ||
        raw['distanceMeters'] is! num ||
        !report.distanceMeters.isFinite ||
        report.distanceMeters < 0 ||
        report.distanceMeters > 100 ||
        status.isClosed ||
        [
          'ownedByMe',
          'secondedByMe',
          'canSecond',
        ].any((key) => raw[key] is! bool) ||
        (canSecond &&
            (ownedByMe ||
                secondedByMe ||
                status == ReportStatus.inProgress ||
                status == ReportStatus.pendingApproval))) {
      throw const FormatException('Similar report could not be verified.');
    }
  }
  final NearbySecondingReport report;
  final ReportStatus status;
  final bool ownedByMe, secondedByMe, canSecond;
}

/// Advisory discovery uses the issue pin. Presence is checked separately by
/// NearbyReportsService only when the citizen explicitly confirms an issue.
class ReportDuplicatesService {
  ReportDuplicatesService({
    String? Function()? account,
    Future<String?> Function()? token,
    Future<List<Map<String, dynamic>>> Function(String, Map<String, dynamic>)?
    request,
  }) : _account = account ?? (() => FirebaseAuth.instance.currentUser?.uid),
       _token =
           token ??
           (() async => FirebaseAuth.instance.currentUser?.getIdToken()),
       _request =
           request ??
           ((token, issue) => ApiClient.instance.reportDuplicateCandidates(
             idToken: token,
             issue: issue,
           ));
  final String? Function() _account;
  final Future<String?> Function() _token;
  final Future<List<Map<String, dynamic>>> Function(
    String,
    Map<String, dynamic>,
  )
  _request;

  Future<List<ReportDuplicateCandidate>> suggest(ReportDraft draft) async {
    final owner = _account();
    void checkAccount() {
      if (owner == null || owner != _account()) {
        throw const ApiException(
          statusCode: 401,
          message: 'Sign in again to check similar reports.',
        );
      }
    }

    checkAccount();
    final token = await _token();
    checkAccount();
    if (token == null) {
      throw const ApiException(statusCode: 401, message: 'Sign in required');
    }
    final rows = await _request(token, {
      'title': draft.title.trim(),
      'description': draft.description.trim(),
      'category': draft.category.trim(),
      'latitude': draft.latitude,
      'longitude': draft.longitude,
    });
    checkAccount();
    if (rows.length > 3) {
      throw const FormatException('Too many similar reports.');
    }
    final candidates = rows.map(ReportDuplicateCandidate.fromApi).toList();
    if (candidates.map((item) => item.report.id).toSet().length !=
        candidates.length) {
      throw const FormatException('Similar reports could not be verified.');
    }
    return candidates;
  }
}
