import '../../../models/ghana_assemblies_data.dart';
import '../../../models/region.dart';
import 'admin_overview.dart';

Region? routingRegion(String? value) {
  for (final region in Region.values) {
    if (region.name == value) return region;
  }
  return null;
}

bool routingJurisdiction(Region region, String assembly) =>
    ghanaAssemblies[region]?.any((item) => item.name == assembly) ?? false;

DateTime _instant(Object? value) {
  if (value is! String ||
      !RegExp(
        r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$',
      ).hasMatch(value)) {
    throw const FormatException('Invalid routing version');
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null || parsed.toUtc().toIso8601String() != value) {
    throw const FormatException('Invalid routing timestamp');
  }
  return parsed;
}

bool _photo(Object? value) {
  if (value is! String || value.isEmpty || value.length > 2048) return false;
  final uri = Uri.tryParse(value);
  if (uri == null || uri.userInfo.isNotEmpty) return false;
  if (uri.hasScheme) {
    return ['http', 'https'].contains(uri.scheme) && uri.host.isNotEmpty;
  }
  return value.startsWith('/uploads/reports/') &&
      uri.path.startsWith('/uploads/reports/') &&
      !uri.pathSegments.contains('..') &&
      !uri.hasAuthority;
}

class RoutingReport {
  RoutingReport._(this.raw);
  final Map<String, dynamic> raw;
  String get id => raw['id'];
  String get reference => raw['publicReference'];
  String get title => raw['title'];
  String get status => raw['status'];
  String get updatedAt => raw['updatedAt'];
  String? get region => raw['region'];
  String? get assembly => raw['assembly'];
  String? get description => raw['description'];
  String? get location => raw['location'];
  String? get community => raw['community'];
  double? get latitude => (raw['latitude'] as num?)?.toDouble();
  double? get longitude => (raw['longitude'] as num?)?.toDouble();
  List<String> get photos => (raw['photoUrls'] as List).cast<String>();
  bool get unresolved => raw['unresolved'];
  bool get canRoute => raw['canRoute'];
  String get regionLabel =>
      routingRegion(region)?.label ??
      (region?.isNotEmpty == true ? region! : 'Unresolved');
  String get assemblyLabel =>
      assembly?.isNotEmpty == true ? assembly! : 'Unresolved';

  factory RoutingReport.parse(Object? value) {
    if (value is! Map<String, dynamic> ||
        !adminId(value['id']) ||
        !adminId(value['publicReference']) ||
        value['title'] is! String ||
        (value['title'] as String).trim().isEmpty ||
        ![
          'SUBMITTED',
          'UNDER_REVIEW',
          'ASSIGNED',
          'IN_PROGRESS',
          'PENDING_APPROVAL',
          'RESOLVED',
          'REJECTED',
        ].contains(value['status']) ||
        !['region', 'assembly', 'description', 'location', 'community'].every(
          (key) =>
              value.containsKey(key) &&
              (value[key] == null || value[key] is String),
        ) ||
        value['photoUrls'] is! List ||
        !(value['photoUrls'] as List).every(_photo) ||
        value['canRoute'] is! bool ||
        value['unresolved'] is! bool) {
      throw const FormatException('Unverified routing report');
    }
    for (final key in ['latitude', 'longitude']) {
      final coordinate = value[key];
      if (!value.containsKey(key) ||
          coordinate != null &&
              (coordinate is! num ||
                  !coordinate.isFinite ||
                  coordinate.abs() > (key == 'latitude' ? 90 : 180))) {
        throw const FormatException('Invalid saved issue pin');
      }
    }
    final unresolved =
        value['region'] == null ||
        value['region'] == '' ||
        value['assembly'] == null ||
        value['assembly'] == '';
    if (value['unresolved'] != unresolved ||
        value['canRoute'] && (!unresolved || value['status'] != 'SUBMITTED') ||
        _instant(value['updatedAt']).isBefore(_instant(value['createdAt']))) {
      throw const FormatException('Inconsistent routing snapshot');
    }
    return RoutingReport._(
      Map.unmodifiable({
        ...value,
        'photoUrls': List<String>.unmodifiable(
          (value['photoUrls'] as List).cast<String>(),
        ),
      }),
    );
  }

  bool sameEvidence(RoutingReport other) =>
      [
        'id',
        'publicReference',
        'title',
        'description',
        'location',
        'community',
        'latitude',
        'longitude',
        'createdAt',
      ].every((key) => raw[key] == other.raw[key]) &&
      photos.length == other.photos.length &&
      Iterable<int>.generate(
        photos.length,
      ).every((i) => photos[i] == other.photos[i]);
}

class RoutingPage {
  const RoutingPage(this.reports, this.total, this.nextCursor);
  final List<RoutingReport> reports;
  final int total;
  final String? nextCursor;
  factory RoutingPage.parse(Map<String, dynamic> raw) {
    if (raw['reports'] is! List ||
        (raw['reports'] as List).length > 25 ||
        !adminCount(raw['total']) ||
        raw['nextCursor'] != null &&
            (raw['nextCursor'] is! String ||
                !RegExp(
                  r'^[A-Za-z0-9_-]{1,300}$',
                ).hasMatch(raw['nextCursor']))) {
      throw const FormatException('Unverified routing queue');
    }
    final reports = (raw['reports'] as List).map(RoutingReport.parse).toList();
    if (reports.any((report) => !report.unresolved) ||
        reports.map((report) => report.id).toSet().length != reports.length ||
        raw['total'] < reports.length ||
        reports.isEmpty && raw['nextCursor'] != null) {
      throw const FormatException('Inconsistent routing queue');
    }
    return RoutingPage(
      List.unmodifiable(reports),
      raw['total'],
      raw['nextCursor'],
    );
  }
}

class RoutingChange {
  const RoutingChange(this.region, this.assembly, this.reason);
  final Region region;
  final String assembly, reason;
  bool get valid =>
      routingJurisdiction(region, assembly) &&
      reason.trim().length >= 10 &&
      reason.trim().length <= 200;
  Map<String, dynamic> body(RoutingReport previous) {
    if (!valid || !previous.canRoute) throw StateError('Routing is locked');
    return {
      'region': region.name,
      'assembly': assembly,
      'reason': reason.trim(),
      'expectedUpdatedAt': previous.updatedAt,
    };
  }
}

class RoutingAcknowledgment {
  const RoutingAcknowledgment(
    this.report,
    this.municipalOfficers,
    this.auditRecorded,
  );
  final RoutingReport report;
  final int municipalOfficers;
  final bool auditRecorded;
  factory RoutingAcknowledgment.parse(
    Map<String, dynamic> raw,
    RoutingReport previous,
    RoutingChange change,
  ) {
    final report = RoutingReport.parse(raw['report']);
    if (!change.valid ||
        !previous.canRoute ||
        !report.sameEvidence(previous) ||
        report.region != change.region.name ||
        report.assembly != change.assembly ||
        report.unresolved ||
        report.canRoute ||
        report.status != 'SUBMITTED' ||
        !_instant(report.updatedAt).isAfter(_instant(previous.updatedAt)) ||
        !adminCount(raw['municipalOfficers']) ||
        raw['auditRecorded'] is! bool) {
      throw const FormatException('Unconfirmed routing change');
    }
    return RoutingAcknowledgment(
      report,
      raw['municipalOfficers'],
      raw['auditRecorded'],
    );
  }
  bool matchesFresh(RoutingReport fresh) =>
      report.sameEvidence(fresh) &&
      fresh.updatedAt == report.updatedAt &&
      fresh.region == report.region &&
      fresh.assembly == report.assembly &&
      fresh.status == 'SUBMITTED' &&
      !fresh.unresolved &&
      !fresh.canRoute;
}
