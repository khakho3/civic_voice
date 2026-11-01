import 'package:civic_voice/features/ministry/models/municipal_performance_data.dart';
import 'package:flutter/foundation.dart';
import 'package:civic_voice/features/ministry/services/ministry_data_directory.dart';
import 'package:civic_voice/features/municipal/models/incoming_report.dart';
import 'package:civic_voice/models/report_status.dart';
import 'package:civic_voice/models/region.dart';

// Isolated labelled fixtures: no shared directory, network, or real citizen data.
MinistryDataDirectory reviewDirectory() => MinistryDataDirectory.forTesting(
  firebaseAvailable: () => true,
  tokenProvider: () async => 'fixture-only',
  reportsFetcher: (_) async => [],
  contactsFetcher: (_) async => [],
  reportsNotifier: ValueNotifier([
    for (final status in ReportStatus.values)
      IncomingReportItem(
        referenceId: 'MINISTRY-FIXTURE-${status.name}',
        title: 'Fixture ${status.name} report with a long descriptive title',
        description: 'Isolated Ministry review fixture.',
        locationLabel: 'Fixture location',
        category: ReportCategory.infrastructure,
        status: status,
        timeAgo: 'Fixture date',
        region: Region.ashanti,
        assembly: 'Kumasi',
        createdAt: DateTime.utc(2026, 10, 30),
        updatedAt: DateTime.utc(2026, 10, 31),
      ),
  ]),
);

const reviewMunicipality = RegionalLeaderItem(
  name: 'Fixture Municipality with a long administrative district name',
  region: Region.ashanti,
  resolvedPercent: 14,
  responseTimeLabel: '24h',
  officerName: 'Fixture Officer with a long contact name',
  officerPhone: '+233 00 000 0000',
);
