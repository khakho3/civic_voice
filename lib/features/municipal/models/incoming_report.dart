import '../../../models/report_category.dart';
import '../../../models/report_status.dart';
import '../../../models/region.dart';
import '../../../services/api_client.dart';

export '../../../models/report_category.dart';

class ReportConfidence {
  const ReportConfidence({
    this.score,
    this.baseScore,
    this.seconderContribution,
    this.seconderCount,
    this.hasLiveCameraPhoto,
    this.photoCount,
    this.liveGpsDistanceMeters,
    this.photoExifDistanceMeters,
    this.photoExifCapturedAt,
  });

  final int? score;
  final int? baseScore;
  final int? seconderContribution;
  final int? seconderCount;
  final bool? hasLiveCameraPhoto;
  final int? photoCount;
  final double? liveGpsDistanceMeters;
  final double? photoExifDistanceMeters;
  final DateTime? photoExifCapturedAt;

  factory ReportConfidence.fromApi(Map<String, dynamic> json) {
    return ReportConfidence(
      score: (json['score'] as num?)?.round(),
      baseScore: (json['baseScore'] as num?)?.round(),
      seconderContribution: (json['seconderContribution'] as num?)?.round(),
      seconderCount: (json['seconderCount'] as num?)?.round(),
      hasLiveCameraPhoto: json['hasLiveCameraPhoto'] as bool?,
      photoCount: (json['photoCount'] as num?)?.round(),
      liveGpsDistanceMeters: (json['liveGpsDistanceMeters'] as num?)
          ?.toDouble(),
      photoExifDistanceMeters: (json['photoExifDistanceMeters'] as num?)
          ?.toDouble(),
      photoExifCapturedAt: DateTime.tryParse(
        json['photoExifCapturedAt'] as String? ?? '',
      ),
    );
  }
}

/// A single report, shared by every Municipal list that shows one — MUN-002
/// Incoming Reports, MUN-001 Dashboard's Recent Reports, and MUN-006 Active
/// Reports. One model instead of separate per-screen mocks means a report's
/// status is real: verifying it or assigning it a team (see
/// `MunicipalReportDirectory`) actually moves it between these lists rather
/// than each screen showing its own disconnected snapshot.
class IncomingReportItem {
  const IncomingReportItem({
    this.apiId,
    required this.referenceId,
    required this.title,
    required this.description,
    required this.locationLabel,
    required this.category,
    required this.status,
    required this.timeAgo,
    this.teamName,
    this.progressPercent,
    this.updatedLabel,
    this.photoUrl,
    this.photoUrls = const [],
    this.citizenName,
    this.citizenPhone,
    this.citizenIsGuest = false,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
    this.resolutionPhotoUrls = const [],
    this.resolutionNotes,
    this.rejectionReason,
    this.rejectedAt,
    this.maintenanceFailureNotes,
    this.maintenanceFailedAt,
    this.assembly,
    this.region,
    this.reviewerName,
    this.reviewerPhone,
    this.reviewerPublicId,
    this.reviewedByCurrentUser = false,
    this.reviewedAt,
    this.maintenanceContactName,
    this.maintenanceContactPhone,
    this.confidence,
    this.citizenLowTrust = false,
  });

  /// Internal database identifier used for API calls. [referenceId] remains
  /// the citizen-facing CV reference shown throughout the UI.
  final String? apiId;

  final String referenceId;
  final String title;
  final String description;
  final String locationLabel;
  final ReportCategory category;
  final ReportStatus status;
  final String timeAgo;

  /// Set once a maintenance team takes the case — see
  /// [MunicipalReportDirectory.assignTeam]. Null beforehand: a report still
  /// in triage (submitted/under review) has no team yet.
  final String? teamName;

  /// 0-100. Null until assigned, mirroring [teamName] — there's no progress
  /// to show before a team is on the case.
  final int? progressPercent;

  /// Pre-formatted "last updated" text (e.g. "2m ago"). Null until assigned,
  /// mirroring [teamName]/[progressPercent].
  final String? updatedLabel;

  /// Null until Firebase Storage is wired up (Issue 03 dependency) — the
  /// leading avatar falls back to a placeholder icon when absent.
  final String? photoUrl;
  final List<String> photoUrls;
  final String? citizenName;
  final String? citizenPhone;
  final bool citizenIsGuest;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> resolutionPhotoUrls;
  final String? resolutionNotes;
  final String? rejectionReason;
  final DateTime? rejectedAt;
  final String? maintenanceFailureNotes;
  final DateTime? maintenanceFailedAt;
  final String? assembly;
  final Region? region;
  final String? reviewerName;
  final String? reviewerPhone;
  final String? reviewerPublicId;
  final bool reviewedByCurrentUser;
  final DateTime? reviewedAt;

  /// Whichever Maintenance user most recently touched this report's
  /// workflow (progress, failure note, or resolution) — see
  /// `Report.maintenanceContactId` on the backend. Null until a maintenance
  /// team has actually acted on the report at least once.
  final String? maintenanceContactName;
  final String? maintenanceContactPhone;
  final ReportConfidence? confidence;
  final bool citizenLowTrust;

  bool get hasReviewer => reviewerPublicId != null;
  bool get canCurrentOfficerReview => !hasReviewer || reviewedByCurrentUser;

  String get apiRecordId => apiId ?? referenceId;

  factory IncomingReportItem.fromApi(Map<String, dynamic> json) {
    final createdAt = DateTime.tryParse(json['createdAt'] as String? ?? '');
    final updatedAt = DateTime.tryParse(json['updatedAt'] as String? ?? '');
    final photos = (json['photoUrls'] as List? ?? const <dynamic>[])
        .whereType<String>()
        .toList();
    return IncomingReportItem(
      apiId: json['id'] as String,
      referenceId: json['publicReference'] as String? ?? json['id'] as String,
      title: json['title'] as String? ?? 'Untitled report',
      description: json['description'] as String? ?? '',
      locationLabel: json['location'] as String? ?? 'Location unavailable',
      category: _categoryFromApi(json['category'] as String?),
      status: _statusFromApi(json['status'] as String?),
      timeAgo: _relativeTime(createdAt),
      teamName: json['assignedTeamName'] as String?,
      progressPercent: (json['progressPercent'] as num?)?.round(),
      updatedLabel: updatedAt == null ? null : _relativeTime(updatedAt),
      photoUrl: photos.isEmpty ? null : ApiClient.assetUrl(photos.first),
      photoUrls: photos.map(ApiClient.assetUrl).toList(),
      citizenName:
          (json['citizen'] as Map<String, dynamic>?)?['fullName'] as String?,
      citizenPhone:
          (json['citizen'] as Map<String, dynamic>?)?['phone'] as String?,
      citizenIsGuest:
          (json['citizen'] as Map<String, dynamic>?)?['isGuest'] as bool? ??
          false,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: createdAt,
      updatedAt: updatedAt,
      resolutionPhotoUrls:
          (json['resolutionPhotoUrls'] as List? ?? const <dynamic>[])
              .whereType<String>()
              .map(ApiClient.assetUrl)
              .toList(),
      resolutionNotes: json['resolutionNotes'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      rejectedAt: DateTime.tryParse(json['rejectedAt'] as String? ?? ''),
      maintenanceFailureNotes: json['maintenanceFailureNotes'] as String?,
      maintenanceFailedAt: DateTime.tryParse(
        json['maintenanceFailedAt'] as String? ?? '',
      ),
      assembly: json['assembly'] as String?,
      region: Region.values.cast<Region?>().firstWhere(
        (item) => item?.name == json['region'],
        orElse: () => null,
      ),
      reviewerName:
          (json['reviewer'] as Map<String, dynamic>?)?['fullName'] as String?,
      reviewerPhone:
          (json['reviewer'] as Map<String, dynamic>?)?['phone'] as String?,
      reviewerPublicId:
          (json['reviewer'] as Map<String, dynamic>?)?['publicId'] as String?,
      reviewedByCurrentUser: json['reviewedByCurrentUser'] as bool? ?? false,
      reviewedAt: DateTime.tryParse(json['reviewedAt'] as String? ?? ''),
      maintenanceContactName:
          (json['maintenanceContact'] as Map<String, dynamic>?)?['fullName']
              as String?,
      maintenanceContactPhone:
          (json['maintenanceContact'] as Map<String, dynamic>?)?['phone']
              as String?,
      confidence: json['confidence'] is Map<String, dynamic>
          ? ReportConfidence.fromApi(json['confidence'] as Map<String, dynamic>)
          : null,
      citizenLowTrust: json['citizenLowTrust'] as bool? ?? false,
    );
  }

  IncomingReportItem copyWith({
    ReportStatus? status,
    String? teamName,
    int? progressPercent,
    String? updatedLabel,
    String? rejectionReason,
    DateTime? rejectedAt,
  }) {
    return IncomingReportItem(
      apiId: apiId,
      referenceId: referenceId,
      title: title,
      description: description,
      locationLabel: locationLabel,
      category: category,
      status: status ?? this.status,
      timeAgo: timeAgo,
      teamName: teamName ?? this.teamName,
      progressPercent: progressPercent ?? this.progressPercent,
      updatedLabel: updatedLabel ?? this.updatedLabel,
      photoUrl: photoUrl,
      photoUrls: photoUrls,
      citizenName: citizenName,
      citizenPhone: citizenPhone,
      citizenIsGuest: citizenIsGuest,
      latitude: latitude,
      longitude: longitude,
      createdAt: createdAt,
      updatedAt: updatedAt,
      resolutionPhotoUrls: resolutionPhotoUrls,
      resolutionNotes: resolutionNotes,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      maintenanceFailureNotes: maintenanceFailureNotes,
      maintenanceFailedAt: maintenanceFailedAt,
      assembly: assembly,
      region: region,
      reviewerName: reviewerName,
      reviewerPhone: reviewerPhone,
      reviewerPublicId: reviewerPublicId,
      reviewedByCurrentUser: reviewedByCurrentUser,
      reviewedAt: reviewedAt,
      maintenanceContactName: maintenanceContactName,
      maintenanceContactPhone: maintenanceContactPhone,
      confidence: confidence,
      citizenLowTrust: citizenLowTrust,
    );
  }

  static ReportCategory _categoryFromApi(String? value) {
    final normalized = value?.toLowerCase() ?? '';
    return ReportCategory.values.firstWhere(
      (category) =>
          category.name.toLowerCase() == normalized ||
          category.label.toLowerCase() == normalized,
      orElse: () => ReportCategory.other,
    );
  }

  static ReportStatus _statusFromApi(String? value) => switch (value) {
    'UNDER_REVIEW' => ReportStatus.underReview,
    'ASSIGNED' => ReportStatus.assigned,
    'IN_PROGRESS' => ReportStatus.inProgress,
    'RESOLVED' => ReportStatus.resolved,
    'REJECTED' => ReportStatus.rejected,
    _ => ReportStatus.submitted,
  };

  static String _relativeTime(DateTime? value) {
    if (value == null) return 'Recently';
    final difference = DateTime.now().difference(value.toLocal());
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hrs ago';
    return '${difference.inDays} days ago';
  }

  /// Placeholder content matching the approved MUN-002/MUN-006 designs, used
  /// until the Cloud Firestore-backed service (Issue 03 dependency) is wired
  /// up.
  ///
  /// The first two entries are MUN-002's original Incoming Reports pair — a
  /// brand-new submission and one already reviewed but still awaiting a
  /// team, which is exactly what should still show in Inbox per the real
  /// status split. The remaining five are the same reports MUN-006 Active
  /// Reports always showed (REQ-8421 is the pothole report followed through
  /// Report Review → Verification → Assign Team elsewhere in the app) —
  /// merged in here rather than kept as a separate mock so a report's
  /// status actually determines which list it shows up in.
  static List<IncomingReportItem> mock() => [
    const IncomingReportItem(
      referenceId: 'CV-1042',
      title: 'Traffic Light Malfunction',
      description:
          'Main St & 4th Ave intersection lights are completely out. '
          'Causing major delays.',
      locationLabel: 'Main St & 4th Ave',
      category: ReportCategory.safety,
      status: ReportStatus.submitted,
      timeAgo: '10 min ago',
    ),
    const IncomingReportItem(
      referenceId: 'CV-1041',
      title: 'Pothole on Elm Street',
      description:
          'Large pothole forming in the right lane northbound. Several '
          'cars swerving to avoid it.',
      locationLabel: 'Elm Street',
      category: ReportCategory.infrastructure,
      status: ReportStatus.underReview,
      timeAgo: '45 min ago',
    ),
    const IncomingReportItem(
      referenceId: 'REQ-8421',
      title: 'Severe Pothole on Main St.',
      description:
          'Deep pothole in the right lane causing vehicles to swerve into '
          'oncoming traffic.',
      locationLabel: 'Main St · Downtown',
      category: ReportCategory.infrastructure,
      status: ReportStatus.inProgress,
      timeAgo: '2 hrs ago',
      teamName: 'Unit Alpha',
      progressPercent: 60,
      updatedLabel: '2m ago',
    ),
    const IncomingReportItem(
      referenceId: 'REQ-8317',
      title: 'Broken Streetlight',
      description:
          'Streetlight has been out for several nights, leaving the '
          'corner unlit.',
      locationLabel: '5th & Oak · Downtown',
      category: ReportCategory.safety,
      status: ReportStatus.assigned,
      timeAgo: '5 hrs ago',
      teamName: 'Unit Bravo',
      progressPercent: 20,
      updatedLabel: '12m ago',
    ),
    const IncomingReportItem(
      referenceId: 'REQ-8298',
      title: 'Overflowing Trash Bin',
      description:
          'Public trash bin has been overflowing for days, attracting '
          'pests.',
      locationLabel: 'Park Ln · Riverside',
      category: ReportCategory.sanitation,
      status: ReportStatus.inProgress,
      timeAgo: '8 hrs ago',
      teamName: 'Unit Charlie',
      progressPercent: 45,
      updatedLabel: '22m ago',
    ),
    const IncomingReportItem(
      referenceId: 'REQ-8402',
      title: 'Water Leak Near Curb',
      description:
          'Steady water leak pooling near the curb, likely a broken main.',
      locationLabel: 'Cedar St · Uptown',
      category: ReportCategory.infrastructure,
      status: ReportStatus.assigned,
      timeAgo: '10 hrs ago',
      teamName: 'Unit Delta',
      progressPercent: 10,
      updatedLabel: '31m ago',
    ),
    const IncomingReportItem(
      referenceId: 'REQ-8189',
      title: 'Sidewalk Crack',
      description: 'Large crack in the sidewalk creating a trip hazard.',
      locationLabel: 'Elm Rd · Southside',
      category: ReportCategory.infrastructure,
      status: ReportStatus.resolved,
      timeAgo: '1 day ago',
      teamName: 'Unit Alpha',
      progressPercent: 100,
      updatedLabel: '1h ago',
    ),
  ];
}
