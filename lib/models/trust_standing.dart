import 'package:flutter/foundation.dart';

/// Public server standing only. Never derives stars or milestones from reports.
@immutable
class TrustStandingData {
  const TrustStandingData({
    required this.stars,
    this.outOf = 5,
    required this.label,
    this.lowStanding = false,
    this.nextStepStars,
    this.resolvedReportsAway,
  });

  static TrustStandingData? fromJson(Object? json) {
    if (json is! Map) return null;
    final stars = json['stars'], outOf = json['outOf'];
    final label = json['label'], low = json['lowStanding'];
    if (stars is! num ||
        !stars.isFinite ||
        stars < 0.5 ||
        stars > 5 ||
        outOf != 5 ||
        label is! String ||
        label.trim().isEmpty ||
        low is! bool ||
        !json.containsKey('nextStep')) {
      return null;
    }
    final next = json['nextStep'];
    double? nextStars;
    int? reports;
    if (next == null) {
      if (stars != 5) return null;
    } else {
      if (next is! Map) return null;
      final target = next['stars'], count = next['resolvedReportsAway'];
      if (target is! num ||
          !target.isFinite ||
          target <= stars ||
          target > 5 ||
          count is! int ||
          count < 1) {
        return null;
      }
      nextStars = target.toDouble();
      reports = count;
    }
    return TrustStandingData(
      stars: stars.toDouble(),
      label: label,
      lowStanding: low,
      nextStepStars: nextStars,
      resolvedReportsAway: reports,
    );
  }

  final double stars, outOf;
  final String label;
  final bool lowStanding;
  final double? nextStepStars;
  final int? resolvedReportsAway;

  Map<String, Object?> toJson() => {
    'stars': stars,
    'outOf': outOf,
    'label': label,
    'lowStanding': lowStanding,
    'nextStep': nextStepStars == null
        ? null
        : {'stars': nextStepStars, 'resolvedReportsAway': resolvedReportsAway},
  };
  String get scoreLabel => '${_trim(stars)}/${_trim(outOf)}';
  String get readout => '${_trim(stars)} out of ${_trim(outOf)} stars — $label';
  String get milestone {
    final next = nextStepStars, count = resolvedReportsAway;
    if (next == null || count == null) {
      return 'You have reached the highest standing.';
    }
    const words = ['', 'One', 'Two', 'Three', 'Four', 'Five'];
    final counted = count > 0 && count < words.length ? words[count] : '$count';
    return '$counted more resolved ${count == 1 ? 'report' : 'reports'} to reach ${_trim(next)} stars.';
  }

  static String _trim(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : '$value';
}
