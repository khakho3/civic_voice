import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

enum ReportStatus {
  submitted,
  underReview,
  inProgress,
  resolved,
}

extension ReportStatusDetails on ReportStatus {
  String get label {
    return switch (this) {
      ReportStatus.submitted => 'Submitted',
      ReportStatus.underReview => 'Under Review',
      ReportStatus.inProgress => 'In Progress',
      ReportStatus.resolved => 'Resolved',
    };
  }

  IconData get icon {
    return switch (this) {
      ReportStatus.submitted => AppIcons.statusSubmitted,
      ReportStatus.underReview => AppIcons.statusUnderReview,
      ReportStatus.inProgress => AppIcons.statusInProgress,
      ReportStatus.resolved => AppIcons.statusResolved,
    };
  }

  Color color(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>()!;
    return switch (this) {
      ReportStatus.submitted => colors.statusSubmitted,
      ReportStatus.underReview => colors.statusUnderReview,
      ReportStatus.inProgress => colors.statusInProgress,
      ReportStatus.resolved => colors.statusResolved,
    };
  }
}

class CivicReport {
  const CivicReport({
    this.id = '',
    required this.title,
    this.description = '',
    this.category = '',
    required this.location,
    this.community = '',
    this.latitude,
    this.longitude,
    this.photoCount = 0,
    this.submittedAt,
    required this.timeLabel,
    required this.status,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final String location;
  final String community;
  final double? latitude;
  final double? longitude;
  final int photoCount;
  final DateTime? submittedAt;
  final String timeLabel;
  final ReportStatus status;

  factory CivicReport.fromMap(Map<String, Object?> map) {
    final statusName = map['status'] as String?;
    final submittedAtValue = map['submittedAt'] as String?;

    return CivicReport(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? '',
      location: map['location'] as String? ?? '',
      community: map['community'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      photoCount: (map['photoCount'] as num?)?.toInt() ?? 0,
      submittedAt: submittedAtValue == null
          ? null
          : DateTime.tryParse(submittedAtValue),
      timeLabel: map['timeLabel'] as String? ?? '',
      status: ReportStatus.values.firstWhere(
        (status) => status.name == statusName,
        orElse: () => ReportStatus.submitted,
      ),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'community': community,
      'latitude': latitude,
      'longitude': longitude,
      'photoCount': photoCount,
      'submittedAt': submittedAt?.toIso8601String(),
      'timeLabel': timeLabel,
      'status': status.name,
    };
  }

  CivicReport copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? location,
    String? community,
    double? latitude,
    double? longitude,
    int? photoCount,
    DateTime? submittedAt,
    String? timeLabel,
    ReportStatus? status,
  }) {
    return CivicReport(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      community: community ?? this.community,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      photoCount: photoCount ?? this.photoCount,
      submittedAt: submittedAt ?? this.submittedAt,
      timeLabel: timeLabel ?? this.timeLabel,
      status: status ?? this.status,
    );
  }
}
