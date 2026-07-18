import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/region.dart';

/// Scope filters for the "Regional Leaders" list, layered with the
/// separate [Region] picker (a leader can be scoped to a region *and*
/// narrowed to Top 10/Needs Attention within it). Each option is something
/// the underlying data can actually answer — unlike the old "Regions"/
/// "This Month" chips this replaced, which toggled a selected state with
/// nothing behind them once the mock dataset only had three entries. Now
/// that [MunicipalPerformanceData.mock] carries one real assembly per
/// region, "Top 10" is a genuine sort+limit and "Needs Attention" a real
/// threshold, not decoration.
enum PerformanceFilter {
  all('All'),
  top10('Top 10'),
  needsAttention('Needs Attention');

  const PerformanceFilter(this.label);

  final String label;
}

/// Which series the "Efficiency Trend" bar chart plots.
enum EfficiencyMetric {
  response('Response'),
  resolution('Resolution');

  const EfficiencyMetric(this.label);

  final String label;
}

/// The four National Summary-style stat cards.
class MunicipalPerformanceStats {
  const MunicipalPerformanceStats({
    required this.avgResponseLabel,
    required this.resolutionPercent,
    required this.slaMetPercent,
    required this.backlogLabel,
  });

  final String avgResponseLabel;
  final int resolutionPercent;
  final int slaMetPercent;
  final String backlogLabel;
}

/// One row in the "Regional Leaders" list — despite the name, this is a
/// per-assembly (municipality/metro/district) entry, each tagged with its
/// own [region] so the region picker has something real to narrow by. The
/// approved MIN-003 frame's own title stays "Regional Leaders" (a national
/// leaderboard spanning every region), not a rename to "Municipality
/// Leaders" — the [region] tag is what makes that leaderboard filterable
/// by region, not a claim that each row *is* a region.
class RegionalLeaderItem {
  const RegionalLeaderItem({
    required this.name,
    required this.region,
    required this.resolvedPercent,
    required this.responseTimeLabel,
    required this.officerName,
    required this.officerPhone,
  });

  final String name;
  final Region region;
  final int resolvedPercent;
  final String responseTimeLabel;

  /// The Municipal Officer assigned to this assembly — a Ministry
  /// Supervisor's actual next step once a performance number looks bad,
  /// not another chart. There's no real cross-module link yet to Admin's
  /// own provisioned Municipal Officer accounts (see
  /// `AdminUserItem.assembly`), so this is realistic mock contact
  /// info for now, in the same shape a Firestore-backed lookup would
  /// eventually return.
  final String officerName;

  /// E.164-ish Ghana mobile format (e.g. "+233 24 555 0123") — same
  /// format `tel:`/`sms:` URIs expect, so [officerPhone] can be handed
  /// straight to `url_launcher` with no reformatting.
  final String officerPhone;

  /// Derived from [resolvedPercent] rather than stored — one fewer place
  /// for the color and the number it represents to drift out of sync.
  Color get rankColor {
    if (resolvedPercent >= 85) return AppColors.statusResolved;
    if (resolvedPercent >= 75) return AppColors.statusInProgress;
    return AppColors.warning;
  }

  bool get needsAttention => resolvedPercent < 75;
}

/// Data backing MIN-003 Municipal Performance's loaded state.
class MunicipalPerformanceData {
  const MunicipalPerformanceData({
    required this.stats,
    required this.regionalLeaders,
    required this.responseTrend,
    required this.resolutionTrend,
    required this.trendCaption,
  });

  final MunicipalPerformanceStats stats;

  /// One real assembly per region (all 16) — enough genuine national
  /// volume for the Top 10/Needs Attention scope filter and the region
  /// picker to both do real work, rather than toggling a selected state
  /// over three placeholder entries with nothing to differentiate.
  final List<RegionalLeaderItem> regionalLeaders;

  /// Relative bar heights — proportions only, not absolute counts.
  final List<int> responseTrend;
  final List<int> resolutionTrend;
  final String trendCaption;

  /// Placeholder content matching the approved MIN-003 design, used until
  /// the Cloud Firestore-backed aggregation service (Issue 05 dependency)
  /// is wired up.
  static MunicipalPerformanceData mock() {
    return const MunicipalPerformanceData(
      stats: MunicipalPerformanceStats(
        avgResponseLabel: '18h',
        resolutionPercent: 76,
        slaMetPercent: 84,
        backlogLabel: '1.2K',
      ),
      regionalLeaders: [
        RegionalLeaderItem(
          name: 'Accra Metropolitan',
          region: Region.greaterAccra,
          resolvedPercent: 92,
          responseTimeLabel: '14h',
          officerName: 'Kwame Owusu',
          officerPhone: '+233 24 555 0101',
        ),
        RegionalLeaderItem(
          name: 'Kumasi Metropolitan',
          region: Region.ashanti,
          resolvedPercent: 86,
          responseTimeLabel: '18h',
          officerName: 'Abena Boateng',
          officerPhone: '+233 24 555 0102',
        ),
        RegionalLeaderItem(
          name: 'Sekondi Takoradi Metropolitan',
          region: Region.western,
          resolvedPercent: 79,
          responseTimeLabel: '21h',
          officerName: 'Kojo Mensah',
          officerPhone: '+233 24 555 0103',
        ),
        RegionalLeaderItem(
          name: 'Sefwi-Wiawso Municipal',
          region: Region.westernNorth,
          resolvedPercent: 68,
          responseTimeLabel: '34h',
          officerName: 'Efua Asante',
          officerPhone: '+233 24 555 0104',
        ),
        RegionalLeaderItem(
          name: 'Cape Coast Metropolitan',
          region: Region.central,
          resolvedPercent: 81,
          responseTimeLabel: '19h',
          officerName: 'Yaw Appiah',
          officerPhone: '+233 24 555 0105',
        ),
        RegionalLeaderItem(
          name: 'Kwahu West Municipal',
          region: Region.eastern,
          resolvedPercent: 74,
          responseTimeLabel: '25h',
          officerName: 'Adjoa Darko',
          officerPhone: '+233 24 555 0106',
        ),
        RegionalLeaderItem(
          name: 'Ho Municipal',
          region: Region.volta,
          resolvedPercent: 77,
          responseTimeLabel: '20h',
          officerName: 'Kofi Agbeko',
          officerPhone: '+233 24 555 0107',
        ),
        RegionalLeaderItem(
          name: 'Jasikan Municipal',
          region: Region.oti,
          resolvedPercent: 62,
          responseTimeLabel: '41h',
          officerName: 'Ama Kudjo',
          officerPhone: '+233 24 555 0108',
        ),
        RegionalLeaderItem(
          name: 'Tamale Metropolitan',
          region: Region.northern,
          resolvedPercent: 71,
          responseTimeLabel: '26h',
          officerName: 'Alhassan Iddrisu',
          officerPhone: '+233 24 555 0109',
        ),
        RegionalLeaderItem(
          name: 'East Mamprusi Municipal',
          region: Region.northEast,
          resolvedPercent: 58,
          responseTimeLabel: '48h',
          officerName: 'Fuseini Mahama',
          officerPhone: '+233 24 555 0110',
        ),
        RegionalLeaderItem(
          name: 'East Gonja Municipal',
          region: Region.savannah,
          resolvedPercent: 64,
          responseTimeLabel: '38h',
          officerName: 'Salamatu Yakubu',
          officerPhone: '+233 24 555 0111',
        ),
        RegionalLeaderItem(
          name: 'Bolgatanga Municipal',
          region: Region.upperEast,
          resolvedPercent: 69,
          responseTimeLabel: '30h',
          officerName: 'Akolgo Atule',
          officerPhone: '+233 24 555 0112',
        ),
        RegionalLeaderItem(
          name: 'Wa Municipal',
          region: Region.upperWest,
          resolvedPercent: 66,
          responseTimeLabel: '33h',
          officerName: 'Zakaria Issahaku',
          officerPhone: '+233 24 555 0113',
        ),
        RegionalLeaderItem(
          name: 'Sunyani Municipal',
          region: Region.bono,
          resolvedPercent: 83,
          responseTimeLabel: '17h',
          officerName: 'Comfort Osei',
          officerPhone: '+233 24 555 0114',
        ),
        RegionalLeaderItem(
          name: 'Techiman Municipal',
          region: Region.bonoEast,
          resolvedPercent: 72,
          responseTimeLabel: '24h',
          officerName: 'Bright Amankwah',
          officerPhone: '+233 24 555 0115',
        ),
        RegionalLeaderItem(
          name: 'Tano North Municipal',
          region: Region.ahafo,
          resolvedPercent: 60,
          responseTimeLabel: '44h',
          officerName: 'Gifty Frimpong',
          officerPhone: '+233 24 555 0116',
        ),
      ],
      responseTrend: [46, 62, 54, 88, 66, 40, 28],
      resolutionTrend: [58, 70, 64, 92, 78, 52, 44],
      trendCaption: 'Last 7 reporting periods · aggregated only',
    );
  }
}
